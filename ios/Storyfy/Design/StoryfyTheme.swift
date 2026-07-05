import SwiftUI

enum StoryfyTheme {
    static let ink = Color(red: 0.10, green: 0.10, blue: 0.12)
    static let muted = Color(red: 0.42, green: 0.40, blue: 0.40)
    static let paper = Color(red: 0.98, green: 0.96, blue: 0.92)
    static let card = Color.white.opacity(0.78)
    static let coral = Color(red: 0.91, green: 0.34, blue: 0.27)
    static let gold = Color(red: 0.92, green: 0.67, blue: 0.26)
}

struct StoryfyBackground: View {
    var body: some View {
        ZStack {
            StoryfyTheme.paper.ignoresSafeArea()
            Circle().fill(StoryfyTheme.coral.opacity(0.12)).frame(width: 300).blur(radius: 20).offset(x: 150, y: -330)
            Circle().fill(StoryfyTheme.gold.opacity(0.15)).frame(width: 260).blur(radius: 28).offset(x: -160, y: 350)
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .foregroundStyle(.white)
            .background(StoryfyTheme.ink.opacity(configuration.isPressed ? 0.78 : 1), in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
