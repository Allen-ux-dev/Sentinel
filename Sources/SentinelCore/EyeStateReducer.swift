public enum EyeStateReducer {
    public static func state(for event: SentryEvent) -> EyeState {
        switch event.type {
        case .authenticationAlert, .monitoringRecoveryFailed:
            return .alertHigh
        case .authenticationSucceeded, .sessionUnlocked:
            return .success
        case .systemSleeping:
            return .sleeping
        case .systemWoke:
            return .waking
        case .networkConnected, .networkDisconnected,
             .powerConnected, .powerDisconnected,
             .usbChanged, .authenticationFailed,
             .monitoringInterrupted, .monitoringRecovered,
             .sentryArmed, .sentryDisarmed,
             .sessionLocked:
            return .focus
        }
    }
}
