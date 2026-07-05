import SwiftUI

struct FinishView: View {
    @Environment(AppModel.self) private var model
    @State private var shareItems: [Any] = []
    @State private var showingShareSheet = false
    @State private var preparingShare = false
    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: model.albumCreated ? "checkmark.circle.fill" : "heart.fill").font(.system(size: 72)).foregroundStyle(StoryfyTheme.coral)
            Text("\(model.month.displayName.capitalized) agora faz parte da sua história.").font(.system(size: 35, weight: .bold, design: .rounded)).multilineTextAlignment(.center)
            Text(model.albumCreated ? "O álbum foi salvo no Apple Photos." : "Salve o álbum e compartilhe quando estiver pronto.").foregroundStyle(StoryfyTheme.muted).multilineTextAlignment(.center)
            Spacer()
            if !model.albumCreated { Button("Salvar álbum no Fotos") { Task { await model.createAlbum() } }.buttonStyle(PrimaryButtonStyle()) }
            Button {
                Task {
                    preparingShare = true
                    shareItems = await model.sharePayload()
                    preparingShare = false
                    showingShareSheet = true
                }
            } label: {
                Label(preparingShare ? "Preparando…" : "Compartilhar fotos", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity).padding()
            }
            .disabled(preparingShare)
            Button("Criar outra história") { model.restart() }.foregroundStyle(StoryfyTheme.muted)
        }
        .padding(28)
        .sheet(isPresented: $showingShareSheet) { ShareSheet(items: shareItems) }
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: items, applicationActivities: nil) }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
