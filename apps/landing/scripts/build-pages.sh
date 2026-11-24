#!/bin/sh
# Assemble dist/ for Cloudflare Pages (ourney-landing).
# Copies all served static files from apps/landing/ into apps/landing/dist/,
# excluding authoring/config files (og-src/, scripts/, dist/, vercel.json,
# .vercelignore, .gitignore).
#
# Cloudflare Pages references:
#   - https://developers.cloudflare.com/pages/configuration/build-configuration/
#   - https://developers.cloudflare.com/pages/configuration/headers/
#   - https://developers.cloudflare.com/pages/configuration/redirects/
#   - https://developers.cloudflare.com/pages/configuration/serving-pages/

set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
LANDING_DIR=$(CDPATH='' cd -- "$SCRIPT_DIR/.." && pwd)
DIST_DIR="$LANDING_DIR/dist"

rm -rf "${DIST_DIR:?}"
mkdir -p "$DIST_DIR"

for entry in "$LANDING_DIR"/*; do
  [ -e "$entry" ] || continue
  name=$(basename -- "$entry")
  case "$name" in
    og-src|scripts|dist|vercel.json|.vercelignore|.gitignore)
      continue
      ;;
  esac
  cp -R "$entry" "$DIST_DIR/$name"
done

for required in _headers _redirects index.html 404.html f.html j.html p.html; do
  if [ ! -f "$DIST_DIR/$required" ]; then
    printf 'build-pages: missing required output file: %s\n' "$required" >&2
    exit 1
  fi
done
