#!/bin/zsh
set -euo pipefail

cd "${0:A:h}"

APP_NAME="Sentinel"
BUNDLE_ID="dev.sentinel.mac"
DEST="/Applications/${APP_NAME}.app"
STAGE_ROOT="$PWD/.build/sentinel-package"
STAGE_APP="$STAGE_ROOT/${APP_NAME}.app"
INFO_PLIST="$PWD/Packaging/Info.plist"
LAUNCH_TEMPLATE="$PWD/Packaging/dev.sentinel.mac.helper.plist.template"
ICON_SOURCE="$PWD/Packaging/AppIcon-source.png"
ICONSET="$STAGE_ROOT/AppIcon.iconset"
LAUNCH_DIR="$HOME/Library/LaunchAgents"
LAUNCH_PLIST="$LAUNCH_DIR/dev.sentinel.mac.helper.plist"
LOG_DIR="$HOME/Library/Logs/Sentinel"
LOG_FILE="$LOG_DIR/helper.log"

function fail() {
  echo ""
  echo "❌ $1"
  exit 1
}

function run_as_needed() {
  if [[ -w /Applications ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

echo "=========================================="
echo " Sentinel v0.1 — Build + Safe Install"
echo "=========================================="

echo "[1/9] Validating source and integration guards..."
/bin/bash Tests/BuildGuards/helper_entrypoint_guard.sh || fail "Swift entry-point validation failed. Installed app was not touched."
/bin/bash Tests/BuildGuards/camera_capture_guard.sh || fail "Camera capture validation failed. Installed app was not touched."
/bin/bash Tests/BuildGuards/auth_capture_integration_guard.sh || fail "Authentication-capture integration validation failed. Installed app was not touched."
/bin/bash Tests/BuildGuards/capture_ui_guard.sh || fail "Capture UI validation failed. Installed app was not touched."
/bin/bash Tests/BuildGuards/icon_about_guard.sh || fail "App icon / About validation failed. Installed app was not touched."

echo "[2/9] Running core tests..."
swift test || fail "Tests failed. Installed app was not touched."

echo "[3/9] Building release binaries..."
swift build -c release --product Sentinel || fail "Sentinel release build failed."
swift build -c release --product SentinelHelper || fail "SentinelHelper release build failed."
BIN_DIR="$(swift build -c release --show-bin-path)"
[[ -x "$BIN_DIR/Sentinel" ]] || fail "Sentinel binary missing."
[[ -x "$BIN_DIR/SentinelHelper" ]] || fail "SentinelHelper binary missing."

echo "[4/9] Assembling staged app bundle..."
rm -rf "$STAGE_ROOT"
mkdir -p "$STAGE_APP/Contents/MacOS" "$STAGE_APP/Contents/Library/Helpers" "$STAGE_APP/Contents/Resources"
cp "$INFO_PLIST" "$STAGE_APP/Contents/Info.plist"
[[ -f "$ICON_SOURCE" ]] || fail "App icon source is missing."
mkdir -p "$ICONSET"
function make_icon() {
  local size="$1"
  local name="$2"
  /usr/bin/sips -z "$size" "$size" "$ICON_SOURCE" --out "$ICONSET/$name" >/dev/null || fail "App icon resize failed for $name."
}
make_icon 16 icon_16x16.png
make_icon 32 icon_16x16@2x.png
make_icon 32 icon_32x32.png
make_icon 64 icon_32x32@2x.png
make_icon 128 icon_128x128.png
make_icon 256 icon_128x128@2x.png
make_icon 256 icon_256x256.png
make_icon 512 icon_256x256@2x.png
make_icon 512 icon_512x512.png
make_icon 1024 icon_512x512@2x.png
/usr/bin/iconutil -c icns "$ICONSET" -o "$STAGE_APP/Contents/Resources/Sentinel.icns" || fail "App icon compilation failed."
for locale in en zh-Hans; do
  if [[ -d "$PWD/Packaging/${locale}.lproj" ]]; then
    mkdir -p "$STAGE_APP/Contents/Resources/${locale}.lproj"
    cp "$PWD/Packaging/${locale}.lproj/InfoPlist.strings" "$STAGE_APP/Contents/Resources/${locale}.lproj/InfoPlist.strings"
  fi
done
cp "$BIN_DIR/Sentinel" "$STAGE_APP/Contents/MacOS/Sentinel"
cp "$BIN_DIR/SentinelHelper" "$STAGE_APP/Contents/Library/Helpers/SentinelHelper"
chmod 755 "$STAGE_APP/Contents/MacOS/Sentinel" "$STAGE_APP/Contents/Library/Helpers/SentinelHelper"
printf 'APPL????' > "$STAGE_APP/Contents/PkgInfo"

echo "[5/9] Ad-hoc signing and validating stage..."
/usr/bin/codesign --force --deep --sign - "$STAGE_APP" || fail "Signing failed."
/usr/bin/codesign --verify --deep --strict --verbose=2 "$STAGE_APP" || fail "Staged signature verification failed."
/usr/bin/plutil -lint "$STAGE_APP/Contents/Info.plist" >/dev/null || fail "Info.plist validation failed."

echo "[6/9] Installing atomically to /Applications..."
TMP_DEST="/Applications/.Sentinel.app.new.$$"
BACKUP="/Applications/.Sentinel.app.backup.$$"
run_as_needed rm -rf "$TMP_DEST" "$BACKUP"
run_as_needed /usr/bin/ditto "$STAGE_APP" "$TMP_DEST"
if [[ -d "$DEST" ]]; then
  run_as_needed mv "$DEST" "$BACKUP"
fi
if ! run_as_needed mv "$TMP_DEST" "$DEST"; then
  [[ -d "$BACKUP" ]] && run_as_needed mv "$BACKUP" "$DEST"
  fail "Install failed; previous app was restored."
fi
if ! /usr/bin/codesign --verify --deep --strict --verbose=2 "$DEST"; then
  run_as_needed rm -rf "$DEST"
  [[ -d "$BACKUP" ]] && run_as_needed mv "$BACKUP" "$DEST"
  fail "Installed app failed verification; previous app was restored."
fi
run_as_needed rm -rf "$BACKUP"

echo "[7/9] Installing user watchdog LaunchAgent..."
mkdir -p "$LAUNCH_DIR" "$LOG_DIR"
HELPER_PATH="$DEST/Contents/Library/Helpers/SentinelHelper"
/usr/bin/sed \
  -e "s|__HELPER_PATH__|$HELPER_PATH|g" \
  -e "s|__LOG_PATH__|$LOG_FILE|g" \
  "$LAUNCH_TEMPLATE" > "$LAUNCH_PLIST.tmp"
/usr/bin/plutil -lint "$LAUNCH_PLIST.tmp" >/dev/null || fail "LaunchAgent plist validation failed."
mv "$LAUNCH_PLIST.tmp" "$LAUNCH_PLIST"
/bin/launchctl bootout "gui/$UID" "$LAUNCH_PLIST" >/dev/null 2>&1 || true
/bin/launchctl bootstrap "gui/$UID" "$LAUNCH_PLIST" || fail "Could not start SentinelHelper."
/bin/launchctl enable "gui/$UID/dev.sentinel.mac.helper" >/dev/null 2>&1 || true

echo "[8/9] Registering app bundle..."
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$DEST" >/dev/null 2>&1 || true

echo "[9/9] Launching Sentinel..."
/usr/bin/open "$DEST"

echo ""
echo "✅ Installed: $DEST"
echo "✅ User data remains in ~/Library/Application Support/Sentinel"
echo "ℹ️ First automatic lock may ask for Accessibility permission."
echo "ℹ️ Authentication-failure feedback is experimental; use Diagnostics to verify availability."
echo "ℹ️ Enabling authentication-failure captures will request macOS Camera permission while unlocked."
