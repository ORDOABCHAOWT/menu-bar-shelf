#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$ROOT_DIR/.build/release"
APP_NAME="MenuBarShelf"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
INSTALLED_APP="/Applications/$APP_NAME.app"
PUBLIC_BUNDLE_ID="io.github.ordoabchaowt.menubarshelf"
BUNDLE_ID="${APP_BUNDLE_ID:-$PUBLIC_BUNDLE_ID}"

# Preserve the identity of an existing local install; fresh public builds use PUBLIC_BUNDLE_ID.
if [[ -z "${APP_BUNDLE_ID:-}" && -f "$INSTALLED_APP/Contents/Info.plist" ]]; then
  EXISTING_BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$INSTALLED_APP/Contents/Info.plist" 2>/dev/null || true)"
  if [[ -n "$EXISTING_BUNDLE_ID" ]]; then
    BUNDLE_ID="$EXISTING_BUNDLE_ID"
  fi
fi

cd "$ROOT_DIR"
swift build -c release

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"

cp "$ROOT_DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" "$APP_BUNDLE/Contents/Info.plist"
cp "$ROOT_DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
/usr/bin/codesign --force --sign - --options runtime "$APP_BUNDLE"

echo "$APP_BUNDLE"
