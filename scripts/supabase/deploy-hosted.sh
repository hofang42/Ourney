#!/usr/bin/env bash
# Deploys the Ourney backend to a HOSTED Supabase project (docs/runbooks/hosted-supabase.md).
#
#   SUPABASE_ACCESS_TOKEN=... SUPABASE_PROJECT_REF=... SUPABASE_DB_PASSWORD=... \
#     bash scripts/supabase/deploy-hosted.sh [--dry-run]
#
# Steps: link -> db push (supabase/migrations) -> functions deploy -> Auth config -> optional SMTP (H2).
# --dry-run only links and runs `supabase db push --dry-run`; nothing is changed on the project.
# Idempotent: db push applies only new migrations, functions deploy overwrites, the Auth config and
# SMTP PATCHes set the same values again.
#
# Auth config (always, on every real deploy): the app signs in with a 6-digit email OTP, so the
# hosted project must send CODE emails (supabase/templates/*.html, subjects from config.toml) and
# use a real site_url instead of the default http://localhost:3000. Also sets the OTP length (6),
# expiry (3600 s) and mailer_autoconfirm (same as local enable_confirmations = false).
#   AUTH_SITE_URL (default https://hofang42.github.io/Ourney/)  used for site_url and uri_allow_list
#
# Optional SMTP (all four required together, otherwise the script fails before doing anything):
#   SMTP_HOST SMTP_USER SMTP_PASS SMTP_SENDER_EMAIL
#   SMTP_PORT (default 465)  SMTP_SENDER_NAME (default Ourney)  SMTP_RATE_LIMIT (default 30, mails/hour)
#
# Secrets are only read from the environment: never printed and never passed as command-line
# arguments (supabase CLI and jq read them from env; curl gets them via stdin / a config fd).
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
AUTH_SITE_URL="${AUTH_SITE_URL:-https://hofang42.github.io/Ourney/}"

# The token must be a single clean word (it is also written into a curl config file below).
# Checked before ANY supabase call so a bad secret fails early.
bad_token_re='[[:space:]"\\]'
if [[ "$SUPABASE_ACCESS_TOKEN" =~ $bad_token_re ]]; then
  echo "error: SUPABASE_ACCESS_TOKEN contains whitespace, a quote or a backslash (bad secret value?)" >&2
  exit 1
fi

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
  # Normalise (e.g. 030 -> 30) so jq's tonumber never sees leading zeros.
  SMTP_RATE_LIMIT=$((10#$SMTP_RATE_LIMIT))
fi

# The API base URL can be overridden for tests, but only to https or a loopback http server,
# so the access token can never be sent in clear text to a remote host.
SUPABASE_API_URL="${SUPABASE_API_URL:-https://api.supabase.com}"
api_re='^(https://[^/]|http://(127\.0\.0\.1|localhost)(:[0-9]+)?(/|$))'
if ! [[ "$SUPABASE_API_URL" =~ $api_re ]]; then
  echo "error: SUPABASE_API_URL must start with https:// (or http://127.0.0.1 / http://localhost)" >&2
  exit 1
fi

# --- 3. Tools ---------------------------------------------------------------------------------
tools=(supabase)
if [ "$DRY_RUN" -eq 0 ]; then tools+=(jq curl); fi
for t in "${tools[@]}"; do
  if ! command -v "$t" > /dev/null 2>&1; then
    echo "error: required tool not found on PATH: $t" >&2
    exit 1
  fi
done

# The CLI reads both from the environment (link and db push use SUPABASE_DB_PASSWORD as the
# database password), so no secret is ever passed on a command line.
export SUPABASE_ACCESS_TOKEN SUPABASE_DB_PASSWORD

# Run from the repo root so `supabase/` (config.toml, migrations, functions) is found.
cd "$(dirname "${BASH_SOURCE[0]}")/../.."

# Subject of an auth email template, read from supabase/config.toml (single source of truth).
toml_subject() {
  awk -v sect="[auth.email.template.$1]" '
    /^\[/ { in_sect = ($0 == sect); next }
    in_sect && /^subject[[:space:]]*=/ { sub(/^subject[[:space:]]*=[[:space:]]*"/, ""); sub(/"[[:space:]]*$/, ""); print; exit }
  ' supabase/config.toml
}

# PATCH the project's Auth config; the JSON body comes from stdin. The token goes to curl through a
# config read from a process substitution, so it is not in curl's argv either. Only the API's
# `.message` is shown on failure, never the whole body.
patch_auth_config() {
  local what="$1" response msg
  if ! response="$(
    curl --silent --show-error --fail-with-body -X PATCH \
      --config <(printf 'header = "Authorization: Bearer %s"\n' "$SUPABASE_ACCESS_TOKEN") \
      -H 'Content-Type: application/json' \
      --data-binary @- \
      "$SUPABASE_API_URL/v1/projects/$SUPABASE_PROJECT_REF/config/auth"
  )"; then
    msg="$(printf '%s' "$response" | jq -r '.message // empty' 2> /dev/null || true)"
    echo "error: $what update failed${msg:+: $msg}" >&2
    exit 1
  fi
}

# --- 4. Link + migrations ---------------------------------------------------------------------
echo "==> Linking project $SUPABASE_PROJECT_REF"
supabase link --project-ref "$SUPABASE_PROJECT_REF"

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

# --- 6. Auth config: OTP code emails (always) --------------------------------------------------
# Default hosted templates send a magic LINK built from the default Site URL (http://localhost:3000);
# the app expects a 6-digit code. Templates are plain files in the repo (not secrets).
magic_subject="$(toml_subject magic_link)"
confirm_subject="$(toml_subject confirmation)"
for f in supabase/templates/magic_link.html supabase/templates/confirmation.html; do
  if [ ! -s "$f" ]; then
    echo "error: missing email template: $f" >&2
    exit 1
  fi
done
if [ -z "$magic_subject" ] || [ -z "$confirm_subject" ]; then
  echo "error: could not read the email template subjects from supabase/config.toml" >&2
  exit 1
fi
echo "==> Applying Auth config (OTP code emails, site_url $AUTH_SITE_URL)"
export AUTH_SITE_URL
jq -n \
  --arg magic_subject "$magic_subject" --arg confirm_subject "$confirm_subject" \
  --rawfile magic_html supabase/templates/magic_link.html \
  --rawfile confirm_html supabase/templates/confirmation.html \
  '{site_url: $ENV.AUTH_SITE_URL, uri_allow_list: $ENV.AUTH_SITE_URL,
    mailer_otp_length: 6, mailer_otp_exp: 3600, mailer_autoconfirm: true,
    mailer_subjects_magic_link: $magic_subject,
    mailer_templates_magic_link_content: $magic_html,
    mailer_subjects_confirmation: $confirm_subject,
    mailer_templates_confirmation_content: $confirm_html}' |
  patch_auth_config "Auth config"
echo "Auth config applied."

# --- 7. Optional SMTP (H2) --------------------------------------------------------------------
if [ "$APPLY_SMTP" -eq 1 ]; then
  # shellcheck disable=SC2153  # SMTP_HOST is set: APPLY_SMTP=1 only when all four SMTP_* are non-empty
  echo "==> Applying custom SMTP to Auth (host: $SMTP_HOST, port: $SMTP_PORT, sender: $SMTP_SENDER_EMAIL)"
  # Values reach jq through the environment ($ENV), never as arguments, so no secret appears in a
  # command line. smtp_port is a string in the Management API; rate_limit_email_sent is an integer.
  export SMTP_HOST SMTP_PORT SMTP_USER SMTP_PASS SMTP_SENDER_EMAIL SMTP_SENDER_NAME SMTP_RATE_LIMIT
  jq -n \
    '{smtp_host: $ENV.SMTP_HOST, smtp_port: $ENV.SMTP_PORT, smtp_user: $ENV.SMTP_USER,
      smtp_pass: $ENV.SMTP_PASS, smtp_admin_email: $ENV.SMTP_SENDER_EMAIL,
      smtp_sender_name: $ENV.SMTP_SENDER_NAME,
      rate_limit_email_sent: ($ENV.SMTP_RATE_LIMIT | tonumber)}' |
    patch_auth_config "SMTP"
  echo "SMTP applied."
else
  echo "==> SMTP_* not set: leaving Auth SMTP settings untouched"
fi

echo "Deploy finished."
