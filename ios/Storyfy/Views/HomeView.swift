import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Sua retrospectiva").font(.caption.weight(.semibold)).textCase(.uppercase).tracking(2).foregroundStyle(StoryfyTheme.coral)
            Text(model.month.displayName.capitalized).font(.system(size: 44, weight: .bold, design: .rounded))
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 32).fill(StoryfyTheme.ink)
                VStack(spacing: 18) {
                    Image(systemName: "photo.stack.fill").font(.system(size: 54)).foregroundStyle(StoryfyTheme.gold)
                    Text("Vamos encontrar os momentos que contam a história do seu mês.").font(.title2.bold()).multilineTextAlignment(.center).foregroundStyle(.white)
                    Text("Screenshots ficam de fora. Você revisa tudo antes de compartilhar.").multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.7))
                }.padding(30)
            }.frame(height: 330)
            Spacer()
            Button("Criar retrospectiva") { Task { await model.buildStory() } }.buttonStyle(PrimaryButtonStyle())
        }.padding(28)
    }
}
