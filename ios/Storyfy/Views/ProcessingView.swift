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
            Text("Montando sua história").font(.largeTitle.bold())
            Text(model.statusMessage).foregroundStyle(StoryfyTheme.muted).multilineTextAlignment(.center)
            Spacer()
        }.padding(28)
    }
}
