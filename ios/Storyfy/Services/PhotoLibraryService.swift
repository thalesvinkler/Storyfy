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
        guard [.authorized, .limited].contains(accessState()) else { throw StoryfyError.accessDenied }
        let options = PHFetchOptions()
        options.predicate = NSPredicate(
            format: "mediaType == %d AND creationDate >= %@ AND creationDate < %@",
            PHAssetMediaType.image.rawValue, interval.start as NSDate, interval.end as NSDate
        )
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        let fetched = PHAsset.fetchAssets(with: options)
        var result: [PhotoCandidate] = []
        fetched.enumerateObjects { asset, _, _ in
            guard !asset.mediaSubtypes.contains(.photoScreenshot), let date = asset.creationDate else { return }
            let pixels = Double(asset.pixelWidth * asset.pixelHeight)
            let resolution = min(pixels / 12_000_000, 1)
            let favorite = asset.isFavorite ? 0.35 : 0
            result.append(PhotoCandidate(id: asset.localIdentifier, asset: asset, createdAt: date, score: 0.55 + resolution * 0.1 + favorite))
        }
        return result
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
