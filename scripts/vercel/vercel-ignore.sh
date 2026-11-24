#!/bin/sh
# Vercel Ignored Build Step for Ourney monorepo web projects (apps/landing, apps/admin).
#
# References:
#   - https://vercel.com/docs/project-configuration#ignorecommand
#   - https://vercel.com/docs/deployments/configure-a-build#ignored-build-step
#
# Vercel executes `ignoreCommand` from the project's configured Root Directory
# (e.g. `apps/landing` or `apps/admin`). An optional directory argument may also
# be passed (defaults to `.`).
#
# Exit code contract (per Vercel docs):
#   0 = skip / cancel build (no files changed in target directory)
#   1 = proceed with build (files changed, or base commit unavailable)

set -eu

TARGET_DIR="${1:-.}"

if [ ! -d "$TARGET_DIR" ]; then
  printf 'vercel-ignore: target directory "%s" does not exist; proceeding with build.\n' "$TARGET_DIR"
  exit 1
fi

if [ -n "${VERCEL_GIT_PREVIOUS_SHA:-}" ]; then
  BASE_REF="$VERCEL_GIT_PREVIOUS_SHA"
else
  BASE_REF="HEAD^"
fi

if ! git rev-parse --verify --quiet "${BASE_REF}^{commit}" >/dev/null 2>&1; then
  printf 'vercel-ignore: base commit "%s" is unavailable in this clone; proceeding with build.\n' "$BASE_REF"
  exit 1
fi

if git diff --quiet "$BASE_REF" HEAD -- "$TARGET_DIR"; then
  printf 'vercel-ignore: no changes in "%s" between %s and HEAD; skipping build.\n' "$TARGET_DIR" "$BASE_REF"
  exit 0
else
  printf 'vercel-ignore: changes detected in "%s" between %s and HEAD; proceeding with build.\n' "$TARGET_DIR" "$BASE_REF"
  exit 1
fi
