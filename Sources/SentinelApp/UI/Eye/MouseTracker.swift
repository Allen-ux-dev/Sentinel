#if os(macOS)
import AppKit
import Combine

@MainActor
final class MouseTracker: ObservableObject {
    @Published private(set) var normalizedOffset: CGSize = .zero
    private var timer: Timer?

    func start() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.sample()
        }
        sample()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        normalizedOffset = .zero
    }

    private func sample() {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { $0.frame.contains(mouse) }) ?? NSScreen.main
        guard let screen else { normalizedOffset = .zero; return }
        let center = CGPoint(x: screen.frame.midX, y: screen.frame.midY)
        let halfW = max(1, screen.frame.width / 2)
        let halfH = max(1, screen.frame.height / 2)
        var x = (mouse.x - center.x) / halfW
        var y = -(mouse.y - center.y) / halfH
        let length = sqrt(x * x + y * y)
        if length > 1 {
            x /= length
            y /= length
        }
        let target = CGSize(width: x, height: y)
        let smoothing: CGFloat = 0.22
        normalizedOffset = CGSize(
            width: normalizedOffset.width + (target.width - normalizedOffset.width) * smoothing,
            height: normalizedOffset.height + (target.height - normalizedOffset.height) * smoothing
        )
    }
}
#endif
