#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SETTINGS="$ROOT/Sources/SentinelApp/UI/SettingsView.swift"
INFO="$ROOT/Packaging/Info.plist"
ICON_SOURCE="$ROOT/Packaging/AppIcon-source.png"
BUILD="$ROOT/Build.command"

[[ -f "$ICON_SOURCE" ]] || { echo "FAIL: missing app icon source."; exit 1; }

grep -q '<key>CFBundleIconFile</key><string>Sentinel.icns</string>' "$INFO" || { echo 'FAIL: Info.plist does not declare Sentinel.icns.'; exit 1; }
grep -q 'sips -z' "$BUILD" || { echo 'FAIL: Build.command does not generate icon sizes from the source icon.'; exit 1; }
grep -q 'iconutil' "$BUILD" || { echo 'FAIL: Build.command does not compile the generated iconset.'; exit 1; }
grep -q 'model.text(.aboutMe)' "$SETTINGS" || { echo 'FAIL: About Me section missing from Settings.'; exit 1; }
grep -q 'https://github.com/Allen-ux-dev' "$SETTINGS" || { echo 'FAIL: GitHub profile link missing from Settings.'; exit 1; }

echo 'PASS: app icon and About Me integration are present.'
