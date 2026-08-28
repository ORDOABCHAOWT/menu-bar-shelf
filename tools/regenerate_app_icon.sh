#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ICONSET="$ROOT_DIR/Resources/AppIcon.iconset"
TIFF="$ROOT_DIR/Resources/AppIcon.tiff"
ICNS="$ROOT_DIR/Resources/AppIcon.icns"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

cd "$ROOT_DIR"
swift tools/generate_app_icon.swift >/dev/null
swift tools/check_icon_alpha.swift "$ICONSET/icon_512x512@2x.png"

mkdir -p "$TMP_DIR/tiffs"
for png in "$ICONSET"/*.png; do
  base="$(basename "$png" .png)"
  dpi=72
  if [[ "$base" == *@2x ]]; then
    dpi=144
  fi

  sips -s format tiff -s dpiWidth "$dpi" -s dpiHeight "$dpi" "$png" \
    --out "$TMP_DIR/tiffs/$base.tiff" >/dev/null
done

tiffutil -cat \
  "$TMP_DIR/tiffs/icon_16x16.tiff" \
  "$TMP_DIR/tiffs/icon_16x16@2x.tiff" \
  "$TMP_DIR/tiffs/icon_32x32.tiff" \
  "$TMP_DIR/tiffs/icon_32x32@2x.tiff" \
  "$TMP_DIR/tiffs/icon_128x128.tiff" \
  "$TMP_DIR/tiffs/icon_128x128@2x.tiff" \
  "$TMP_DIR/tiffs/icon_256x256.tiff" \
  "$TMP_DIR/tiffs/icon_256x256@2x.tiff" \
  "$TMP_DIR/tiffs/icon_512x512.tiff" \
  "$TMP_DIR/tiffs/icon_512x512@2x.tiff" \
  -out "$TIFF" >/dev/null

tiff2icns "$TIFF" "$ICNS"

iconutil -c iconset -o "$TMP_DIR/verify.iconset" "$ICNS"
icon_count="$(find "$TMP_DIR/verify.iconset" -maxdepth 1 -name '*.png' | wc -l | tr -d ' ')"
if [[ "$icon_count" -lt 5 ]]; then
  echo "Expected AppIcon.icns to contain at least 5 sizes, found $icon_count" >&2
  exit 1
fi

echo "$ICNS"
