import Photos
import UIKit

protocol PhotoLibraryServing {
    func accessState() -> PhotoAccessState
    func requestAccess() async -> PhotoAccessState
    func candidates(in interval: MonthInterval) async throws -> [PhotoCandidate]
    func image(for asset: PHAsset, size: CGSize) async -> UIImage?
    func createAlbum(named name: String, assets: [PHAsset]) async throws
}

final class PhotoLibraryService: PhotoLibraryServing {
    private let imageManager = PHCachingImageManager()

    func accessState() -> PhotoAccessState { Self.map(PHPhotoLibrary.authorizationStatus(for: .readWrite)) }

    func requestAccess() async -> PhotoAccessState {
        Self.map(await PHPhotoLibrary.requestAuthorization(for: .readWrite))
    }

    func candidates(in interval: MonthInterval) async throws -> [PhotoCandidate] {
        try await Task.detached(priority: .userInitiated) {
            guard [.authorized, .limited].contains(Self.map(PHPhotoLibrary.authorizationStatus(for: .readWrite))) else {
                throw StoryfyError.accessDenied
            }

            let imageManager = PHCachingImageManager()
            let qualityAnalyzer = PhotoQualityAnalyzer()
            let options = PHFetchOptions()
            options.predicate = NSPredicate(
                format: "mediaType == %d AND creationDate >= %@ AND creationDate < %@",
                PHAssetMediaType.image.rawValue, interval.start as NSDate, interval.end as NSDate
            )
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

            let fetched = PHAsset.fetchAssets(with: options)
            var assets: [PHAsset] = []
            assets.reserveCapacity(fetched.count)
            fetched.enumerateObjects { asset, _, _ in
                guard !asset.mediaSubtypes.contains(.photoScreenshot), asset.creationDate != nil else { return }
                assets.append(asset)
            }

            let visualAnalysisIDs = Self.visualAnalysisIDs(from: assets, maximum: 72)
            var result: [PhotoCandidate] = []
            result.reserveCapacity(assets.count)
            for asset in assets {
                try Task.checkCancellation()
                let analyzeVisuals = visualAnalysisIDs.contains(asset.localIdentifier)
                if let candidate = Self.makeCandidate(
                    from: asset,
                    analyzeVisuals: analyzeVisuals,
                    imageManager: imageManager,
                    qualityAnalyzer: qualityAnalyzer
                ) {
                    result.append(candidate)
                }
            }
            return result.sorted { $0.createdAt < $1.createdAt }
        }.value
    }

    private static func makeCandidate(
        from asset: PHAsset,
        analyzeVisuals: Bool,
        imageManager: PHCachingImageManager,
        qualityAnalyzer: PhotoQualityAnalyzer
    ) -> PhotoCandidate? {
        guard let date = asset.creationDate else { return nil }
        let image = analyzeVisuals ? analysisImage(for: asset, imageManager: imageManager) : nil
        let visual = image.map(qualityAnalyzer.visualScore) ?? .neutral
        let megapixels = Double(asset.pixelWidth * asset.pixelHeight) / 1_000_000
        let resolution = min(megapixels / 12, 1)
        let favorite = asset.isFavorite ? 1.0 : 0
        let livePhoto = asset.mediaSubtypes.contains(.photoLive) ? 1.0 : 0
        let panoramaPenalty = asset.mediaSubtypes.contains(.photoPanorama) ? 0.05 : 0
        let score = 0.12 + resolution * 0.12 + visual.exposure * 0.18 + visual.sharpness * 0.26
            + visual.faces * 0.18 + favorite * 0.11 + livePhoto * 0.03 - panoramaPenalty
        return PhotoCandidate(
            id: asset.localIdentifier,
            asset: asset,
            createdAt: date,
            score: min(max(score, 0), 1),
            event: Self.eventName(for: date),
            symbol: "photo",
            colorIndex: Calendar.current.component(.day, from: date) % 6,
            latitude: asset.location?.coordinate.latitude,
            longitude: asset.location?.coordinate.longitude
        )
    }

    private static func analysisImage(for asset: PHAsset, imageManager: PHCachingImageManager) -> UIImage? {
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = false
        options.isSynchronous = true
        var result: UIImage?
        imageManager.requestImage(for: asset, targetSize: CGSize(width: 256, height: 256), contentMode: .aspectFill, options: options) { image, _ in
            result = image
        }
        return result
    }

    private static func visualAnalysisIDs(from assets: [PHAsset], maximum: Int) -> Set<String> {
        guard assets.count > maximum else { return Set(assets.map(\.localIdentifier)) }
        var selected = Set(assets.filter(\.isFavorite).map(\.localIdentifier))
        let remaining = max(maximum - selected.count, maximum / 2)
        let strideSize = max(1, assets.count / remaining)
        for index in Swift.stride(from: 0, to: assets.count, by: strideSize) where selected.count < maximum {
            selected.insert(assets[index].localIdentifier)
        }
        return selected
    }

    private static func eventName(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInWeekend(date) { return "Fim de semana" }
        let hour = Calendar.current.component(.hour, from: date)
        if hour < 10 { return "Começos de dia" }
        if hour < 18 { return "Dias em movimento" }
        return "Noites e encontros"
    }

    func image(for asset: PHAsset, size: CGSize) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .opportunistic
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = true
            var resumed = false
            imageManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: options) { image, info in
                let degraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if !degraded && !resumed { resumed = true; continuation.resume(returning: image) }
            }
        }
    }

    func createAlbum(named name: String, assets: [PHAsset]) async throws {
        guard !assets.isEmpty else { throw StoryfyError.noPhotos }
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: name)
            request.addAssets(assets as NSArray)
        }
    }

    private static func map(_ status: PHAuthorizationStatus) -> PhotoAccessState {
        switch status {
        case .authorized: .authorized
        case .limited: .limited
        case .denied, .restricted: .denied
        case .notDetermined: .notDetermined
        @unknown default: .denied
        }
    }
}
