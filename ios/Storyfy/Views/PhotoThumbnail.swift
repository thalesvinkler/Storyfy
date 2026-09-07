import SwiftUI

struct PhotoThumbnail: View {
    @Environment(AppModel.self) private var model
    let photo: PhotoCandidate
    var body: some View {
        GeometryReader { proxy in
            Group {
                if photo.asset == nil {
                    DemoPhoto(photo: photo)
                } else {
                    Color.gray.opacity(0.15).overlay {
                    AsyncImageView(loader: { await model.thumbnail(for: photo, size: CGSize(width: proxy.size.width * 3, height: proxy.size.height * 3)) })
                    }
                }
            }.clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

private struct DemoPhoto: View {
    let photo: PhotoCandidate
    private let colors: [Color] = [.red, .cyan, .green, .yellow, .indigo, .pink]

    var body: some View {
        ZStack {
            colors[photo.colorIndex % colors.count].opacity(0.72)
            Rectangle().fill(.black.opacity(0.12)).frame(maxHeight: .infinity).offset(y: 70)
            Image(systemName: photo.symbol).font(.system(size: 42, weight: .medium)).foregroundStyle(.white)
            VStack { Spacer(); Text(photo.event).font(.caption2.bold()).foregroundStyle(.white).lineLimit(1).padding(8) }
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
