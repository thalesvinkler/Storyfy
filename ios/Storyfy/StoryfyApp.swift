import SwiftUI

@main
struct StoryfyApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .tint(StoryfyTheme.coral)
        }
    }
}
