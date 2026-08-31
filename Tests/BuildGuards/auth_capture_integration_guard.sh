#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FILE="$ROOT/Sources/SentinelApp/AppModel.swift"

grep -q 'authenticationFailureCaptureEnabled && isArmed' "$FILE" || { echo 'FAIL: armed-only capture gate missing.'; exit 1; }
grep -q 'captureState = .pending' "$FILE" || { echo 'FAIL: pending capture state missing.'; exit 1; }
grep -q 'state: .available' "$FILE" || { echo 'FAIL: available capture state update missing.'; exit 1; }
grep -q 'state: .failed' "$FILE" || { echo 'FAIL: failed capture state update missing.'; exit 1; }
grep -q 'captureTail' "$FILE" || { echo 'FAIL: serialized capture queue missing.'; exit 1; }
grep -q 'requestCameraPermission' "$FILE" || { echo 'FAIL: explicit camera permission action missing.'; exit 1; }
grep -q 'timestamp: Date()' "$FILE" || { echo 'FAIL: capture record must use actual photo time.'; exit 1; }

echo 'PASS: AppModel gates, queues, and persists authentication-failure captures.'
