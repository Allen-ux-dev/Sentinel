# Authentication Failure Capture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add privacy-bounded, compressed local camera stills linked to Sentinel authentication-failure events.

**Architecture:** Extend SentinelCore with backward-compatible capture metadata and a disk-backed `CaptureStore`; add a macOS-only AVFoundation still-capture service; integrate capture queueing in `AppModel`; surface captures in Events, a new gallery, and Settings. Camera permission is requested only from an explicit settings action, while actual captures run only when Sentinel is armed.

**Tech Stack:** Swift 5.9, SwiftUI, AppKit, AVFoundation, Foundation, XCTest, existing Swift Package / Build.command packaging.

**Spec:** `docs/superpowers/specs/2026-08-30-auth-failure-capture-design.md`

## Global Constraints

- macOS 13 minimum.
- Capture disabled by default.
- Never read or store password contents, keystrokes, Touch ID biometric data, audio, or face-recognition data.
- Never suppress the system camera-use indicator.
- Captures stay local and are JPEG-compressed.
- All new user-facing text must support English and Simplified Chinese.
- Existing eye-behavior update and SentinelHelper entry-point fix must remain intact.

---

### Task 1: Core capture model and persistence

**Files:**
- Modify: `Sources/SentinelCore/Models.swift`
- Modify: `Sources/SentinelCore/SentrySettings.swift`
- Modify: `Sources/SentinelCore/EventStore.swift`
- Create: `Sources/SentinelCore/CaptureStore.swift`
- Modify: `Tests/SentinelCoreTests/PersistenceTests.swift`
- Modify: `Tests/SentinelCoreTests/CoreBehaviorTests.swift`

**Interfaces:**
- Produces: `CaptureState`, `CaptureImageQuality`, `CaptureRecord`, `CaptureStore`, `EventStore.updateCapture(eventID:state:captureID:)`.

- [ ] Write failing tests for settings defaults, old-event decoding, event capture association, capture round-trip/delete, retention pruning, and storage-cap pruning.
- [ ] Run `swift test` and confirm those new tests fail because the capture types/APIs do not exist.
- [ ] Implement the minimal core models, store, and update API.
- [ ] Run `swift test` and confirm all core tests pass.
- [ ] Commit core persistence changes.

### Task 2: Bilingual strings and bundle camera permission

**Files:**
- Modify: `Sources/SentinelCore/AppStrings.swift`
- Modify: `Tests/SentinelCoreTests/CoreBehaviorTests.swift`
- Modify: `Packaging/Info.plist`
- Create: `Packaging/en.lproj/InfoPlist.strings`
- Create: `Packaging/zh-Hans.lproj/InfoPlist.strings`
- Modify: `Build.command`

**Interfaces:**
- Produces: new `AppStringKey` values and localized bundle resources.

- [ ] Write failing localization assertions for Captures, View Capture, capture toggle, capture failure, camera permission, and Clear Captures.
- [ ] Run `swift test` and confirm the localization test fails.
- [ ] Add bilingual app strings and camera usage-description resources; update Build.command to copy `.lproj` folders.
- [ ] Run `swift test`, shell syntax check, and plist validation.
- [ ] Commit localization and packaging changes.

### Task 3: macOS still-camera capture service

**Files:**
- Create: `Sources/SentinelApp/Runtime/CameraCaptureService.swift`

**Interfaces:**
- Produces: `CapturedFrame { data, width, height }`, `CameraCaptureService.authorizationStatus`, `requestPermission() async -> Bool`, `captureJPEG(quality:) async throws -> CapturedFrame`.

- [ ] Add a source-level build guard that requires AVFoundation capture and session-stop behavior in the service.
- [ ] Run the guard and confirm failure before the service exists.
- [ ] Implement one-shot AVFoundation photo capture, fit-resize, JPEG compression, and immediate session stop.
- [ ] Run the source guard and Swift parser checks available in this environment.
- [ ] Commit camera-service changes.

### Task 4: AppModel integration and serialized capture queue

**Files:**
- Modify: `Sources/SentinelApp/AppModel.swift`

**Interfaces:**
- Consumes: `CaptureStore`, `CameraCaptureService`, `SentryEvent.captureState`, `SentryEvent.captureID`.
- Produces: published `captures`, permission state, capture lookup/delete/clear/request-permission functions.

- [ ] Add a source-level integration guard for armed-only capture, pending/available/failed transitions, and serialized queueing.
- [ ] Run the guard and confirm failure before integration exists.
- [ ] Implement capture-store initialization, gallery loading, capture queueing, event update, retention cleanup, permission request, delete, and clear.
- [ ] Run core tests and source guards.
- [ ] Commit integration changes.

### Task 5: Captures gallery, event button, and settings UI

**Files:**
- Modify: `Sources/SentinelApp/UI/RootView.swift`
- Modify: `Sources/SentinelApp/UI/EventsView.swift`
- Modify: `Sources/SentinelApp/UI/SettingsView.swift`
- Create: `Sources/SentinelApp/UI/CapturesView.swift`
- Create: `Sources/SentinelApp/UI/CaptureDetailView.swift`

**Interfaces:**
- Consumes: AppModel capture APIs and localized strings.

- [ ] Add source-level UI guards for the Captures sidebar entry, gallery, event View Capture button, and capture settings.
- [ ] Run the guard and confirm it fails.
- [ ] Implement gallery/detail sheet, event-row capture states, and capture settings/permission controls.
- [ ] Run core tests and parser/source guards.
- [ ] Commit UI changes.

### Task 6: Documentation, build verification, and package

**Files:**
- Modify: `README.md`
- Modify: `docs/MANUAL-TESTS.md`

**Interfaces:**
- Produces: user-facing build/test package.

- [ ] Document privacy behavior, camera permission, capture storage defaults, and lock-screen manual test cases.
- [ ] Run `swift test`, all build guards, `bash -n`/`zsh -n` where available, and plist lint or XML parse validation.
- [ ] Verify the helper entry-point fix and eye-behavior files remain present.
- [ ] Create a clean ZIP excluding `.git`, `.build`, and worktree metadata; unzip it and rerun portable validations.
- [ ] Commit documentation and report any macOS-only verification that still requires the user's Mac.
