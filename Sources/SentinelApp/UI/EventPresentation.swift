#if os(macOS)
import Foundation
import SentinelCore

enum EventPresentation {
    static func title(for type: SentryEventType, language: AppLanguage) -> String {
        let zh = AppStrings.resolvedLanguage(language) == .zhHans
        switch type {
        case .sentryArmed: return zh ? "哨兵已启动" : "Sentry armed"
        case .sentryDisarmed: return zh ? "哨兵已停止" : "Sentry disarmed"
        case .networkConnected: return zh ? "网络已连接" : "Network connected"
        case .networkDisconnected: return zh ? "网络已断开" : "Network disconnected"
        case .powerConnected: return zh ? "电源已连接" : "Power connected"
        case .powerDisconnected: return zh ? "电源已断开" : "Power disconnected"
        case .usbChanged: return zh ? "USB 设备状态变化" : "USB device changed"
        case .systemSleeping: return zh ? "Mac 即将睡眠" : "Mac sleeping"
        case .systemWoke: return zh ? "Mac 已唤醒" : "Mac woke"
        case .sessionLocked: return zh ? "Mac 已锁屏" : "Mac locked"
        case .sessionUnlocked: return zh ? "Mac 已解锁" : "Mac unlocked"
        case .authenticationFailed: return zh ? "认证失败" : "Authentication failed"
        case .authenticationSucceeded: return zh ? "认证成功" : "Authentication succeeded"
        case .authenticationAlert: return zh ? "连续认证失败警报" : "Repeated authentication failures"
        case .monitoringInterrupted: return zh ? "监测异常中断" : "Monitoring interrupted"
        case .monitoringRecovered: return zh ? "监测已恢复" : "Monitoring recovered"
        case .monitoringRecoveryFailed: return zh ? "监测恢复失败" : "Monitoring recovery failed"
        }
    }

    static func relativeTime(for date: Date, language: AppLanguage) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: AppStrings.resolvedLanguage(language) == .zhHans ? "zh_Hans" : "en_US")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
#endif
