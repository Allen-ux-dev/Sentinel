#if os(macOS)
import AppKit
import SwiftUI

@MainActor
final class OverlayWindowController {
    private weak var model: AppModel?
    private var windows: [NSWindow] = []

    init(model: AppModel) {
        self.model = model
    }

    func show() {
        guard windows.isEmpty, let model else { return }
        for screen in NSScreen.screens {
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false,
                screen: screen
            )
            window.setFrame(screen.frame, display: true)
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = false
            window.ignoresMouseEvents = true
            window.level = .screenSaver
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            window.contentView = NSHostingView(
                rootView: SkyLightOverlayBridge(content: SentinelLockScreenView(model: model))
            )
            window.orderFrontRegardless()
            windows.append(window)
        }
    }

    func hide() {
        windows.forEach { $0.orderOut(nil); $0.close() }
        windows.removeAll()
    }
}
#endif
