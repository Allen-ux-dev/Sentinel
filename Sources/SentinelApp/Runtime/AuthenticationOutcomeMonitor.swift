#if os(macOS)
import Foundation
import SentinelCore

protocol AuthenticationOutcomeMonitor: AnyObject {
    var isAvailable: Bool { get }
    func start(handler: @escaping (AuthenticationOutcome) -> Void)
    func stop()
}
#endif
