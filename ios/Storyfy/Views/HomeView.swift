import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                StoryfyWordmark()
                Spacer()
                Button { model.screen = .writingStyle } label: {
                    Image(systemName: "gearshape")
                        .font(.title3)
                        .frame(width: 42, height: 42)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Abrir configurações")
            }

            Button {
                model.screen = .paywall
            } label: {
                HStack {
                    Image(systemName: model.billingPlan == .free ? "sparkles" : "checkmark.seal.fill")
                        .foregroundStyle(model.billingPlan == .free ? StoryfyTheme.coral : StoryfyTheme.teal)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(model.billingPlan == .free ? "Plano Free" : "Plano \(model.billingPlan.title)")
                            .font(.caption.bold())
                        Text("\(model.billingPlan.captionLimit) legendas IA por mês")
                            .font(.caption2)
                            .foregroundStyle(StoryfyTheme.muted)
                    }
                    Spacer()
                    Text(model.billingPlan == .free ? "Upgrade" : "Gerenciar")
                        .font(.caption.bold())
                        .foregroundStyle(StoryfyTheme.coral)
                }
                .padding(12)
                .background(StoryfyTheme.card, in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 8) {
                Text("NOVA HISTÓRIA").font(.caption2.bold()).tracking(2).foregroundStyle(StoryfyTheme.coral)
                Text("Qual mês você quer reviver?").font(.system(size: 34, weight: .bold, design: .rounded))
                Text("Escolha o período. O restante fica por conta do Storyfy.").foregroundStyle(StoryfyTheme.muted)
            }

            MonthYearPicker(selectedMonth: model.month.start) { date in
                model.selectMonth(date)
            }

            if let latest = model.archives.first {
                VStack(alignment: .leading, spacing: 8) {
                    Text("HISTÓRIA RECENTE").font(.caption2.bold()).tracking(2).foregroundStyle(StoryfyTheme.teal)
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(latest.monthName).font(.subheadline.bold())
                            Text("\(latest.photoCount) fotos · salva \(latest.createdAt.formatted(.relative(presentation: .named)))")
                                .font(.caption2).foregroundStyle(StoryfyTheme.muted)
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(StoryfyTheme.teal)
                    }
                }
                .padding(.vertical, 12)
                .overlay(alignment: .top) { Divider() }
            }

            Spacer()

            HStack(spacing: 12) {
                Image(systemName: model.usesWritingStyle ? "checkmark.circle.fill" : "sparkles")
                    .foregroundStyle(model.usesWritingStyle ? StoryfyTheme.teal : StoryfyTheme.coral)
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.usesWritingStyle ? "Seu estilo está configurado" : "Legenda com a sua voz").font(.caption.bold())
                    Text(model.usesWritingStyle ? model.writingProfile : "Adicione seu perfil ou exemplos de legendas.")
                        .font(.caption2).foregroundStyle(StoryfyTheme.muted).lineLimit(1)
                }
                Spacer()
                Button(model.usesWritingStyle ? "Editar" : "Configurar") { model.screen = .writingStyle }
                    .font(.caption.bold()).foregroundStyle(StoryfyTheme.coral)
            }
            .padding(.vertical, 12)
            .overlay(alignment: .top) { Divider() }

            Button("Montar história de \(monthName)") { Task { await model.buildStory() } }
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding(24)
        .task {
            await model.refreshBilling()
        }
    }

    private var monthName: String {
        model.month.start.formatted(.dateTime.month(.wide).locale(Locale(identifier: "pt_BR")))
    }
}

private struct MonthYearPicker: View {
    let selectedMonth: Date
    let onSelect: (Date) -> Void

    private let calendar = Calendar.current
    private let monthSymbols = Calendar.current.shortMonthSymbols

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button { selectYear(year - 1) } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 36, height: 34)
                }
                .buttonStyle(.plain)
                .disabled(year <= minimumYear)

                Spacer()

                Text(String(year))
                    .font(.headline.bold())

                Spacer()

                Button { selectYear(year + 1) } label: {
                    Image(systemName: "chevron.right")
                        .frame(width: 36, height: 34)
                }
                .buttonStyle(.plain)
                .disabled(year >= currentYear)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(1...12, id: \.self) { month in
                    Button {
                        select(month: month, year: year)
                    } label: {
                        Text(monthSymbols[month - 1].capitalized)
                            .font(.caption.bold())
                            .frame(maxWidth: .infinity, minHeight: 38)
                    }
                    .buttonStyle(MonthButtonStyle(isSelected: month == selectedMonthNumber, isDisabled: isFuture(month: month, year: year)))
                    .disabled(isFuture(month: month, year: year))
                }
            }
        }
        .padding(12)
        .background(StoryfyTheme.card, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(StoryfyTheme.muted.opacity(0.18)))
    }

    private var selectedMonthNumber: Int {
        calendar.component(.month, from: selectedMonth)
    }

    private var year: Int {
        calendar.component(.year, from: selectedMonth)
    }

    private var currentYear: Int {
        calendar.component(.year, from: .now)
    }

    private var currentMonth: Int {
        calendar.component(.month, from: .now)
    }

    private var minimumYear: Int { currentYear - 5 }

    private func isFuture(month: Int, year: Int) -> Bool {
        year > currentYear || (year == currentYear && month > currentMonth)
    }

    private func selectYear(_ year: Int) {
        let month = min(selectedMonthNumber, year == currentYear ? currentMonth : 12)
        select(month: month, year: year)
    }

    private func select(month: Int, year: Int) {
        guard let date = calendar.date(from: DateComponents(year: year, month: month, day: 1)) else { return }
        onSelect(date)
    }
}

private struct MonthButtonStyle: ButtonStyle {
    let isSelected: Bool
    let isDisabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(textColor)
            .background(backgroundColor(configuration), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(borderColor))
            .opacity(isDisabled ? 0.35 : 1)
    }

    private var textColor: Color {
        isSelected ? .white : StoryfyTheme.muted
    }

    private var borderColor: Color {
        isSelected ? StoryfyTheme.coral : StoryfyTheme.muted.opacity(0.18)
    }

    private func backgroundColor(_ configuration: Configuration) -> Color {
        if isSelected { return StoryfyTheme.coral }
        return configuration.isPressed ? StoryfyTheme.muted.opacity(0.12) : .clear
    }
}
