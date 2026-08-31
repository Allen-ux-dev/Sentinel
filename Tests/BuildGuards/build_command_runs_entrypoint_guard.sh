#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BUILD="$ROOT/Build.command"

for guard in \
  helper_entrypoint_guard.sh \
  camera_capture_guard.sh \
  auth_capture_integration_guard.sh \
  capture_ui_guard.sh \
  icon_about_guard.sh; do
  if ! grep -Fq "/bin/bash Tests/BuildGuards/$guard" "$BUILD"; then
    echo "FAIL: Build.command does not run $guard before compiling."
    exit 1
  fi
done

echo 'PASS: Build.command runs all Sentinel build guards before compiling.'
