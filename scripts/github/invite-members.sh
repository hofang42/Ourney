#!/usr/bin/env bash
# Invites the Ourney contributors (docs/TASKS.md §2) to the repo with `push` (write) permission.
#
#   bash scripts/github/invite-members.sh            # dry run: prints what it would do
#   bash scripts/github/invite-members.sh --apply    # really sends the invitations
#
# Run as a repo admin after `gh auth login`. Safe to re-run: users who are already collaborators
# with at least push, or who already have a pending invitation, are skipped.
# Only GET requests are made unless --apply is given.
set -euo pipefail

REPO="${REPO:-hofang42/Ourney}"
PERMISSION="push"
USERS=(thydynh03 lken1514 nguyenductien-qnm)

DRY_RUN=1
for arg in "$@"; do
  case "$arg" in
    --apply) DRY_RUN=0 ;;
    -h | --help)
      echo "Usage: $0 [--apply]   (default is a dry run)"
      exit 0
      ;;
    *)
      echo "error: unknown argument: $arg" >&2
      echo "Usage: $0 [--apply]" >&2
      exit 2
      ;;
  esac
done

if ! command -v gh > /dev/null 2>&1; then
  echo "error: GitHub CLI (gh) not found on PATH" >&2
  exit 1
fi

if [ "$DRY_RUN" -eq 1 ]; then
  echo "DRY RUN for $REPO (no changes). Pass --apply to send invitations."
else
  echo "APPLY mode for $REPO."
fi

# Fail clearly when gh is not logged in instead of treating every call as "not a collaborator".
if ! gh api user --jq '.login' > /dev/null 2>&1; then
  echo "error: gh is not authenticated (or GitHub is unreachable). Run: gh auth login" >&2
  exit 1
fi

# Logins with a pending invitation (read-only). Needs admin rights on the repo.
if ! pending="$(gh api "repos/$REPO/invitations" --jq '.[].invitee.login' 2> /dev/null)"; then
  if [ "$DRY_RUN" -eq 0 ]; then
    echo "error: cannot list invitations for $REPO (admin rights needed)" >&2
    exit 1
  fi
  echo "warn: cannot list invitations for $REPO (admin rights needed); pending ones are not detected" >&2
  pending=""
fi

for u in "${USERS[@]}"; do
  # Effective permission: admin | maintain | write | triage | read | none.
  # A 404 means "not a collaborator"; any other error is fatal (never guess).
  if ! perm="$(gh api "repos/$REPO/collaborators/$u/permission" --jq '.permission' 2>&1)"; then
    if [[ "$perm" == *"404"* ]]; then
      perm=""
    else
      echo "error: could not read the permission of @$u on $REPO: $perm" >&2
      exit 1
    fi
  fi
  case "$perm" in
    admin | maintain | write)
      echo "skip   @$u: already a collaborator with '$perm' (>= $PERMISSION)"
      continue
      ;;
  esac
  if grep -qix "$u" <<<"$pending"; then
    echo "skip   @$u: invitation already pending"
    continue
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "would  invite @$u with permission=$PERMISSION (current: ${perm:-none})"
  else
    echo "invite @$u with permission=$PERMISSION"
    gh api -X PUT "repos/$REPO/collaborators/$u" -f "permission=$PERMISSION" --silent
  fi
done

echo
echo "Pending invitations for $REPO:"
if list="$(gh api "repos/$REPO/invitations" --jq '.[] | "  @\(.invitee.login) (\(.permissions))"' 2> /dev/null)"; then
  echo "${list:-  (none)}"
else
  echo "  (cannot list: admin rights needed)"
fi
