#!/usr/bin/env bash
# Release preflight (docs/runbooks/release.md). READ-ONLY: it never creates a tag, never pushes.
#
#   bash scripts/release/preflight.sh v0.1.0
#
# Checks, run from the repository you want to release:
#   1. tag looks like vX.Y.Z
#   2. version name in apps/mobile/pubspec.yaml equals X.Y.Z
#   3. working tree is clean
#   4. current branch is main and equals origin/main
#   5. the latest CI run on main succeeded and ran for this commit (gh, read-only)
#   6. the tag does not exist yet, locally or on origin
# On success it prints the commands for the admin to run. Exit codes: 0 ok, 1 a check failed, 2 usage.
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 vX.Y.Z" >&2
  exit 2
fi
TAG="$1"

if ! [[ "$TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "error: tag '$TAG' must look like vX.Y.Z (for example v0.1.0)" >&2
  exit 2
fi
VERSION="${TAG#v}"

for t in git gh; do
  if ! command -v "$t" > /dev/null 2>&1; then
    echo "error: required tool not found on PATH: $t" >&2
    exit 1
  fi
done

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

failures=0
ok() { echo "ok    $1"; }
fail() {
  echo "FAIL  $1" >&2
  failures=$((failures + 1))
}

# 2. pubspec version name (the part before '+')
PUBSPEC="apps/mobile/pubspec.yaml"
if [ -f "$PUBSPEC" ]; then
  pub_version="$(sed -n 's/^version:[[:space:]]*\([^+[:space:]]*\).*/\1/p' "$PUBSPEC" | head -n 1)"
  if [ "$pub_version" = "$VERSION" ]; then
    ok "pubspec version name is $pub_version"
  else
    fail "pubspec version name is '${pub_version:-<none>}', expected '$VERSION' (bump it in $PUBSPEC via a PR)"
  fi
else
  fail "$PUBSPEC not found"
fi

# 3. clean working tree (untracked files count)
if [ -z "$(git status --porcelain)" ]; then
  ok "working tree is clean"
else
  fail "working tree is not clean (commit or stash your changes)"
fi

# 4. on main and up to date with origin
branch="$(git rev-parse --abbrev-ref HEAD)"
if [ "$branch" = "main" ]; then
  ok "on branch main"
else
  fail "on branch '$branch', releases are cut from main"
fi
if git fetch --quiet origin main 2> /dev/null; then
  head_sha="$(git rev-parse HEAD)"
  origin_sha="$(git rev-parse refs/remotes/origin/main)"
  if [ "$head_sha" = "$origin_sha" ]; then
    ok "HEAD equals origin/main (${head_sha:0:7})"
  else
    fail "HEAD (${head_sha:0:7}) differs from origin/main (${origin_sha:0:7}); run: git pull --ff-only"
  fi
else
  fail "could not fetch origin/main"
  head_sha="$(git rev-parse HEAD)"
fi

# 5. latest CI run on main
ci_json="$(gh run list --branch main --workflow CI --limit 1 --json conclusion,headSha 2> /dev/null || true)"
ci_conclusion="$(printf '%s' "$ci_json" | sed -n 's/.*"conclusion":"\([a-z_]*\)".*/\1/p')"
ci_sha="$(printf '%s' "$ci_json" | sed -n 's/.*"headSha":"\([0-9a-f]*\)".*/\1/p')"
if [ -z "$ci_conclusion" ]; then
  fail "no finished CI run found on main (is gh logged in? is the run still in progress?)"
elif [ "$ci_conclusion" != "success" ]; then
  fail "latest CI run on main concluded '$ci_conclusion'"
elif [ -n "$ci_sha" ] && [ "$ci_sha" != "$head_sha" ]; then
  fail "latest CI run is for ${ci_sha:0:7}, not for HEAD (${head_sha:0:7})"
else
  ok "latest CI run on main succeeded"
fi

# 6. tag must not exist yet
if git rev-parse -q --verify "refs/tags/$TAG" > /dev/null; then
  fail "tag $TAG already exists locally"
elif [ -n "$(git ls-remote --tags origin "refs/tags/$TAG" 2> /dev/null || true)" ]; then
  fail "tag $TAG already exists on origin"
else
  ok "tag $TAG does not exist yet"
fi

echo
if [ "$failures" -gt 0 ]; then
  echo "Preflight FAILED ($failures problem(s)). Nothing was changed." >&2
  exit 1
fi

echo "Preflight passed. Nothing was created. As a repo admin, run:"
echo
echo "  git tag -a $TAG -m \"Ourney $TAG\""
echo "  git push origin $TAG"
echo
echo "The tag starts the iOS and Android workflows, which attach the IPA and APK to the Release."
