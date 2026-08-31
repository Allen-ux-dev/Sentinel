# Authentication Failure Capture Design

**Goal:** When Sentinel is armed and an authentication failure is detected, capture one visible-indicator camera still, compress it locally, attach it to the event record, and make captures reviewable from the app.

## Safety and privacy boundaries

- Capture is disabled by default.
- Enabling capture while unlocked requests macOS Camera permission up front; the app never attempts to bypass or hide the macOS camera-use indicator.
- Capture runs only while Sentinel is armed and only for authentication-failure events produced by Sentinel's existing experimental authentication monitor or Diagnostics simulator.
- Password contents, keystrokes, Touch ID biometric data, audio, face recognition, continuous video, cloud upload, and background covert capture are out of scope.
- A failed camera capture never suppresses the authentication event itself.

## Capture lifecycle

1. `AppModel.receive` receives an `authenticationFailed` event.
2. If capture is enabled and Sentinel is armed, the event is persisted with `captureState = pending`.
3. Capture requests are serialized so rapid failures do not overwrite a photo-output continuation.
4. `CameraCaptureService` captures one frame through AVFoundation and stops the session immediately afterward.
5. The frame is resized and JPEG-compressed according to the selected quality profile.
6. `CaptureStore` writes the JPEG under `Application Support/Sentinel/Captures/`, writes metadata, enforces retention and storage limits, and returns a `CaptureRecord`.
7. The event is updated with `captureState = available` and its `captureID`. On failure it becomes `captureState = failed` without recording sensitive error detail in the event.

## Storage model

`SentryEvent` gains optional backward-compatible `captureState` and `captureID` fields. `CaptureRecord` stores an ID, source event ID, timestamp, authentication kind, relative image filename, byte count, width, and height. `CaptureStore` owns `captures.json` plus JPEG files.

Defaults:

- retention: 7 days
- storage cap: 250 MB
- quality: Standard, fit within 960x540, JPEG quality about 0.58

Quality presets:

- Efficient: fit within 720x405, JPEG quality 0.42
- Standard: fit within 960x540, JPEG quality 0.58
- High: fit within 1280x720, JPEG quality 0.72

When the storage cap is exceeded, expired records are removed first, then the oldest remaining captures until the store is back under the cap.

## UI

The sidebar gains **Captures / 捕获画面**. The gallery uses a lazy grid of locally stored images with timestamp and authentication method. Selecting a card shows a detail sheet with the full image, timestamp, method, dimensions, file size, and Delete action.

Authentication-failure rows in Events show:

- a progress indication while capture is pending,
- **View Capture / 查看捕获画面** when available,
- **Capture failed / 捕获失败** if acquisition failed.

Settings adds a Capture section with the master toggle, quality, retention, storage cap, camera-permission status/action, and Clear All Captures.

## Localization

All new app-visible strings are present in English and Simplified Chinese. The bundle also includes localized `NSCameraUsageDescription` strings so the macOS permission prompt explains the feature in the user's system language.

## Failure handling

No camera, denied permission, camera in use, compression failure, or disk-write failure marks only that event's capture as failed. Existing Sentinel monitoring, event persistence, lock-screen UI, and alert behavior continue normally.

## Validation

Core tests cover defaults, backward-compatible event decoding, capture-store save/load/delete/retention/storage-cap behavior, event association updates, and bilingual strings. macOS manual tests cover first permission grant, denied permission, real/simulated authentication failure while armed, rapid failures, gallery/detail/deletion, retention cleanup, and lock-screen capture behavior.
