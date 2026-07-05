import SwiftUI

struct CaptionView: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: 18) {
            Text("As palavras do mês").font(.largeTitle.bold())
            Text("Este é um primeiro rascunho. Deixe com a sua voz.").foregroundStyle(StoryfyTheme.muted)
            TextEditor(text: $model.caption).font(.body).scrollContentBackground(.hidden).padding(16).background(StoryfyTheme.card, in: RoundedRectangle(cornerRadius: 22))
            Button { model.regenerateCaption() } label: { Label("Tentar outra legenda", systemImage: "sparkles") }.frame(maxWidth: .infinity)
            Button("Aprovar história") { model.finish() }.buttonStyle(PrimaryButtonStyle()).disabled(model.caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }.padding(24)
    }
}
