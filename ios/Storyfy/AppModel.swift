import Foundation
import Photos
import Observation
import UIKit
import SwiftUI

@MainActor
@Observable
final class AppModel {
    var screen: AppScreen = .welcome
    var access: PhotoAccessState = .notDetermined
    var photos: [PhotoCandidate] = []
    var caption = ""
    var progress = 0.0
    var statusMessage = "Preparando sua história…"
    var errorMessage: String?
    var albumCreated = false
    let month = MonthInterval.previous()

    private let library: PhotoLibraryServing
    private let curator: CurationServing
    private let captions: CaptionServing
    private var captionVariant = 0

    init(library: PhotoLibraryServing = PhotoLibraryService(), curator: CurationServing = LocalCurationService(), captions: CaptionServing = LocalCaptionService()) {
        self.library = library; self.curator = curator; self.captions = captions
        access = library.accessState()
    }

    func requestPhotoAccess() async {
        access = await library.requestAccess()
        if access == .authorized || access == .limited { screen = .home }
        else { errorMessage = StoryfyError.accessDenied.localizedDescription }
    }

    func buildStory() async {
        screen = .processing; errorMessage = nil; progress = 0.15
        do {
            statusMessage = "Buscando as fotos de \(month.displayName)…"
            let candidates = try await library.candidates(in: month)
            guard !candidates.isEmpty else { throw StoryfyError.noPhotos }
            progress = 0.58; statusMessage = "Escolhendo momentos diferentes…"
            photos = curator.select(from: candidates, limit: 15)
            progress = 1; statusMessage = "Sua retrospectiva está pronta."
            try? await Task.sleep(for: .milliseconds(450)); screen = .review
        } catch { errorMessage = error.localizedDescription; screen = .home }
    }

    func remove(_ photo: PhotoCandidate) { photos.removeAll { $0.id == photo.id } }
    func move(from source: IndexSet, to destination: Int) { photos.move(fromOffsets: source, toOffset: destination) }

    func prepareCaption() {
        caption = captions.caption(for: month, photoCount: photos.count, variant: captionVariant)
        screen = .caption
    }

    func regenerateCaption() { captionVariant += 1; caption = captions.caption(for: month, photoCount: photos.count, variant: captionVariant) }

    func finish() { screen = .finish }

    func createAlbum() async {
        do {
            try await library.createAlbum(named: "Storyfy — \(month.displayName.capitalized)", assets: photos.map(\.asset))
            albumCreated = true
        } catch { errorMessage = error.localizedDescription }
    }

    func thumbnail(for photo: PhotoCandidate, size: CGSize) async -> UIImage? { await library.image(for: photo.asset, size: size) }

    func sharePayload() async -> [Any] {
        var items: [Any] = []
        for photo in photos {
            if let image = await library.image(for: photo.asset, size: CGSize(width: 2048, height: 2048)) { items.append(image) }
        }
        items.append(caption)
        return items
    }

    func restart() { photos = []; caption = ""; progress = 0; albumCreated = false; errorMessage = nil; screen = .home }
}
