# Sentinel v0.1 Manual macOS Validation

Run these checks on a real Mac after `./Build.command`. Core policy tests are automated; the items below require macOS UI/framework behavior and cannot be validated in the Linux build environment used to assemble this source package.

## 1. Launch / language
- Open Sentinel from `/Applications`.
- Switch System -> 简体中文 -> English and confirm Dashboard, Events, Settings and Diagnostics change immediately.
- Quit/reopen and confirm language persists.

## 2. Vector eye
- Confirm the outer silhouette is a complete circle.
- Confirm the upper/lower eyelids form an eye inside the circle and leave visible gaps from the outer ring on both sides.
- Move the pointer around the display: iris/pupil should follow with damping and remain bounded.
- Wait 15–30 seconds and confirm occasional natural blink.
- In Diagnostics, simulate several auth failures and confirm the last three reactions are not immediately repeated.

## 3. Secure Lock Screen path
- Open Accessibility settings from Diagnostics and grant Sentinel permission.
- Click Start Sentry. Verify the 5-second countdown and Enter Now.
- Confirm macOS itself opens the real Lock Screen.
- Confirm Sentinel does not present any custom password field.
- Confirm the eye overlay appears over the real Lock Screen through SkyLightWindow.
- Unlock normally and confirm the overlay disappears immediately.

## 4. Auto-arm
- Enable auto-arm on lock.
- Lock with Control-Command-Q outside Sentinel.
- Confirm Sentinel arms and displays the overlay.
- Unlock and confirm it disarms while retaining the auto-arm preference for the next lock.

## 5. Event monitors
- Disable/enable Wi-Fi or network connectivity: one network transition event per change.
- Connect/disconnect AC power: one power event per change.
- Insert/remove a USB device: one topology-change event per change; no serial number should appear on the lock screen.
- Sleep/wake the Mac and confirm events.

## 6. Authentication reaction adapter
- Diagnostics must show whether the experimental auth adapter is active.
- Intentionally enter an incorrect password only on your own test Mac and check whether a generic authentication-failure event is detected on this macOS version.
- If not detected, Diagnostics must continue to state that the adapter is experimental/unavailable; do not add keyboard capture as a workaround.
- Use the simulator buttons to validate the reaction engine regardless of adapter availability.

## 7. Alert threshold
- Using the simulator, trigger 3 failures within 2 minutes.
- Confirm a single true-alert event is created and only one short alert sound is produced.
- Confirm eye enters high alert for about 10 seconds then low alert.
- Simulate success and confirm failure count/state reset.

## 8. Timeline / privacy
- Enable lock-screen recent events and confirm only 2–3 short summaries appear.
- Confirm no username, IP address, USB serial number, password data, or fingerprint data is displayed.
- Clear Event History and confirm the local list empties.

## 9. Watchdog
- Arm Sentinel, then force-quit the main app from Activity Monitor.
- Wait at least 30 seconds; helper should attempt to relaunch it.
- Repeat failures and confirm helper stops after at most 3 recovery attempts within 5 minutes.
- Confirm helper status is visible in Diagnostics.
- Quit Sentinel normally and confirm helper does not treat it as a crash.

## 10. Multi-display / compatibility
- Test internal display only, then with an external display.
- Verify overlay windows are non-interactive and do not block system login controls.
- Test Retina and scaled display modes.
- After every macOS major update, retest SkyLight overlay before relying on it.

## 11. Authentication-failure still capture
- Before arming, open Settings -> Captures and confirm **Capture image on authentication failure** is off by default.
- Enable it while unlocked. Confirm macOS shows the normal Camera permission prompt and the app reports permission as granted after approval.
- Deny Camera permission once and confirm Sentinel leaves capture disabled and does not repeatedly prompt from the Lock Screen.
- With capture enabled, arm Sentinel and intentionally enter one incorrect password on your own test Mac. If the experimental authentication adapter reports the failure, confirm the camera indicator is visible briefly, the camera session stops, and one event becomes linked to one image.
- Repeat with Touch ID failure if the current macOS adapter reports it. If the adapter only reports a generic authentication failure, the capture should be labeled generic rather than guessing the method.
- Trigger multiple failures several seconds apart and confirm each detected failure receives its own image; captures must not overwrite each other.
- Open Events and use **View Capture / 查看捕获画面** from the authentication-failure row.
- Open the **Captures / 捕获画面** sidebar page and confirm the same image appears in the gallery with timestamp, method, dimensions, and compressed file size.
- Delete one capture and confirm its image file disappears and the old Events row no longer offers a broken View Capture link.
- Clear all captures and confirm the gallery becomes empty without deleting unrelated event history.
- Change quality between Efficient / Standard / High and verify dimensions stay within 720×405 / 960×540 / 1280×720 respectively while preserving aspect ratio.
- Set a small storage cap for testing, generate enough captures to exceed it, and confirm the oldest images are removed first.
- Change capture retention to 1 day and confirm expired metadata/images are pruned on the next settings save or capture.
- Confirm all image files remain under `~/Library/Application Support/Sentinel/Captures/`; no network upload should occur.
- Confirm there is no microphone access, continuous video recording, face recognition, password text, keyboard logging, or Touch ID biometric storage.
