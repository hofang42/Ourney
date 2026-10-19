#!/usr/bin/env bash
# Creates the repository rulesets for main, release branches and v* tags.
# Run once as a repo admin:  gh auth login && bash scripts/github/setup-rulesets.sh
# Re-running is safe: existing rulesets with the same name are updated.
set -euo pipefail

REPO="${REPO:-hofang42/Ourney}"
ADMIN_BYPASS='[{"actor_id": 5, "actor_type": "RepositoryRole", "bypass_mode": "always"}]'

upsert() {
  local name="$1" body="$2" id
  id=$(gh api "repos/$REPO/rulesets" --jq ".[] | select(.name == \"$name\") | .id")
  if [ -n "$id" ]; then
    gh api -X PUT "repos/$REPO/rulesets/$id" --input - <<<"$body" --jq '"updated: \(.name) (#\(.id))"'
  else
    gh api -X POST "repos/$REPO/rulesets" --input - <<<"$body" --jq '"created: \(.name) (#\(.id))"'
  fi
}

# 1. main: PR + green CI (no approval required; anyone with write access can merge), no force-push, no deletion.
upsert "Protect main" "$(cat <<EOF
{
  "name": "Protect main",
  "target": "branch",
  "enforcement": "active",
  "conditions": {"ref_name": {"include": ["~DEFAULT_BRANCH"], "exclude": []}},
  "bypass_actors": $ADMIN_BYPASS,
  "rules": [
    {"type": "deletion"},
    {"type": "non_fast_forward"},
    {"type": "pull_request", "parameters": {
      "required_approving_review_count": 0,
      "dismiss_stale_reviews_on_push": false,
      "require_code_owner_review": false,
      "require_last_push_approval": false,
      "required_review_thread_resolution": true,
      "allowed_merge_methods": ["squash", "merge"]
    }},
    {"type": "required_status_checks", "parameters": {
      "strict_required_status_checks_policy": true,
      "do_not_enforce_on_create": false,
      "required_status_checks": [
        {"context": "ourney_core (dart test)"},
        {"context": "supabase (pgTAP + edge functions)"},
        {"context": "apps/mobile (codegen + analyze + test)"}
      ]
    }}
  ]
}
EOF
)"

# 2. release/**: no force-push, no deletion.
upsert "Protect release branches" "$(cat <<EOF
{
  "name": "Protect release branches",
  "target": "branch",
  "enforcement": "active",
  "conditions": {"ref_name": {"include": ["refs/heads/release/**"], "exclude": []}},
  "bypass_actors": $ADMIN_BYPASS,
  "rules": [{"type": "deletion"}, {"type": "non_fast_forward"}]
}
EOF
)"

# 3. v* tags trigger the IPA/APK release: only admins create, move or delete them.
upsert "Protect release tags" "$(cat <<EOF
{
  "name": "Protect release tags",
  "target": "tag",
  "enforcement": "active",
  "conditions": {"ref_name": {"include": ["refs/tags/v*"], "exclude": []}},
  "bypass_actors": $ADMIN_BYPASS,
  "rules": [{"type": "creation"}, {"type": "update"}, {"type": "deletion"}, {"type": "non_fast_forward"}]
}
EOF
)"

# Repo settings: delete merged branches, no rebase merges (matches allowed_merge_methods).
gh api -X PATCH "repos/$REPO" \
  -F delete_branch_on_merge=true -F allow_rebase_merge=false \
  -F allow_squash_merge=true -F allow_merge_commit=true \
  --jq '"settings: delete_branch_on_merge=\(.delete_branch_on_merge)"'

gh api "repos/$REPO/rulesets" --jq '.[] | "\(.id)\t\(.target)\t\(.enforcement)\t\(.name)"'
