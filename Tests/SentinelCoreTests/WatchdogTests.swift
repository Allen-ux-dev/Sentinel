import XCTest
@testable import SentinelCore

final class WatchdogTests: XCTestCase {
    func testHeartbeatIsStaleOnlyPastConfiguredAge() {
        let heartbeat = HeartbeatSnapshot(timestamp: Date(timeIntervalSince1970: 100), processID: 10)
        XCTAssertFalse(WatchdogPolicy.isHeartbeatStale(heartbeat, now: Date(timeIntervalSince1970: 125), staleAfter: 30))
        XCTAssertTrue(WatchdogPolicy.isHeartbeatStale(heartbeat, now: Date(timeIntervalSince1970: 131), staleAfter: 30))
    }

    func testMissingHeartbeatIsStaleWhenArmed() {
        XCTAssertTrue(WatchdogPolicy.requiresRecovery(armed: true, heartbeat: nil, now: Date(), staleAfter: 30))
        XCTAssertFalse(WatchdogPolicy.requiresRecovery(armed: false, heartbeat: nil, now: Date(), staleAfter: 30))
    }
}
