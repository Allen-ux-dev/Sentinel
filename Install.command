#!/bin/bash
set -euo pipefail

APP_NAME="Sentinel.app"
DEST="/Applications/$APP_NAME"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_APP="$SCRIPT_DIR/$APP_NAME"
SOURCE_ZIP="$SCRIPT_DIR/Sentinel.app.zip"
TMP_DIR=""
BACKUP=""

cleanup() {
  if [[ -n "${TMP_DIR:-}" && -d "$TMP_DIR" ]]; then
    rm -rf "$TMP_DIR"
  fi
}
trap cleanup EXIT

echo "=========================================="
echo " Sentinel — Install to Applications"
echo "=========================================="
echo

if [[ ! -d "$SOURCE_APP" ]]; then
  if [[ -f "$SOURCE_ZIP" ]]; then
    TMP_DIR="$(mktemp -d)"
    echo "[1/4] Extracting Sentinel.app..."
    ditto -x -k "$SOURCE_ZIP" "$TMP_DIR"
    SOURCE_APP="$TMP_DIR/$APP_NAME"
  else
    echo "❌ Sentinel.app was not found next to Install.command."
    echo "   Put Sentinel.app (or Sentinel.app.zip) in the same folder and run again."
    exit 1
  fi
else
  echo "[1/4] Found Sentinel.app."
fi

if [[ ! -d "$SOURCE_APP" ]]; then
  echo "❌ The archive did not contain Sentinel.app at its top level."
  exit 1
fi

if [[ -f "$SOURCE_APP/Contents/Info.plist" ]]; then
  BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$SOURCE_APP/Contents/Info.plist" 2>/dev/null || true)"
  if [[ "$BUNDLE_ID" != "dev.sentinel.mac" ]]; then
    echo "❌ Unexpected bundle identifier: ${BUNDLE_ID:-missing}"
    echo "   Refusing to install a bundle that is not Sentinel."
    exit 1
  fi
else
  echo "❌ Sentinel.app is missing Contents/Info.plist."
  exit 1
fi

echo "[2/4] Verifying app bundle..."
if ! codesign --verify --deep --strict "$SOURCE_APP" 2>/dev/null; then
  echo "⚠️  Signature verification did not pass."
  echo "   This build may be ad-hoc signed. Installation can continue, but macOS may show a security prompt."
fi

if [[ -e "$DEST" ]]; then
  BACKUP="/Applications/.Sentinel.previous.$(date +%Y%m%d%H%M%S).app"
  echo "[3/4] Backing up the currently installed Sentinel..."
  mv "$DEST" "$BACKUP"
else
  echo "[3/4] No existing Sentinel installation found."
fi

install_failed=0
if ! ditto "$SOURCE_APP" "$DEST"; then
  install_failed=1
fi

if [[ "$install_failed" -ne 0 || ! -d "$DEST" ]]; then
  echo "❌ Installation failed."
  rm -rf "$DEST" 2>/dev/null || true
  if [[ -n "$BACKUP" && -d "$BACKUP" ]]; then
    mv "$BACKUP" "$DEST"
    echo "   Previous Sentinel installation was restored."
  fi
  exit 1
fi

if [[ -n "$BACKUP" && -d "$BACKUP" ]]; then
  rm -rf "$BACKUP"
fi


echo "[4/4] Installed successfully: $DEST"
echo
open "$DEST"
echo "✅ Sentinel is now in /Applications and has been opened."
