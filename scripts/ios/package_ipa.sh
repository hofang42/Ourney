#!/usr/bin/env bash
# Package an unsigned Runner.app (from `flutter build ios --release --no-codesign`)
# into an unsigned .ipa. Runs on macOS or Linux (needs only bash, cp, zip).
#
# Usage: scripts/ios/package_ipa.sh [path/to/Runner.app] [output.ipa]
# Defaults: apps/mobile/build/ios/iphoneos/Runner.app -> ./Ourney-unsigned.ipa
set -euo pipefail

APP_DIR="${1:-apps/mobile/build/ios/iphoneos/Runner.app}"
OUT="${2:-Ourney-unsigned.ipa}"

if [ ! -d "$APP_DIR" ] || [ ! -f "$APP_DIR/Info.plist" ]; then
  echo "error: '$APP_DIR' is not an app bundle (no Info.plist). Run 'flutter build ios --release --no-codesign' first." >&2
  exit 1
fi
if ! command -v zip >/dev/null 2>&1; then
  echo "error: 'zip' not found" >&2
  exit 1
fi

OUT_DIR="$(cd "$(dirname "$OUT")" && pwd)"
OUT_ABS="$OUT_DIR/$(basename "$OUT")"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

mkdir "$WORK/Payload"
cp -R "$APP_DIR" "$WORK/Payload/"
rm -f "$OUT_ABS"
# -q quiet, -r recurse, -y keep symlinks (needed for frameworks inside the .app)
(cd "$WORK" && zip -qry "$OUT_ABS" Payload)

echo "Created $OUT_ABS ($(du -h "$OUT_ABS" | cut -f1))"
