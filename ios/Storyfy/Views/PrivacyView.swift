import SwiftUI

struct PrivacyView: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Suas memórias continuam suas.").font(.system(size: 36, weight: .bold, design: .rounded))
            Text("Nesta versão, a curadoria acontece no próprio iPhone. Nenhuma foto é enviada para nossos servidores.").foregroundStyle(StoryfyTheme.muted)
            VStack(spacing: 16) {
                PrivacyRow(icon: "iphone", text: "Originais permanecem no aparelho")
                PrivacyRow(icon: "eye.slash", text: "Nada é publicado sem sua aprovação")
                PrivacyRow(icon: "slider.horizontal.3", text: "Acesso limitado também funciona")
            }.padding(20).background(StoryfyTheme.card, in: RoundedRectangle(cornerRadius: 24))
            Spacer()
            Button("Permitir acesso às fotos") { Task { await model.requestPhotoAccess() } }.buttonStyle(PrimaryButtonStyle())
        }.padding(28)
    }
}

private struct PrivacyRow: View {
    let icon: String; let text: String
    var body: some View { HStack(spacing: 14) { Image(systemName: icon).frame(width: 26).foregroundStyle(StoryfyTheme.coral); Text(text); Spacer() } }
}
