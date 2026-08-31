#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ROOT_VIEW="$ROOT/Sources/SentinelApp/UI/RootView.swift"
EVENTS="$ROOT/Sources/SentinelApp/UI/EventsView.swift"
SETTINGS="$ROOT/Sources/SentinelApp/UI/SettingsView.swift"
GALLERY="$ROOT/Sources/SentinelApp/UI/CapturesView.swift"
DETAIL="$ROOT/Sources/SentinelApp/UI/CaptureDetailView.swift"

grep -q 'case captures' "$ROOT_VIEW" || { echo 'FAIL: Captures sidebar section missing.'; exit 1; }
[[ -f "$GALLERY" ]] || { echo 'FAIL: CapturesView.swift missing.'; exit 1; }
[[ -f "$DETAIL" ]] || { echo 'FAIL: CaptureDetailView.swift missing.'; exit 1; }
grep -q 'viewCapture' "$EVENTS" || { echo 'FAIL: event View Capture action missing.'; exit 1; }
grep -q 'captureOnAuthFailure' "$SETTINGS" || { echo 'FAIL: capture settings toggle missing.'; exit 1; }
grep -q 'captureImageQuality' "$SETTINGS" || { echo 'FAIL: capture quality picker missing.'; exit 1; }

echo 'PASS: capture sidebar, gallery, event action, detail, and settings UI are present.'
