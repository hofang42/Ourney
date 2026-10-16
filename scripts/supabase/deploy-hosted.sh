#!/usr/bin/env bash
# Deploys the Ourney backend to a HOSTED Supabase project (docs/runbooks/hosted-supabase.md).
#
#   SUPABASE_ACCESS_TOKEN=... SUPABASE_PROJECT_REF=... SUPABASE_DB_PASSWORD=... \
#     bash scripts/supabase/deploy-hosted.sh [--dry-run]
#
# Steps: link -> db push (supabase/migrations) -> functions deploy -> optional SMTP (H2).
# --dry-run only links and runs `supabase db push --dry-run`; nothing is changed on the project.
# Idempotent: db push applies only new migrations, functions deploy overwrites, the SMTP PATCH
# sets the same values again.
#
# Optional SMTP (all four required together, otherwise the script fails before doing anything):
#   SMTP_HOST SMTP_USER SMTP_PASS SMTP_SENDER_EMAIL
#   SMTP_PORT (default 465)  SMTP_SENDER_NAME (default Ourney)  SMTP_RATE_LIMIT (default 30, mails/hour)
#
# Secrets are only read from the environment and never printed.
set -euo pipefail

usage() {
  echo "Usage: $0 [--dry-run]" >&2
}

DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown argument: $arg" >&2
      usage
      exit 2
      ;;
  esac
done

# --- 1. Required environment ------------------------------------------------------------------
missing=()
for v in SUPABASE_ACCESS_TOKEN SUPABASE_PROJECT_REF SUPABASE_DB_PASSWORD; do
  if [ -z "${!v:-}" ]; then missing+=("$v"); fi
done
if [ "${#missing[@]}" -gt 0 ]; then
  echo "error: missing required environment variable(s): ${missing[*]}" >&2
  exit 1
fi

# --- 2. SMTP variables: all or nothing (validated up front, also in --dry-run) ------------------
smtp_set=()
smtp_unset=()
for v in SMTP_HOST SMTP_USER SMTP_PASS SMTP_SENDER_EMAIL; do
  if [ -n "${!v:-}" ]; then smtp_set+=("$v"); else smtp_unset+=("$v"); fi
done
APPLY_SMTP=0
if [ "${#smtp_set[@]}" -eq 4 ]; then
  APPLY_SMTP=1
elif [ "${#smtp_set[@]}" -gt 0 ]; then
  echo "error: partial SMTP configuration. Set all of SMTP_HOST SMTP_USER SMTP_PASS SMTP_SENDER_EMAIL" \
    "or none. Missing: ${smtp_unset[*]}" >&2
  exit 1
fi

SMTP_PORT="${SMTP_PORT:-465}"
SMTP_SENDER_NAME="${SMTP_SENDER_NAME:-Ourney}"
SMTP_RATE_LIMIT="${SMTP_RATE_LIMIT:-30}"
if [ "$APPLY_SMTP" -eq 1 ]; then
  case "$SMTP_PORT" in '' | *[!0-9]*)
    echo "error: SMTP_PORT must be a number" >&2
    exit 1
    ;;
  esac
  case "$SMTP_RATE_LIMIT" in '' | *[!0-9]*)
    echo "error: SMTP_RATE_LIMIT must be a number" >&2
    exit 1
    ;;
  esac
  case "$SUPABASE_ACCESS_TOKEN" in *[\"\\[:space:]]*)
    echo "error: SUPABASE_ACCESS_TOKEN contains characters that are not allowed in a token" >&2
    exit 1
    ;;
  esac
fi

# --- 3. Tools ---------------------------------------------------------------------------------
tools=(supabase)
if [ "$APPLY_SMTP" -eq 1 ]; then tools+=(jq curl); fi
for t in "${tools[@]}"; do
  if ! command -v "$t" > /dev/null 2>&1; then
    echo "error: required tool not found on PATH: $t" >&2
    exit 1
  fi
done

# The CLI reads these from the environment (it also picks SUPABASE_DB_PASSWORD up for `db push`).
export SUPABASE_ACCESS_TOKEN SUPABASE_DB_PASSWORD

# Run from the repo root so `supabase/` (config.toml, migrations, functions) is found.
cd "$(dirname "${BASH_SOURCE[0]}")/../.."

# --- 4. Link + migrations ---------------------------------------------------------------------
echo "==> Linking project $SUPABASE_PROJECT_REF"
supabase link --project-ref "$SUPABASE_PROJECT_REF" --password "$SUPABASE_DB_PASSWORD"

if [ "$DRY_RUN" -eq 1 ]; then
  echo "==> Dry run: migrations that would be applied"
  supabase db push --dry-run
  echo "Dry run finished. Nothing was changed on the project."
  exit 0
fi

echo "==> Applying migrations (db push)"
supabase db push --yes

# --- 5. Edge functions ------------------------------------------------------------------------
# delete-account: needs the caller's JWT (it authenticates the user itself and deletes THAT user),
#   so the gateway keeps verify_jwt on (default; config.toml also says verify_jwt = true).
# public-journey: read-only JSON for anonymous viewers of a shared link. The code expects NO
#   Authorization header (access is gated by the revocable journeys.public_token), so the gateway
#   must not demand a JWT: --no-verify-jwt (config.toml has verify_jwt = false as well).
echo "==> Deploying function delete-account"
supabase functions deploy delete-account --project-ref "$SUPABASE_PROJECT_REF"

echo "==> Deploying function public-journey (anonymous access)"
supabase functions deploy public-journey --project-ref "$SUPABASE_PROJECT_REF" --no-verify-jwt

# --- 6. Optional SMTP (H2) --------------------------------------------------------------------
if [ "$APPLY_SMTP" -eq 1 ]; then
  echo "==> Applying custom SMTP to Auth (host: $SMTP_HOST, port: $SMTP_PORT, sender: $SMTP_SENDER_EMAIL)"
  api="${SUPABASE_API_URL:-https://api.supabase.com}"
  # The body is built by jq (proper JSON escaping) and sent through stdin; the token goes through a
  # curl config read from a process substitution. Neither shows up in the process list or logs.
  # smtp_port is a string in the Management API; rate_limit_email_sent is an integer.
  if ! response="$(
    jq -n \
      --arg host "$SMTP_HOST" \
      --arg port "$SMTP_PORT" \
      --arg user "$SMTP_USER" \
      --arg pass "$SMTP_PASS" \
      --arg admin "$SMTP_SENDER_EMAIL" \
      --arg name "$SMTP_SENDER_NAME" \
      --argjson rate "$SMTP_RATE_LIMIT" \
      '{smtp_host: $host, smtp_port: $port, smtp_user: $user, smtp_pass: $pass,
        smtp_admin_email: $admin, smtp_sender_name: $name, rate_limit_email_sent: $rate}' |
      curl --silent --show-error --fail-with-body -X PATCH \
        --config <(printf 'header = "Authorization: Bearer %s"\n' "$SUPABASE_ACCESS_TOKEN") \
        -H 'Content-Type: application/json' \
        --data-binary @- \
        "$api/v1/projects/$SUPABASE_PROJECT_REF/config/auth"
  )"; then
    # Only the API's message is shown, never the whole body.
    msg="$(printf '%s' "$response" | jq -r '.message // empty' 2> /dev/null || true)"
    echo "error: SMTP update failed${msg:+: $msg}" >&2
    exit 1
  fi
  echo "SMTP applied."
else
  echo "==> SMTP_* not set: leaving Auth SMTP settings untouched"
fi

echo "Deploy finished."
