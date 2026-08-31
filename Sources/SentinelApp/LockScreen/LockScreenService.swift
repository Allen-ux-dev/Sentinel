#if os(macOS)
import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

struct LockScreenService {
    var isAccessibilityTrusted: Bool { AXIsProcessTrusted() }

    var isSessionLocked: Bool {
        guard let dictionary = CGSessionCopyCurrentDictionary() as? [String: Any],
              let value = dictionary["CGSSessionScreenIsLocked"]
        else { return false }
        if let boolean = value as? Bool { return boolean }
        if let number = value as? NSNumber { return number.boolValue }
        return false
    }

    @discardableResult
    func requestLock(promptIfNeeded: Bool) -> Bool {
        guard ensureAccessibility(prompt: promptIfNeeded) else { return false }

        guard let source = CGEventSource(stateID: .hidSystemState),
              let down = CGEvent(keyboardEventSource: source, virtualKey: 12, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: 12, keyDown: false)
        else { return false }

        down.flags = [.maskCommand, .maskControl]
        up.flags = [.maskCommand, .maskControl]
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
        return true
    }

    func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return }
        NSWorkspace.shared.open(url)
    }

    private func ensureAccessibility(prompt: Bool) -> Bool {
        if AXIsProcessTrusted() { return true }
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [key: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}
#endif
