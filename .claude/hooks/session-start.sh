#!/bin/bash
# SessionStart hook for Claude Code cloud sessions: installs the Flutter SDK (same version as CI)
# and fetches pub dependencies so `dart analyze`, `flutter analyze`, `dart test` and `flutter test`
# work out of the box. Local sessions are left alone.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# A SessionStart hook's stdout is fed to Claude as context; keep install logs out of it.
exec 1>&2

repo="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"

# Single source of truth for the Flutter version: the CI workflow.
version="$(sed -n 's/^ *FLUTTER_VERSION: *\([0-9.]*\).*/\1/p' "$repo/.github/workflows/ci.yml" | head -n 1)"
if [ -z "$version" ]; then
  echo "session-start: FLUTTER_VERSION not found in .github/workflows/ci.yml" >&2
  exit 1
fi

flutter_home=/opt/flutter
stamp="$flutter_home/.ourney-installed-version"

if [ "$(cat "$stamp" 2>/dev/null || true)" != "$version" ]; then
  echo "session-start: installing Flutter $version into $flutter_home" >&2
  base_url=https://storage.googleapis.com/flutter_infra_release/releases
  release="$(curl -fsSL "$base_url/releases_linux.json" \
    | jq -c --arg v "$version" '[.releases[] | select(.version == $v and .channel == "stable")][0]')"
  if [ "$release" = "null" ]; then
    echo "session-start: Flutter $version (stable) not found in releases_linux.json" >&2
    exit 1
  fi
  archive="$(jq -r '.archive' <<<"$release")"
  sha256="$(jq -r '.sha256' <<<"$release")"

  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  curl -fsSL -o "$tmp/flutter.tar.xz" "$base_url/$archive"
  echo "$sha256  $tmp/flutter.tar.xz" | sha256sum -c --quiet -
  rm -rf "$flutter_home"
  tar -xJf "$tmp/flutter.tar.xz" -C "$(dirname "$flutter_home")" --no-same-owner
  echo "$version" >"$stamp"
fi

# The SDK is a git checkout; avoid "dubious ownership" errors from the flutter tool.
if ! git config --global --get-all safe.directory | grep -qx "$flutter_home"; then
  git config --global --add safe.directory "$flutter_home"
fi

export PATH="$flutter_home/bin:$HOME/.pub-cache/bin:$PATH"
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"$flutter_home/bin:\$HOME/.pub-cache/bin:\$PATH\"" >>"$CLAUDE_ENV_FILE"
fi

flutter config --no-analytics --no-cli-animations >/dev/null
dart --disable-analytics >/dev/null

(cd "$repo/packages/ourney_core" && dart pub get)
(cd "$repo/apps/mobile" && flutter pub get)
