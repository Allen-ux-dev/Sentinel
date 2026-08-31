#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FILE="$ROOT/Sources/SentinelApp/Runtime/CameraCaptureService.swift"

[[ -f "$FILE" ]] || { echo "FAIL: CameraCaptureService.swift is missing."; exit 1; }
grep -q 'import AVFoundation' "$FILE" || { echo "FAIL: AVFoundation import missing."; exit 1; }
grep -q 'AVCapturePhotoOutput' "$FILE" || { echo "FAIL: one-shot photo output missing."; exit 1; }
grep -q 'requestAccess(for: .video' "$FILE" || { echo "FAIL: explicit camera permission request missing."; exit 1; }
grep -q 'stopRunning()' "$FILE" || { echo "FAIL: camera session is not explicitly stopped after a capture."; exit 1; }
grep -q 'using: .jpeg' "$FILE" || { echo "FAIL: JPEG compression path missing."; exit 1; }
grep -q 'continuousAutoExposure' "$FILE" || { echo "FAIL: continuous auto exposure configuration missing."; exit 1; }
grep -q 'continuousAutoWhiteBalance' "$FILE" || { echo "FAIL: continuous auto white balance configuration missing."; exit 1; }
grep -q 'CameraWarmupPolicy.minimumWarmupSeconds' "$FILE" || { echo "FAIL: camera warmup delay is not wired to policy."; exit 1; }
grep -q 'isAdjustingExposure' "$FILE" || { echo "FAIL: exposure settling is not checked before capture."; exit 1; }
grep -q 'averageLuma' "$FILE" || { echo "FAIL: black-frame luma validation missing."; exit 1; }
grep -q 'shouldRetryProbablyBlackFrame' "$FILE" || { echo "FAIL: black-frame retry policy missing."; exit 1; }

echo "PASS: camera capture service has permission, warmup, exposure settling, black-frame retry, stop, and JPEG compression paths."
