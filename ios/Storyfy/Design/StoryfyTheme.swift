import SwiftUI

enum StoryfyTheme {
    static let ink = Color(uiColor: .label)
    static let muted = Color(uiColor: .secondaryLabel)
    static let paper = Color(uiColor: .systemBackground)
    static let card = Color(uiColor: .secondarySystemBackground)
    static let coral = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 1.00, green: 0.44, blue: 0.39, alpha: 1)
            : UIColor(red: 0.91, green: 0.34, blue: 0.27, alpha: 1)
    })
    static let gold = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.96, green: 0.73, blue: 0.30, alpha: 1)
            : UIColor(red: 0.92, green: 0.67, blue: 0.26, alpha: 1)
    })
    static let teal = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.40, green: 0.78, blue: 0.77, alpha: 1)
            : UIColor(red: 0.12, green: 0.48, blue: 0.48, alpha: 1)
    })
}

struct StoryfyBackground: View {
    var body: some View {
        StoryfyTheme.paper.ignoresSafeArea()
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .foregroundStyle(StoryfyTheme.paper)
            .background(StoryfyTheme.ink.opacity(configuration.isPressed ? 0.78 : 1), in: RoundedRectangle(cornerRadius: 8))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct StoryfyWordmark: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "photo.on.rectangle.angled").foregroundStyle(StoryfyTheme.coral)
            Text("STORYFY").font(.caption.weight(.black)).tracking(2)
        }
    }
}
