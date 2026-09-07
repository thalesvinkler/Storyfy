import SwiftUI
import UIKit

struct WritingStyleView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL
    @State private var examples = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Button { model.screen = .home } label: { Image(systemName: "chevron.left") }.buttonStyle(.plain)
                    Spacer()
                }
                Text("CONFIGURAÇÕES").font(.caption2.bold()).tracking(2).foregroundStyle(StoryfyTheme.coral)
                Text("Personalize o Storyfy").font(.largeTitle.bold())

                settingsSection(title: "Plano", icon: "creditcard") {
                    HStack(spacing: 12) {
                        Image(systemName: model.billingPlan == .free ? "sparkles" : "checkmark.seal.fill")
                            .font(.title2)
                            .foregroundStyle(model.billingPlan == .free ? StoryfyTheme.coral : StoryfyTheme.teal)
                            .frame(width: 38)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Storyfy \(model.billingPlan.title)").font(.subheadline.bold())
                            Text("\(model.billingPlan.captionLimit) legendas IA por mês")
                                .font(.caption).foregroundStyle(StoryfyTheme.muted)
                        }
                        Spacer()
                        Button(model.billingPlan == .free ? "Upgrade" : "Gerenciar") { model.screen = .paywall }
                            .font(.caption.bold()).foregroundStyle(StoryfyTheme.coral)
                    }
                }

                settingsSection(title: "Instagram", icon: "camera") {
                    if model.instagramConnectionID == nil {
                        Text("Conecte sua conta profissional para aprender o padrão das suas legendas.")
                            .font(.subheadline).foregroundStyle(StoryfyTheme.muted)
                        Button { Task { await model.connectInstagram() } } label: {
                            Label(model.isConnectingInstagram ? "Conectando…" : "Conectar Instagram", systemImage: "link")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent).tint(StoryfyTheme.ink).disabled(model.isConnectingInstagram)
                    } else {
                        HStack(spacing: 11) {
                            Circle().fill(StoryfyTheme.coral).frame(width: 38, height: 38)
                                .overlay(Image(systemName: "camera.fill").foregroundStyle(.white))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(model.writingProfile).font(.subheadline.bold())
                                Text("\(importedCaptionCount) legendas importadas").font(.caption).foregroundStyle(StoryfyTheme.muted)
                            }
                            Spacer()
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(StoryfyTheme.teal)
                        }
                        Text("Ao desconectar, apagamos deste aparelho as legendas importadas e solicitamos a remoção da conexão no servidor.")
                            .font(.caption2).foregroundStyle(StoryfyTheme.muted)
                        Button("Desconectar e apagar dados", role: .destructive) { Task { await model.disconnectInstagram(); examples = "" } }
                            .font(.caption.bold())
                    }
                }

                settingsSection(title: "Calendário", icon: "calendar") {
                    HStack(alignment: .top, spacing: 11) {
                        Image(systemName: model.calendarConnected ? "calendar.badge.checkmark" : "calendar.badge.plus")
                            .font(.title2).foregroundStyle(model.calendarConnected ? StoryfyTheme.teal : StoryfyTheme.coral)
                            .frame(width: 38)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(model.calendarConnected ? "Acesso permitido" : "Acesso opcional").font(.subheadline.bold())
                            Text(model.calendarStatusMessage).font(.caption).foregroundStyle(StoryfyTheme.muted)
                        }
                    }
                    if !model.calendarConnected {
                        HStack(spacing: 10) {
                            Button(model.isConnectingCalendar ? "Solicitando…" : "Permitir acesso") { Task { await model.connectCalendar() } }
                                .buttonStyle(.bordered).disabled(model.isConnectingCalendar)
                            Button("Abrir Ajustes") {
                                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                            }
                            .buttonStyle(.plain).font(.caption.bold()).foregroundStyle(StoryfyTheme.coral)
                        }
                    }
                }

                settingsSection(title: "Localização", icon: "location") {
                    Toggle(isOn: Binding(get: { model.locationNamesEnabled }, set: { model.locationNamesEnabled = $0 })) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Identificar cidades e regiões").font(.subheadline.bold())
                            Text("Opcional. Consulta nomes de lugares usando as coordenadas das fotos.")
                                .font(.caption).foregroundStyle(StoryfyTheme.muted)
                        }
                    }
                    .tint(StoryfyTheme.teal)
                    Text("Mesmo desativado, o Storyfy ainda evita muitas fotos do mesmo local usando apenas coordenadas no aparelho.")
                        .font(.caption2).foregroundStyle(StoryfyTheme.muted)
                }

                settingsSection(title: "Exemplos adicionais", icon: "text.quote") {
                    Text("Opcional. Cole frases que representem sua voz além das legendas importadas.")
                        .font(.caption).foregroundStyle(StoryfyTheme.muted)
                    TextEditor(text: $examples)
                        .scrollContentBackground(.hidden)
                        .padding(9)
                        .frame(height: 96)
                        .background(StoryfyTheme.card, in: RoundedRectangle(cornerRadius: 8))
                }

                Button("Salvar configurações") {
                    let combined = [model.writingExamples, examples.trimmingCharacters(in: .whitespacesAndNewlines)]
                        .filter { !$0.isEmpty }.joined(separator: "\n\n")
                    model.saveWritingStyle(profile: model.writingProfile, examples: combined)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(24)
        }
    }

    private var importedCaptionCount: Int {
        model.writingExamples.components(separatedBy: "\n\n").filter { !$0.isEmpty }.count
    }

    private func settingsSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon).font(.headline)
            content()
        }
        .padding(.vertical, 16)
        .overlay(alignment: .top) { Divider() }
    }
}
