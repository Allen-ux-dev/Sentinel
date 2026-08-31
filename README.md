# Sentinel / 哨兵

Sentinel is a native macOS lock-screen companion built around a calm, vector-drawn “living eye”. macOS continues to own the real password and Touch ID UI; Sentinel only adds a visual overlay and privacy-safe local event monitoring.

哨兵是一个原生 macOS 锁屏伴随工具。核心 UI 是实时矢量绘制的“哨兵之眼”：外圈保持圆形，内部是悬浮的 👁️ 形上下眼睑，左右端点与外圆之间保留小空隙；瞳孔跟随鼠标，平时缓慢呼吸，事件发生时会眨眼、侧目、收瞳或产生波纹。

## v0.1 已实现 / Included

- 原生 SwiftUI + AppKit；无 WebView / Electron。
- 中英文切换：跟随系统 / 简体中文 / English。
- 实时 Canvas/Bézier 眼睛绘制；不使用写实眼球图片。
- 呼吸、鼠标跟随、自然眨眼、反重复认证失败反应池与低概率彩蛋反应。
- 手动启动哨兵，默认 5 秒倒计时，可立即进入；可配置 0/3/5/10 秒。
- 可设置“Mac 锁屏时自动进入哨兵模式”。
- 真实 macOS 锁屏仍负责密码与 Touch ID。
- SkyLightWindow 锁屏层覆盖（私有 SkyLight API，单独隔离）。
- 网络、电源、USB、睡眠/唤醒、锁屏/解锁事件。
- 本地 JSON 事件时间线，默认 7 天自动清理。
- 连续认证失败策略：默认 2 分钟内 3 次 -> 高警觉 10 秒 -> 低警觉。
- Watchdog Helper：心跳过期后 5 分钟内最多尝试恢复 3 次，防止崩溃循环。
- 普通事件静音；真正警报只播放一次轻提示音。

## Authentication feedback limitation / 认证反馈限制

macOS does **not** expose a stable public API that reports every wrong Lock Screen password or Touch ID failure to third-party apps. Sentinel therefore uses a narrow **experimental system-log outcome adapter**. It only looks for authentication-result messages and never records keyboard input, password text, password length, fingerprint data, or Secure Enclave content.

macOS 没有稳定的公开 API 可以让第三方 App 获取每一次锁屏密码/Touch ID 失败。因此 v0.1 的失败反馈是“实验性结果监听”。它不会读取按键、密码、密码长度、指纹或 Secure Enclave 数据。诊断页会明确显示该适配器在当前系统上是否可用，并提供“模拟认证失败/成功”按钮用于验证整套眼睛动画和警报状态机。

## Build & install

Requires macOS 13+ and a Swift/Xcode toolchain. The build downloads the MIT-licensed `SkyLightWindow` Swift package.

```bash
chmod +x Build.command
./Build.command
```

`Build.command` first runs tests and release builds. Only after the staged app is signed and verified does it replace `/Applications/Sentinel.app`. If final verification fails, it restores the previous installed app. User settings/history stay under `~/Library/Application Support/Sentinel` and are not deleted by updates.

自动锁屏使用 macOS 的 Control-Command-Q 锁屏动作，因此首次使用可能需要给 Sentinel **辅助功能（Accessibility）** 权限。如果不授权，你仍然可以手动按 `Control + Command + Q`，哨兵会在收到系统锁屏事件后显示。

## Important boundaries

- Sentinel never implements its own password field.
- Sentinel never captures password/Touch ID content.
- The overlay must never block system unlock.
- If SkyLight changes on a future macOS release, monitoring should continue even if the overlay cannot be shown.
- v0.1 is local-only: no cloud upload, remote camera, or remote surveillance.

## Inspiration & attribution / 灵感来源与致谢

Sentinel was **not designed in a vacuum**. Its original inspiration came from [Lakr233/Sentry](https://github.com/Lakr233/Sentry), which explores the idea of leaving a macOS security monitor running while the owner steps away from the computer. Seeing that concept — together with Lakr233's [SkyLightWindow](https://github.com/Lakr233/SkyLightWindow) framework — inspired this project to explore a different interaction direction: a calm, vector-drawn “living eye” that turns monitoring state into visible behavior on the real macOS Lock Screen.

Sentinel is a separate implementation. Its own design includes the circular vector eye, breathing/blinking/gaze behavior, reaction pools, bilingual UI, local event timeline, watchdog/recovery system, authentication-failure state machine, and optional still-image capture workflow.

Sentinel was **not** designed from scratch with no reference. The project deliberately credits its upstream inspiration:

- **Product inspiration:** [Lakr233/Sentry](https://github.com/Lakr233/Sentry)
- **Lock-screen/window dependency:** [Lakr233/SkyLightWindow](https://github.com/Lakr233/SkyLightWindow), MIT licensed

中文：Sentinel 的最初灵感来自 **Lakr233 的 Sentry**。Sentry 提出了“人在离开 Mac 后，让电脑继续处于安全监测状态”的思路；同时，**SkyLightWindow** 展示了使用 macOS SkyLight 机制把自定义界面放到非常高的系统窗口层级的可能性。在这个基础上，Sentinel 选择了自己的设计方向：把监测状态做成一只实时矢量绘制、会呼吸、眨眼、注视并对事件作出反应的“哨兵之眼”。项目会明确保留这份灵感与依赖致谢。

See [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) for details.

## Download & install / 下载与安装

For normal users, download the latest macOS build from **GitHub Releases**. The release package contains `Sentinel.app` and `Install.command`. Keep them in the same folder and double-click `Install.command`; it safely installs Sentinel to `/Applications/Sentinel.app`.

普通用户请从 **GitHub Releases** 下载最新 macOS 版本。发布包中会包含 `Sentinel.app` 与 `Install.command`。将二者放在同一文件夹，双击 `Install.command` 即可安装到 `/Applications/Sentinel.app`。

Developers can build from source with `Build.command` as described below.

## Eye behavior update

- Natural idle blinking now occurs more frequently (roughly every 3–7 seconds), with occasional double blinks.
- Iris and pupil rendering is clipped to the live eyelid shape so neither can draw outside the eyelids during blinks, squints, or alerts.
- Cursor tracking uses smaller gaze travel and automatically reduces vertical travel as the eyelids close.
- The pupil has a subtle independent idle contraction/expansion pulse while existing alert reactions can still constrict it more strongly.

## Authentication-failure captures / 认证失败捕获

Sentinel can optionally capture **one still image** when an authentication failure is detected while Sentry Mode is armed. This feature is **off by default**. Enabling it while the Mac is unlocked requests normal macOS Camera permission; Sentinel does not hide or suppress the system camera-use indicator.

哨兵可以选择在“哨兵模式已布防”且检测到认证失败时捕获 **一张静态画面**。该功能默认关闭。用户在解锁状态下主动开启后，Sentinel 会请求正常的 macOS 摄像头权限；不会隐藏系统的摄像头使用指示。

- Default quality: Standard, fit within 960×540, JPEG-compressed.
- Default retention: 7 days.
- Default maximum capture storage: 250 MB; oldest captures are removed automatically when the limit is exceeded.
- Captures are stored only under `~/Library/Application Support/Sentinel/Captures/` and indexed by local metadata.
- The Events page links each successfully captured authentication-failure event to **View Capture / 查看捕获画面**.
- The new **Captures / 捕获画面** sidebar page shows the local gallery and supports per-image deletion or clearing all captures.
- A camera/permission/storage failure leaves the authentication event intact and marks only the image capture as failed.
- No audio, continuous video, face recognition, password contents, keystrokes, or Touch ID biometric data are captured.

Because authentication-failure detection itself remains experimental on macOS, real Lock Screen capture triggering must be validated on the target Mac. Sentinel will not fall back to keyboard logging or password interception if macOS does not expose a reliable failure event.

## License

Sentinel is released under the [Apache License 2.0](LICENSE). Third-party projects and dependencies retain their own copyright notices and licenses. In particular, SkyLightWindow and the upstream Sentry project are MIT-licensed projects by Lakr Aream.

Sentinel 使用 [Apache License 2.0](LICENSE) 开源。第三方项目与依赖继续保留各自原有的版权与许可；其中 SkyLightWindow 与上游 Sentry 项目均由 Lakr Aream 以 MIT License 发布。
