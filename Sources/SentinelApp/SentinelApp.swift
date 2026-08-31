#if os(macOS)
import SwiftUI

@main
struct SentinelApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView(model: model)
                .frame(minWidth: 940, minHeight: 640)
        }
        .windowStyle(.hiddenTitleBar)

        Settings {
            SettingsView(model: model)
                .frame(width: 620, height: 620)
        }
    }
}
#endif
