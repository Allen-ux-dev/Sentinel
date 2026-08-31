import Foundation

public enum AppStringKey: String, Sendable, CaseIterable {
    case appName
    case sentryMode
    case startSentry
    case enterNow
    case cancel
    case stopSentry
    case protected
    case inactive
    case alert
    case recentEvents
    case noEvents
    case settings
    case events
    case diagnostics
    case dashboard
    case language
    case systemLanguage
    case chinese
    case english
    case autoArmOnLock
    case countdown
    case showRecentOnLock
    case retention
    case authThreshold
    case authWindow
    case highAlertDuration
    case alertSound
    case launchAtLogin
    case animationIntensity
    case cursorTracking
    case naturalBlink
    case clearHistory
    case experimentalAuth
    case authExperimentalUnavailable
    case accessibility
    case accessibilityRequired
    case openAccessibility
    case monitoringHealthy
    case monitoringInterrupted
    case network
    case power
    case usb
    case watchdog
    case armed
    case disarmed
    case lockInstruction
    case active
    case okay
    case helperIdle
    case helperHealthy
    case helperRecoveryAttempted
    case helperRecoveryBlocked
    case helperRecoveryFailed
    case noStatusYet
    case attempts
    case oneDay
    case sevenDays
    case thirtyDays
    case quiet
    case standard
    case lively
    case simulatePasswordFailure
    case simulateTouchIDFailure
    case debugAuthSuccess
    case captures
    case viewCapture
    case captureOnAuthFailure
    case captureFailed
    case capturePending
    case cameraPermission
    case cameraPermissionGranted
    case cameraPermissionDenied
    case requestCameraPermission
    case clearCaptures
    case noCaptures
    case captureQuality
    case captureRetention
    case captureStorageLimit
    case efficient
    case highQuality
    case captureDetail
    case deleteCapture
    case passwordFailure
    case touchIDFailure
    case unknownAuthentication
    case imageDimensions
    case fileSize
    case capturedAt
    case localOnlyCaptureNotice
    case aboutMe
    case developer
    case githubProfile
}

public enum AppStrings {
    private static let en: [AppStringKey: String] = [
        .appName: "Sentinel", .sentryMode: "Sentry Mode", .startSentry: "Start Sentry",
        .enterNow: "Enter Now", .cancel: "Cancel", .stopSentry: "Stop Sentry", .protected: "Protected",
        .inactive: "Inactive", .alert: "Alert", .recentEvents: "Recent Events", .noEvents: "No events yet",
        .settings: "Settings", .events: "Events", .diagnostics: "Diagnostics", .dashboard: "Dashboard",
        .language: "Language", .systemLanguage: "System", .chinese: "Simplified Chinese", .english: "English",
        .autoArmOnLock: "Auto-arm when Mac locks", .countdown: "Activation countdown",
        .showRecentOnLock: "Show recent events on Lock Screen", .retention: "Event retention",
        .authThreshold: "Authentication failure threshold", .authWindow: "Failure time window",
        .highAlertDuration: "High-alert duration", .alertSound: "Alert sound", .launchAtLogin: "Launch at login",
        .animationIntensity: "Animation intensity", .cursorTracking: "Cursor tracking",
        .naturalBlink: "Natural blinking", .clearHistory: "Clear Event History",
        .experimentalAuth: "Experimental authentication feedback",
        .authExperimentalUnavailable: "Authentication failure feedback is experimental and may be unavailable on this macOS version.",
        .accessibility: "Accessibility",
        .accessibilityRequired: "Accessibility permission is required to lock the Mac automatically.",
        .openAccessibility: "Open Accessibility Settings", .monitoringHealthy: "Monitoring is healthy",
        .monitoringInterrupted: "Monitoring interrupted", .network: "Network", .power: "Power", .usb: "USB",
        .watchdog: "Watchdog", .armed: "Armed", .disarmed: "Disarmed",
        .lockInstruction: "Sentinel is ready. macOS still owns password and Touch ID authentication.",
        .active: "Active", .okay: "OK", .helperIdle: "Idle", .helperHealthy: "Healthy",
        .helperRecoveryAttempted: "Recovery attempted", .helperRecoveryBlocked: "Recovery paused",
        .helperRecoveryFailed: "Recovery failed", .noStatusYet: "No status yet", .attempts: "attempts",
        .oneDay: "1 day", .sevenDays: "7 days", .thirtyDays: "30 days",
        .quiet: "Quiet", .standard: "Standard", .lively: "Lively",
        .simulatePasswordFailure: "Simulate Password Failure",
        .simulateTouchIDFailure: "Simulate Touch ID Failure",
        .debugAuthSuccess: "Simulate Auth Success",
        .captures: "Captures", .viewCapture: "View Capture",
        .captureOnAuthFailure: "Capture image on authentication failure",
        .captureFailed: "Capture failed", .capturePending: "Capturing…",
        .cameraPermission: "Camera Permission", .cameraPermissionGranted: "Granted",
        .cameraPermissionDenied: "Not granted", .requestCameraPermission: "Request Camera Permission",
        .clearCaptures: "Clear All Captures", .noCaptures: "No captures yet",
        .captureQuality: "Image quality", .captureRetention: "Capture retention",
        .captureStorageLimit: "Maximum capture storage", .efficient: "Efficient", .highQuality: "High",
        .captureDetail: "Capture Detail", .deleteCapture: "Delete Capture",
        .passwordFailure: "Password failure", .touchIDFailure: "Touch ID failure",
        .unknownAuthentication: "Authentication failure", .imageDimensions: "Dimensions",
        .fileSize: "File size", .capturedAt: "Captured at",
        .localOnlyCaptureNotice: "Captures stay on this Mac. No audio, video recording, or face recognition.",
        .aboutMe: "About Me", .developer: "Developer", .githubProfile: "GitHub Profile"
    ]

    private static let zh: [AppStringKey: String] = [
        .appName: "哨兵", .sentryMode: "哨兵模式", .startSentry: "启动哨兵模式",
        .enterNow: "立即进入", .cancel: "取消", .stopSentry: "停止哨兵", .protected: "正在保护",
        .inactive: "未启动", .alert: "警觉", .recentEvents: "最近事件", .noEvents: "暂无事件",
        .settings: "设置", .events: "事件", .diagnostics: "诊断", .dashboard: "主页",
        .language: "语言", .systemLanguage: "跟随系统", .chinese: "简体中文", .english: "English",
        .autoArmOnLock: "Mac 锁屏时自动进入哨兵", .countdown: "启动倒计时",
        .showRecentOnLock: "锁屏显示最近事件", .retention: "事件保留时间",
        .authThreshold: "认证失败次数阈值", .authWindow: "失败统计时间窗口",
        .highAlertDuration: "高警觉持续时间", .alertSound: "警报提示音", .launchAtLogin: "登录时启动",
        .animationIntensity: "动画强度", .cursorTracking: "鼠标视线跟随",
        .naturalBlink: "自然眨眼", .clearHistory: "清空事件记录",
        .experimentalAuth: "实验性认证反馈",
        .authExperimentalUnavailable: "认证失败反馈属于实验功能，当前 macOS 版本上可能无法可靠获取。",
        .accessibility: "辅助功能",
        .accessibilityRequired: "自动锁定 Mac 需要辅助功能权限。",
        .openAccessibility: "打开辅助功能设置", .monitoringHealthy: "监测运行正常",
        .monitoringInterrupted: "监测已中断", .network: "网络", .power: "电源", .usb: "USB",
        .watchdog: "守护进程", .armed: "已布防", .disarmed: "未布防",
        .lockInstruction: "哨兵已经准备好；密码和 Touch ID 始终由 macOS 自己负责。",
        .active: "运行中", .okay: "正常", .helperIdle: "空闲", .helperHealthy: "正常",
        .helperRecoveryAttempted: "已尝试恢复", .helperRecoveryBlocked: "已暂停自动恢复",
        .helperRecoveryFailed: "恢复失败", .noStatusYet: "暂无状态", .attempts: "次尝试",
        .oneDay: "1 天", .sevenDays: "7 天", .thirtyDays: "30 天",
        .quiet: "安静", .standard: "标准", .lively: "灵动",
        .simulatePasswordFailure: "模拟密码失败",
        .simulateTouchIDFailure: "模拟 Touch ID 失败",
        .debugAuthSuccess: "模拟认证成功",
        .captures: "捕获画面", .viewCapture: "查看捕获画面",
        .captureOnAuthFailure: "认证失败时捕获画面",
        .captureFailed: "捕获失败", .capturePending: "正在捕获…",
        .cameraPermission: "摄像头权限", .cameraPermissionGranted: "已授权",
        .cameraPermissionDenied: "未授权", .requestCameraPermission: "请求摄像头权限",
        .clearCaptures: "清空全部捕获", .noCaptures: "暂无捕获画面",
        .captureQuality: "图像质量", .captureRetention: "捕获保留时间",
        .captureStorageLimit: "捕获最大存储", .efficient: "节省空间", .highQuality: "高质量",
        .captureDetail: "捕获详情", .deleteCapture: "删除捕获",
        .passwordFailure: "密码认证失败", .touchIDFailure: "Touch ID 认证失败",
        .unknownAuthentication: "认证失败", .imageDimensions: "分辨率",
        .fileSize: "文件大小", .capturedAt: "捕获时间",
        .localOnlyCaptureNotice: "捕获画面只保存在这台 Mac。本功能不录音、不录像，也不做人脸识别。",
        .aboutMe: "关于我", .developer: "开发者", .githubProfile: "GitHub 主页"
    ]

    public static func resolvedLanguage(_ language: AppLanguage) -> AppLanguage {
        guard language == .system else { return language }
        let identifier = Locale.preferredLanguages.first?.lowercased() ?? "en"
        return identifier.hasPrefix("zh") ? .zhHans : .english
    }

    public static func text(_ key: AppStringKey, language: AppLanguage) -> String {
        let resolved = resolvedLanguage(language)
        switch resolved {
        case .zhHans: return zh[key] ?? en[key] ?? key.rawValue
        case .english, .system: return en[key] ?? key.rawValue
        }
    }
}
