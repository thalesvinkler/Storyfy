import SwiftUI

struct CaptionView: View {
    @Environment(AppModel.self) private var model
    @FocusState private var isCaptionFocused: Bool
    private let tagColumns = [GridItem(.adaptive(minimum: 130), spacing: 8)]

    var body: some View {
        @Bindable var model = model
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("A voz do seu mes").font(.largeTitle.bold())
                Text(model.usesWritingStyle ? "Inspirada nos exemplos do seu estilo de escrita." : "Um rascunho baseado nos eventos escolhidos. Edite livremente.").foregroundStyle(StoryfyTheme.muted)
                LazyVGrid(columns: tagColumns, alignment: .leading, spacing: 8) {
                    ForEach(model.storyEvents.prefix(4)) { event in
                        Text("\(event.emoji) \(event.name)")
                            .font(.caption.bold())
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 9)
                            .background(StoryfyTheme.card, in: RoundedRectangle(cornerRadius: 6))
                    }
                }
                if model.captionUsedFallback {
                    Label(fallbackMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(StoryfyTheme.gold)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(StoryfyTheme.card, in: RoundedRectangle(cornerRadius: 8))
                }
                if let quota = model.captionQuota {
                    Text("Plano \(quota.plan.capitalized): \(quota.remaining) de \(quota.monthlyLimit) legendas IA restantes neste mês.")
                        .font(.caption.bold())
                        .foregroundStyle(StoryfyTheme.muted)
                }
                if model.captionFallbackReason == .limitReached {
                    Button("Ver planos") { model.screen = .paywall }
                        .buttonStyle(PrimaryButtonStyle())
                }
                if model.isGeneratingCaption {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Escrevendo no seu estilo…").font(.caption).foregroundStyle(StoryfyTheme.muted)
                    }
                    .frame(maxWidth: .infinity, minHeight: 190)
                    .background(StoryfyTheme.card, in: RoundedRectangle(cornerRadius: 8))
                } else {
                    TextEditor(text: $model.caption)
                        .font(.body)
                        .lineSpacing(4)
                        .scrollContentBackground(.hidden)
                        .focused($isCaptionFocused)
                        .frame(minHeight: 150, maxHeight: 190)
                        .padding(14)
                        .background(StoryfyTheme.card, in: RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(24)
            .padding(.bottom, 112)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) {
                Button { Task { await model.regenerateCaption() } } label: { Label("Tentar outra legenda", systemImage: "sparkles") }
                    .frame(maxWidth: .infinity)
                    .disabled(model.isGeneratingCaption)
                Button("Ver preview do carrossel") { model.finish() }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(model.isGeneratingCaption || model.caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 12)
            .background(.ultraThinMaterial)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("OK") { isCaptionFocused = false }
            }
        }
    }

    private var fallbackMessage: String {
        switch model.captionFallbackReason {
        case .limitReached:
            "Você atingiu o limite de legendas IA do plano atual. Geramos uma legenda padrão para você editar."
        case .apiUnavailable, nil:
            "A API de legenda não respondeu. Geramos uma legenda padrão para você editar."
        }
    }
}
