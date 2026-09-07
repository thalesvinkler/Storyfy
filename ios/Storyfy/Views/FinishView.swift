import SwiftUI

struct FinishView: View {
    @Environment(AppModel.self) private var model
    @State private var shareItems: [Any] = []
    @State private var showingShareSheet = false
    @State private var preparingShare = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("PREVIEW DO CARROSSEL").font(.caption2.bold()).tracking(2).foregroundStyle(StoryfyTheme.coral)

            TabView {
                ForEach(Array(model.photos.enumerated()), id: \.element.id) { index, photo in
                    PhotoThumbnail(photo: photo)
                        .aspectRatio(1, contentMode: .fill)
                        .overlay(alignment: .topTrailing) {
                            Text("\(index + 1)/\(model.photos.count)").font(.caption2.bold()).foregroundStyle(.white)
                                .padding(.horizontal, 8).padding(.vertical, 5).background(.black.opacity(0.55), in: Capsule()).padding(10)
                        }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            HStack(spacing: 9) {
                Circle().fill(StoryfyTheme.coral).frame(width: 30, height: 30).overlay(Text("S").font(.caption.bold()).foregroundStyle(.white))
                Text(profileName).font(.caption.bold())
                Spacer()
                Image(systemName: "ellipsis")
            }
            ScrollView { Text(model.caption).font(.subheadline).lineSpacing(3).frame(maxWidth: .infinity, alignment: .leading) }
                .frame(maxHeight: 125)

            Spacer(minLength: 4)
            if !model.albumCreated {
                Button("Aprovar e salvar no Fotos") { Task { await model.createAlbum() } }.buttonStyle(PrimaryButtonStyle())
            }
            Button {
                Task {
                    preparingShare = true
                    shareItems = await model.sharePayload()
                    preparingShare = false
                    showingShareSheet = true
                }
            } label: {
                Label(preparingShare ? "Preparando…" : "Compartilhar carrossel", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity).padding()
            }
            .disabled(preparingShare)
            Button("Voltar para editar") { model.screen = .review }.frame(maxWidth: .infinity).foregroundStyle(StoryfyTheme.muted)
        }
        .padding(22)
        .sheet(isPresented: $showingShareSheet) { ShareSheet(items: shareItems) }
    }

    private var profileName: String {
        let value = model.writingProfile.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? "seu_perfil" : value.replacingOccurrences(of: "@", with: "")
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: items, applicationActivities: nil) }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
