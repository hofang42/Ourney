#!/usr/bin/env bash
# 24-hour UGC moderation review CLI (CS-03, Apple Guideline 1.2 / Google Play UGC Policy).
#
# Usage:
#   SUPABASE_URL=https://<ref>.supabase.co SUPABASE_SERVICE_ROLE_KEY=... \
#     bash scripts/moderation/review.sh <command> [args...]
#
# Commands:
#   list [open|actioned|dismissed|all] [limit]   List moderation queue items ordered by 24h due_at
#   dismiss <queue-id> [note]                    Dismiss a report (restores auto-quarantined content)
#   remove  <queue-id> [note]                    Remove reported check-in/message content
#   ban     <queue-id> [note]                    Remove content, soft-delete/suspend user & revoke links
#   add-word <term> [vi|en|any] [word|substring|diacritic_word] [category]
#                                                Upsert an objectionable term without a deploy
#   disable-word <term>                          Disable an existing objectionable term without a deploy
#   notify                                       Trigger the notify-moderation Edge Function
#
# Secrets are passed to curl via a process-substituted config file, never on the command line.
set -euo pipefail

usage() {
  cat >&2 << 'EOF'
Usage: scripts/moderation/review.sh <command> [args...]

Commands:
  list [open|actioned|dismissed|all] [limit]
  dismiss <queue-id> [note]
  remove  <queue-id> [note]
  ban     <queue-id> [note]
  add-word <term> [vi|en|any] [word|substring|diacritic_word] [profanity|slur|sexual|csae|self_harm|violence]
  disable-word <term>
  notify
EOF
}

if [ "$#" -eq 0 ]; then
  usage
  exit 2
fi

case "${1:-}" in
  -h | --help)
    usage
    exit 0
    ;;
esac

missing=()
for v in SUPABASE_URL SUPABASE_SERVICE_ROLE_KEY; do
  if [ -z "${!v:-}" ]; then missing+=("$v"); fi
done
if [ "${#missing[@]}" -gt 0 ]; then
  echo "error: missing required environment variable(s): ${missing[*]}" >&2
  exit 1
fi

url_re='^(https://[^/[:space:]]+|http://(127\.0\.0\.1|localhost)(:[0-9]+)?)$'
SUPABASE_URL="${SUPABASE_URL%/}"
if ! [[ "$SUPABASE_URL" =~ $url_re ]]; then
  echo "error: SUPABASE_URL must start with https:// (or http://127.0.0.1 / http://localhost)" >&2
  exit 1
fi

bad_key_re='[[:space:]"\\]'
if [[ "$SUPABASE_SERVICE_ROLE_KEY" =~ $bad_key_re ]]; then
  echo "error: SUPABASE_SERVICE_ROLE_KEY contains whitespace, a quote or a backslash" >&2
  exit 1
fi

for t in curl jq; do
  if ! command -v "$t" > /dev/null 2>&1; then
    echo "error: required tool not found on PATH: $t" >&2
    exit 1
  fi
done

uuid_re='^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'

call_rpc() {
  local fn="$1"
  curl --silent --show-error --fail-with-body -X POST \
    --config <(printf 'header = "apikey: %s"\nheader = "Authorization: Bearer %s"\n' \
      "$SUPABASE_SERVICE_ROLE_KEY" "$SUPABASE_SERVICE_ROLE_KEY") \
    -H 'Content-Type: application/json' \
    --data-binary @- \
    "$SUPABASE_URL/rest/v1/rpc/$fn"
}

cmd="$1"
shift

case "$cmd" in
  list)
    status="${1:-open}"
    limit="${2:-50}"
    case "$status" in
      open | actioned | dismissed | all) ;;
      *)
        echo "error: status must be one of: open, actioned, dismissed, all" >&2
        exit 2
        ;;
    esac
    case "$limit" in
      '' | *[!0-9]*)
        echo "error: limit must be a positive integer" >&2
        exit 2
        ;;
    esac
    jq -n --arg s "$status" --argjson l "$((10#$limit))" \
      '{p_status: $s, p_limit: $l}' | call_rpc "list_moderation_queue" | jq .
    ;;

  dismiss | remove | ban)
    queue_id="${1:-}"
    note="${2:-}"
    if ! [[ "$queue_id" =~ $uuid_re ]]; then
      echo "error: <queue-id> must be a UUID" >&2
      exit 2
    fi
    action="remove_content"
    if [ "$cmd" = "dismiss" ]; then action="dismiss"; fi
    if [ "$cmd" = "ban" ]; then action="ban_user"; fi
    jq -n --arg id "$queue_id" --arg act "$action" --arg note "$note" \
      '{p_queue_id: $id, p_action: $act, p_note: (if $note == "" then null else $note end)}' |
      call_rpc "resolve_moderation_item" | jq .
    ;;

  add-word)
    term="${1:-}"
    lang="${2:-vi}"
    mode="${3:-word}"
    category="${4:-profanity}"
    if [ -z "$term" ]; then
      echo "error: add-word requires <term>" >&2
      exit 2
    fi
    jq -n --arg t "$term" --arg l "$lang" --arg m "$mode" --arg c "$category" \
      '{p_term: $t, p_lang: $l, p_match_mode: $m, p_category: $c, p_enabled: true}' |
      call_rpc "upsert_objectionable_word"
    echo "Updated objectionable word: $term ($lang, $mode, $category)"
    ;;

  disable-word)
    term="${1:-}"
    if [ -z "$term" ]; then
      echo "error: disable-word requires <term>" >&2
      exit 2
    fi
    jq -n --arg t "$term" \
      '{p_term: $t, p_enabled: false}' |
      call_rpc "set_objectionable_word_enabled"
    echo "Disabled objectionable word: $term"
    ;;

  notify)
    curl --silent --show-error --fail-with-body -X POST \
      --config <(printf 'header = "Authorization: Bearer %s"\n' "$SUPABASE_SERVICE_ROLE_KEY") \
      -H 'Content-Type: application/json' \
      -d '{}' \
      "$SUPABASE_URL/functions/v1/notify-moderation" | jq .
    ;;

  *)
    echo "error: unknown command: $cmd" >&2
    usage
    exit 2
    ;;
esac
