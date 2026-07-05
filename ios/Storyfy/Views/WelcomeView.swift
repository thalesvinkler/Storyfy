import SwiftUI

struct WelcomeView: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer()
            Text("STORYFY").font(.caption.weight(.bold)).tracking(4).foregroundStyle(StoryfyTheme.coral)
            Text("Sua vida merece mais do que ficar no rolo da câmera.").font(.system(size: 42, weight: .bold, design: .rounded)).foregroundStyle(StoryfyTheme.ink)
            Text("Todo mês, transformamos seus melhores momentos em uma história pronta para recordar e compartilhar.").font(.title3).foregroundStyle(StoryfyTheme.muted).lineSpacing(5)
            Spacer()
            Button("Começar") { model.screen = .privacy }.buttonStyle(PrimaryButtonStyle())
        }.padding(28)
    }
}
