#if os(macOS)
import AppKit
import Foundation
import SentinelCore

@MainActor
final class SessionMonitor {
    private var workspaceTokens: [NSObjectProtocol] = []
    private var distributedTokens: [NSObjectProtocol] = []

    func start(handler: @escaping (SentryEventType) -> Void) {
        stop()
        let workspace = NSWorkspace.shared.notificationCenter
        workspaceTokens.append(workspace.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { _ in
            handler(.systemSleeping)
        })
        workspaceTokens.append(workspace.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { _ in
            handler(.systemWoke)
        })

        let distributed = DistributedNotificationCenter.default()
        distributedTokens.append(distributed.addObserver(
            forName: Notification.Name("com.apple.screenIsLocked"), object: nil, queue: .main
        ) { _ in handler(.sessionLocked) })
        distributedTokens.append(distributed.addObserver(
            forName: Notification.Name("com.apple.screenIsUnlocked"), object: nil, queue: .main
        ) { _ in handler(.sessionUnlocked) })
    }

    func stop() {
        let workspace = NSWorkspace.shared.notificationCenter
        workspaceTokens.forEach { workspace.removeObserver($0) }
        workspaceTokens.removeAll()

        let distributed = DistributedNotificationCenter.default()
        distributedTokens.forEach { distributed.removeObserver($0) }
        distributedTokens.removeAll()
    }
}
#endif
