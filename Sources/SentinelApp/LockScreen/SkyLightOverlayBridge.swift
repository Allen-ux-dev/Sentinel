#if os(macOS)
import SwiftUI
#if canImport(SkyLightWindow)
import SkyLightWindow
#endif

struct SkyLightOverlayBridge<Content: View>: View {
    let content: Content

    @ViewBuilder
    var body: some View {
        #if canImport(SkyLightWindow)
        content.moveToSky()
        #else
        content
        #endif
    }
}
#endif
