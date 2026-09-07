import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ZStack {
            StoryfyBackground()
            Group {
                switch model.screen {
                case .privacy: PrivacyView()
                case .home: HomeView()
                case .processing: ProcessingView()
                case .review: ReviewView()
                case .caption: CaptionView()
                case .finish: FinishView()
                case .writingStyle: WritingStyleView()
                case .paywall: PaywallView()
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                if model.canGoBackInStory {
                    HStack {
                        Button { model.goBack() } label: {
                            Image(systemName: "chevron.left")
                                .font(.headline)
                                .frame(width: 44, height: 40)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Voltar para etapa anterior")
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .background(StoryfyTheme.paper)
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
