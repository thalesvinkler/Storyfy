import SwiftUI

struct ProcessingView: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                Circle().stroke(StoryfyTheme.ink.opacity(0.1), lineWidth: 10)
                Circle().trim(from: 0, to: model.progress).stroke(StoryfyTheme.coral, style: StrokeStyle(lineWidth: 10, lineCap: .round)).rotationEffect(.degrees(-90))
                Text(model.progress, format: .percent.precision(.fractionLength(0))).font(.title.bold())
            }.frame(width: 150, height: 150)
            Text("Montando sua historia").font(.largeTitle.bold())
            Text(model.statusMessage).foregroundStyle(StoryfyTheme.muted).multilineTextAlignment(.center)
            VStack(alignment: .leading, spacing: 12) {
                ProcessingStep(text: "Filtrar imagens", done: model.progress > 0.35)
                ProcessingStep(text: "Agrupar eventos", done: model.progress > 0.65)
                ProcessingStep(text: "Criar narrativa", done: model.progress > 0.84)
            }.padding(18).background(StoryfyTheme.card, in: RoundedRectangle(cornerRadius: 8))
            Spacer()
        }.padding(28)
    }
}

private struct ProcessingStep: View {
    let text: String; let done: Bool
    var body: some View { HStack { Image(systemName: done ? "checkmark.circle.fill" : "circle").foregroundStyle(done ? StoryfyTheme.teal : StoryfyTheme.muted); Text(text); Spacer() } }
}
