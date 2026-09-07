import SwiftUI

struct PaywallView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Button { model.goBack() } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .frame(width: 40, height: 40)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("STORYFY PRO").font(.caption2.bold()).tracking(2).foregroundStyle(StoryfyTheme.coral)
                    Text("Crie no seu ritmo").font(.system(size: 34, weight: .bold, design: .rounded))
                    Text("Comece grátis para a retrospectiva mensal. Faça upgrade quando quiser mais legendas com IA.")
                        .foregroundStyle(StoryfyTheme.muted)
                }

                planSummary

                VStack(alignment: .leading, spacing: 10) {
                    benefit("Legendas geradas com IA no seu estilo", icon: "sparkles")
                    benefit("Fallback automático quando a API não responde", icon: "exclamationmark.shield")
                    benefit("Restaurar compras em qualquer aparelho", icon: "arrow.clockwise")
                }
                .padding(14)
                .background(StoryfyTheme.card, in: RoundedRectangle(cornerRadius: 8))

                VStack(spacing: 10) {
                    ForEach(model.billingProducts) { product in
                        Button {
                            Task { await model.purchase(product) }
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(product.title).font(.headline)
                                    Text(product.subtitle).font(.caption).foregroundStyle(StoryfyTheme.muted)
                                }
                                Spacer()
                                Text(product.price).font(.subheadline.bold())
                            }
                            .padding(14)
                            .background(StoryfyTheme.card, in: RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(product.plan == model.billingPlan ? StoryfyTheme.teal : StoryfyTheme.muted.opacity(0.16)))
                        }
                        .buttonStyle(.plain)
                        .disabled(model.isLoadingBilling)
                    }
                }

                Button {
                    Task { await model.restorePurchases() }
                } label: {
                    Label(model.isLoadingBilling ? "Verificando…" : "Restaurar compras", systemImage: "arrow.clockwise")
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .disabled(model.isLoadingBilling)

                Text("A cobrança é feita pela App Store. Você pode cancelar a renovação nas assinaturas do seu Apple ID.")
                    .font(.caption2)
                    .foregroundStyle(StoryfyTheme.muted)

                #if DEBUG
                debugControls
                #endif
            }
            .padding(24)
        }
        .task {
            if model.billingProducts.isEmpty {
                await model.refreshBilling()
            }
        }
    }

    private var planSummary: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Plano atual").font(.caption.bold()).foregroundStyle(StoryfyTheme.muted)
                Text(model.billingPlan.title).font(.title3.bold())
            }
            Spacer()
            Text("\(model.billingPlan.captionLimit) legendas IA/mês")
                .font(.caption.bold())
                .foregroundStyle(StoryfyTheme.teal)
        }
        .padding(14)
        .background(StoryfyTheme.card, in: RoundedRectangle(cornerRadius: 8))
    }

    private func benefit(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(StoryfyTheme.ink)
    }

    #if DEBUG
    private var debugControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DEBUG").font(.caption2.bold()).tracking(2).foregroundStyle(StoryfyTheme.muted)
            HStack {
                ForEach(BillingPlan.allCases, id: \.self) { plan in
                    Button(plan.title) { model.debugSetPlan(plan) }
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(plan == model.billingPlan ? StoryfyTheme.coral : StoryfyTheme.card, in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(plan == model.billingPlan ? .white : StoryfyTheme.muted)
                }
            }
        }
        .padding(.top, 8)
    }
    #endif
}
