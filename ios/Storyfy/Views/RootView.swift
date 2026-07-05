import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ZStack {
            StoryfyBackground()
            Group {
                switch model.screen {
                case .welcome: WelcomeView()
                case .privacy: PrivacyView()
                case .home: HomeView()
                case .processing: ProcessingView()
                case .review: ReviewView()
                case .caption: CaptionView()
                case .finish: FinishView()
                }
            }
            .transition(.opacity.combined(with: .move(edge: .trailing)))
        }
        .animation(.easeInOut(duration: 0.3), value: model.screen)
        .alert("Algo saiu do roteiro", isPresented: Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })) {
            Button("Entendi", role: .cancel) { model.errorMessage = nil }
        } message: { Text(model.errorMessage ?? "") }
    }
}
