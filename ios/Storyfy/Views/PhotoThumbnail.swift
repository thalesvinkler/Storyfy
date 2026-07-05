import SwiftUI

struct PhotoThumbnail: View {
    @Environment(AppModel.self) private var model
    let photo: PhotoCandidate
    var body: some View {
        GeometryReader { proxy in
            Color.gray.opacity(0.15)
                .overlay {
                    AsyncImageView(loader: { await model.thumbnail(for: photo, size: CGSize(width: proxy.size.width * 3, height: proxy.size.height * 3)) })
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

private struct AsyncImageView: View {
    let loader: () async -> UIImage?
    @State private var image: UIImage?
    var body: some View {
        Group { if let image { Image(uiImage: image).resizable().scaledToFill() } else { ProgressView() } }
            .task { image = await loader() }
            .clipped()
    }
}
