#!/usr/bin/env bash
# Offline tests for scripts/supabase, scripts/github and scripts/release (no bats needed).
# External commands (supabase, curl, gh) are replaced by stubs placed first on PATH, so nothing
# here talks to the network. Needs: bash, git, jq.   Run: bash scripts/tests/run.sh
#
# `check "name" $? ...` deliberately reads the status of the assertion on the line above.
# shellcheck disable=SC2319
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

PASS=0
FAILED=0

pass() {
  PASS=$((PASS + 1))
  echo "  ok   $1"
}
fail() {
  FAILED=$((FAILED + 1))
  echo "  FAIL $1" >&2
  if [ -n "${2:-}" ]; then printf '%s\n' "$2" | sed 's/^/       | /' >&2; fi
}
# check <name> <condition-exit-code> [detail]
check() {
  if [ "$2" -eq 0 ]; then pass "$1"; else fail "$1" "${3:-}"; fi
}
contains() { grep -qF -- "$2" <<< "$1"; }

# Stubs ------------------------------------------------------------------------------------------
BIN="$TMP/bin"
mkdir -p "$BIN"
LOG="$TMP/calls.log"
BODY="$TMP/curl-body.json"
CONFIG="$TMP/curl-config.txt"
REAL_JQ="$(command -v jq)"

# supabase stub: fails when its arguments contain STUB_SUPABASE_FAIL (e.g. "link", "db push").
cat > "$BIN/supabase" << 'EOF'
#!/usr/bin/env bash
echo "supabase $*" >> "$STUB_LOG"
if [ -n "${STUB_SUPABASE_FAIL:-}" ] && [[ "$*" == *"$STUB_SUPABASE_FAIL"* ]]; then
  echo "supabase stub: simulated failure" >&2
  exit 1
fi
EOF

# jq wrapper: logs argv (to prove no secret is passed as an argument), then runs the real jq.
cat > "$BIN/jq" << EOF
#!/usr/bin/env bash
echo "jq \$*" >> "\$STUB_LOG"
exec "$REAL_JQ" "\$@"
EOF

# curl stub: logs argv, saves the body (stdin) and the --config file (the Authorization header).
# Each call's body is also kept as $STUB_BODY.<n> (n = call number).
# STUB_CURL_FAIL=N simulates an API error whose body echoes a secret (curl exit 22) from the Nth
# curl call on (1 = the Auth config PATCH, 2 = the SMTP PATCH).
cat > "$BIN/curl" << 'EOF'
#!/usr/bin/env bash
echo "curl $*" >> "$STUB_LOG"
while [ "$#" -gt 0 ]; do
  if [ "$1" = "--config" ]; then cat "$2" > "$STUB_CONFIG"; fi
  shift
done
cat > "$STUB_BODY"
n="$(grep -c '^curl ' "$STUB_LOG")"
cp "$STUB_BODY" "$STUB_BODY.$n"
if [ -n "${STUB_CURL_FAIL:-}" ] && [ "$n" -ge "$STUB_CURL_FAIL" ]; then
  echo '{"message":"x","smtp_pass":"leak"}'
  exit 22
fi
echo '{}'
EOF

# gh stub: permissions come from STUB_PERMS ("user=perm ..."), a missing user is "not a collaborator".
cat > "$BIN/gh" << 'EOF'
#!/usr/bin/env bash
echo "gh $*" >> "$STUB_LOG"
args="$*"
case "$args" in
  "api user"*)
    if [ -n "${STUB_GH_UNAUTH:-}" ]; then echo "gh: not logged in" >&2; exit 1; fi
    echo "tester"
    exit 0
    ;;
  *"-X PUT"*) exit 0 ;;
  *"/permission"*)
    user="${args#*collaborators/}"
    user="${user%%/*}"
    for kv in ${STUB_PERMS:-}; do
      if [ "${kv%%=*}" != "$user" ]; then continue; fi
      if [ "${kv#*=}" = "ERROR" ]; then echo "gh: Server Error (HTTP 500)" >&2; exit 1; fi
      echo "${kv#*=}"
      exit 0
    done
    echo "gh: Not Found (HTTP 404)" >&2
    exit 1
    ;;
  *"repos/"*"/invitations"*)
    if [[ "$args" == *'.permissions'* ]]; then
      [ -n "${STUB_PENDING:-}" ] && echo "  @${STUB_PENDING} (write)"
    else
      [ -n "${STUB_PENDING:-}" ] && echo "${STUB_PENDING}"
    fi
    exit 0
    ;;
  "run list"*) printf '%s\n' "${STUB_CI_JSON:-[]}"; exit 0 ;;
esac
exit 0
EOF
chmod +x "$BIN"/*

export STUB_LOG="$LOG" STUB_BODY="$BODY" STUB_CONFIG="$CONFIG"
export PATH="$BIN:$PATH"

# run <cmd...>: sets OUT (stdout+stderr) and RC. Environment is whatever the caller exported.
run() {
  : > "$LOG"
  rm -f "$BODY".*
  OUT="$("$@" 2>&1)"
  RC=$?
}

DEPLOY="$ROOT/scripts/supabase/deploy-hosted.sh"
INVITE="$ROOT/scripts/github/invite-members.sh"
PREFLIGHT="$ROOT/scripts/release/preflight.sh"

clean_env() {
  unset SUPABASE_ACCESS_TOKEN SUPABASE_PROJECT_REF SUPABASE_DB_PASSWORD \
    SMTP_HOST SMTP_USER SMTP_PASS SMTP_SENDER_EMAIL SMTP_PORT SMTP_SENDER_NAME SMTP_RATE_LIMIT \
    SUPABASE_API_URL AUTH_SITE_URL STUB_PERMS STUB_PENDING STUB_CI_JSON STUB_SUPABASE_FAIL STUB_CURL_FAIL \
    STUB_GH_UNAUTH
}
set_base_env() {
  export SUPABASE_ACCESS_TOKEN="sbp_test_token_0000" SUPABASE_PROJECT_REF="abcdefghijklmnopqrst"
  export SUPABASE_DB_PASSWORD="db-pass-for-tests"
}

# deploy-hosted.sh ------------------------------------------------------------------------------
echo "deploy-hosted.sh"

clean_env
run bash "$DEPLOY"
[ "$RC" -ne 0 ]
check "missing env fails" $? "rc=$RC"
contains "$OUT" "SUPABASE_ACCESS_TOKEN SUPABASE_PROJECT_REF SUPABASE_DB_PASSWORD"
check "missing env lists all three names" $? "$OUT"
[ ! -s "$LOG" ]
check "missing env runs no external command" $? "$(cat "$LOG")"

for bad in $'sbp_tok\n' 'sbp_"tok' 'sbp tok' 'sbp_\tok' $'sbp_\ttok'; do
  clean_env
  set_base_env
  export SUPABASE_ACCESS_TOKEN="$bad"
  run bash "$DEPLOY"
  [ "$RC" -ne 0 ] && contains "$OUT" "SUPABASE_ACCESS_TOKEN contains whitespace, a quote or a backslash" && [ ! -s "$LOG" ]
  check "bad token is rejected before any supabase call: $(printf '%q' "$bad")" $? "rc=$RC out=$OUT log=$(cat "$LOG")"
done
# Also rejected in --dry-run (no SMTP configured): the check is not tied to SMTP.
run bash "$DEPLOY" --dry-run
[ "$RC" -ne 0 ] && [ ! -s "$LOG" ]
check "bad token is rejected in --dry-run too" $? "rc=$RC out=$OUT"

clean_env
set_base_env
STUB_SUPABASE_FAIL="link" run bash "$DEPLOY"
[ "$RC" -ne 0 ] && ! contains "$(cat "$LOG")" "db push" && ! contains "$(cat "$LOG")" "functions deploy"
check "failing 'supabase link' stops before db push and functions" $? "rc=$RC log=$(cat "$LOG")"
STUB_SUPABASE_FAIL="db push" run bash "$DEPLOY"
[ "$RC" -ne 0 ] && contains "$(cat "$LOG")" "db push" && ! contains "$(cat "$LOG")" "functions deploy"
check "failing 'db push' stops before functions deploy" $? "rc=$RC log=$(cat "$LOG")"
STUB_SUPABASE_FAIL="functions deploy delete-account" run bash "$DEPLOY"
[ "$RC" -ne 0 ] && ! contains "$(cat "$LOG")" "public-journey"
check "failing function deploy stops the script" $? "rc=$RC log=$(cat "$LOG")"

clean_env
export SUPABASE_ACCESS_TOKEN="x"
run bash "$DEPLOY"
contains "$OUT" "SUPABASE_PROJECT_REF SUPABASE_DB_PASSWORD" && ! contains "$OUT" "missing required environment variable(s): SUPABASE_ACCESS_TOKEN"
check "only the missing names are listed" $? "$OUT"

clean_env
run bash "$DEPLOY" --bogus
[ "$RC" -eq 2 ]
check "unknown argument exits 2" $? "rc=$RC $OUT"

clean_env
set_base_env
export SMTP_HOST="smtp.example.com" SMTP_USER="resend"
run bash "$DEPLOY"
[ "$RC" -ne 0 ] && contains "$OUT" "partial SMTP" && contains "$OUT" "SMTP_PASS SMTP_SENDER_EMAIL"
check "partial SMTP vars fail and name the missing ones" $? "rc=$RC $OUT"
[ ! -s "$LOG" ]
check "partial SMTP fails before any external command" $? "$(cat "$LOG")"
run bash "$DEPLOY" --dry-run
[ "$RC" -ne 0 ] && contains "$OUT" "partial SMTP"
check "partial SMTP fails in --dry-run too" $? "rc=$RC $OUT"

clean_env
set_base_env
run bash "$DEPLOY" --dry-run
calls="$(cat "$LOG")"
[ "$RC" -eq 0 ] && contains "$calls" "supabase link --project-ref abcdefghijklmnopqrst" &&
  contains "$calls" "supabase db push --dry-run" &&
  ! contains "$calls" "functions deploy" && ! contains "$calls" "curl"
check "--dry-run only links and runs db push --dry-run" $? "rc=$RC calls=$calls out=$OUT"
[ "$(grep -c '^curl ' "$LOG")" -eq 0 ] && ! ls "$BODY".* > /dev/null 2>&1
check "--dry-run makes zero curl calls" $? "$calls"
! contains "$OUT" "db-pass-for-tests" && ! contains "$OUT" "sbp_test_token_0000"
check "--dry-run output has no secrets" $? "$OUT"

clean_env
set_base_env
run bash "$DEPLOY"
calls="$(cat "$LOG")"
[ "$RC" -eq 0 ] && contains "$calls" "supabase db push --yes" &&
  contains "$calls" "supabase functions deploy delete-account --project-ref abcdefghijklmnopqrst" &&
  contains "$calls" "supabase functions deploy public-journey --project-ref abcdefghijklmnopqrst --no-verify-jwt" &&
  [ "$(grep -c '^curl ' "$LOG")" -eq 1 ] && contains "$calls" "-X PATCH" &&
  contains "$calls" "/v1/projects/abcdefghijklmnopqrst/config/auth"
check "deploy without SMTP: db push + both functions + exactly one Auth config PATCH" $? "rc=$RC calls=$calls out=$OUT"
contains "$OUT" "==> Applying Auth config (OTP code emails, site_url https://hofang42.github.io/Ourney/)" &&
  contains "$OUT" "==> SMTP_* not set: leaving Auth SMTP settings untouched"
check "deploy without SMTP: prints the Auth config and untouched-SMTP lines" $? "$OUT"
jq -e '.mailer_otp_length == 6 and .mailer_otp_exp == 3600 and .mailer_autoconfirm == true
  and .site_url == "https://hofang42.github.io/Ourney/"' "$BODY" > /dev/null
check "Auth config body: 6-digit/3600 s OTP, autoconfirm true, default site_url" $? "$(cat "$BODY" 2> /dev/null | head -c 300)"
jq -e 'has("uri_allow_list") | not' "$BODY" > /dev/null
check "Auth config body: default has no uri_allow_list (dashboard entries are not overwritten)" $? "$(jq -c keys "$BODY" 2> /dev/null)"
jq -e 'keys | map(select(startswith("smtp_") or . == "rate_limit_email_sent")) | length == 0' "$BODY" > /dev/null
check "Auth config body (no SMTP) has no smtp_* fields" $? "$(jq -c keys "$BODY" 2> /dev/null)"
jq -e --rawfile m "$ROOT/supabase/templates/magic_link.html" --rawfile c "$ROOT/supabase/templates/confirmation.html" \
  '.mailer_templates_magic_link_content == $m and .mailer_templates_confirmation_content == $c
   and (.mailer_templates_magic_link_content | contains("{{ .Token }}"))
   and (.mailer_templates_confirmation_content | contains("{{ .Token }}"))
   and ((.mailer_templates_magic_link_content + .mailer_templates_confirmation_content) | contains("ConfirmationURL") | not)' \
  "$BODY" > /dev/null
check "Auth config body: both templates carry {{ .Token }} and no ConfirmationURL" $? "template mismatch"
jq -e '.mailer_subjects_magic_link == "Mã đăng nhập Ourney / Your Ourney sign-in code"
  and .mailer_subjects_confirmation == "Mã xác nhận Ourney / Your Ourney confirmation code"' "$BODY" > /dev/null
check "Auth config body: subjects come from config.toml" $? "$(jq -c '[.mailer_subjects_magic_link,.mailer_subjects_confirmation]' "$BODY" 2> /dev/null)"
AUTH_SITE_URL="https://example.org/app/" run bash "$DEPLOY"
jq -e '.site_url == "https://example.org/app/" and (has("uri_allow_list") | not)' "$BODY" > /dev/null
check "AUTH_SITE_URL overrides site_url only" $? "rc=$RC $(jq -c '[.site_url,.uri_allow_list]' "$BODY" 2> /dev/null)"
AUTH_URI_ALLOW_LIST="https://example.org/app/,ourney://auth-callback" run bash "$DEPLOY"
jq -e '.uri_allow_list == "https://example.org/app/,ourney://auth-callback"' "$BODY" > /dev/null
check "AUTH_URI_ALLOW_LIST is sent as uri_allow_list when set" $? "rc=$RC $(jq -c '.uri_allow_list' "$BODY" 2> /dev/null)"
for bad in "http://example.org/" "https://exa mple.org/" "https://a.org/,https://b.org/" "ftp" ""; do
  [ -n "$bad" ] || continue
  AUTH_SITE_URL="$bad" run bash "$DEPLOY" --dry-run
  [ "$RC" -ne 0 ] && contains "$OUT" "AUTH_SITE_URL must start with https://" && [ ! -s "$LOG" ]
  check "bad AUTH_SITE_URL rejected before any call (also --dry-run): $bad" $? "rc=$RC $OUT log=$(cat "$LOG")"
done
for bad in "http://example.org/" "https://a.org/,,https://b.org/" "https://a.org/, https://b.org/" "https://a.org/," "noscheme"; do
  AUTH_URI_ALLOW_LIST="$bad" run bash "$DEPLOY" --dry-run
  [ "$RC" -ne 0 ] && contains "$OUT" "AUTH_URI_ALLOW_LIST" && [ ! -s "$LOG" ]
  check "bad AUTH_URI_ALLOW_LIST rejected before any call: $bad" $? "rc=$RC $OUT log=$(cat "$LOG")"
done
# Template / subject problems abort before ANY supabase call: run a copy of the repo bits.
COPY="$TMP/repo-copy"
mkdir -p "$COPY/scripts/supabase" "$COPY/supabase/templates"
cp "$DEPLOY" "$COPY/scripts/supabase/"
cp "$ROOT/supabase/config.toml" "$COPY/supabase/"
cp "$ROOT/supabase/templates/"*.html "$COPY/supabase/templates/"
rm "$COPY/supabase/templates/confirmation.html"
run bash "$COPY/scripts/supabase/deploy-hosted.sh"
[ "$RC" -ne 0 ] && contains "$OUT" "missing or empty email template" && [ ! -s "$LOG" ]
check "missing template file fails before any supabase call" $? "rc=$RC $OUT log=$(cat "$LOG")"
cp "$ROOT/supabase/templates/confirmation.html" "$COPY/supabase/templates/"
sed -i 's|^subject = "Mã xác nhận.*|subject = "bad # subject"|' "$COPY/supabase/config.toml"
run bash "$COPY/scripts/supabase/deploy-hosted.sh"
[ "$RC" -ne 0 ] && contains "$OUT" "bad or missing email template subject" && [ ! -s "$LOG" ]
check "malformed subject fails before any supabase call" $? "rc=$RC $OUT log=$(cat "$LOG")"
STUB_CURL_FAIL=1 run bash "$DEPLOY"
[ "$RC" -ne 0 ] && contains "$OUT" "Auth config update failed: x" && ! contains "$OUT" "leak" && ! contains "$OUT" "smtp_pass"
check "Auth config: API failure shows the message only, never the body" $? "rc=$RC $OUT"
run bash "$DEPLOY"
calls="$(cat "$LOG")"
line="$(grep -F "supabase functions deploy delete-account" "$LOG")"
[ -n "$line" ] && ! contains "$line" "--no-verify-jwt"
check "delete-account keeps JWT verification" $? "$line"
line="$(grep -F "supabase functions deploy public-journey" "$LOG")"
contains "$line" "--no-verify-jwt"
check "public-journey is deployed without JWT verification" $? "$line"
! contains "$calls" "db-pass-for-tests" && ! contains "$calls" "sbp_test_token_0000"
check "no secret appears in any supabase argv (link/db push/functions)" $? "$calls"

clean_env
set_base_env
# shellcheck disable=SC2016  # the literal $ in the password is intentional
export SMTP_HOST="smtp.example.com" SMTP_USER="resend" SMTP_PASS='p@ss"word\with$pecial' SMTP_SENDER_EMAIL="no-reply@example.com"
rm -f "$BODY"
run bash "$DEPLOY"
calls="$(cat "$LOG")"
[ "$RC" -eq 0 ] && contains "$calls" "-X PATCH" && contains "$calls" "/v1/projects/abcdefghijklmnopqrst/config/auth"
check "SMTP: PATCHes the project auth config" $? "rc=$RC calls=$calls out=$OUT"
jq -e '.smtp_host == "smtp.example.com" and .smtp_port == "465" and .smtp_user == "resend"
  and .smtp_pass == "p@ss\"word\\with$pecial" and .smtp_admin_email == "no-reply@example.com"
  and .smtp_sender_name == "Ourney" and .rate_limit_email_sent == 30' "$BODY" > /dev/null
check "SMTP: JSON body has fields and defaults (465, Ourney, 30)" $? "$(cat "$BODY" 2> /dev/null)"
! contains "$OUT$calls" 'word\with' && ! contains "$OUT$calls" "p@ss" &&
  ! contains "$OUT$calls" "sbp_test_token_0000" && ! contains "$OUT$calls" "db-pass-for-tests"
check "SMTP: no secret in output or in the argv of supabase, jq and curl" $? "$OUT $calls"
contains "$calls" "jq -n" && contains "$calls" "curl --silent"
check "SMTP: the jq and curl calls were really logged (the check above is meaningful)" $? "$calls"
grep -qxF 'header = "Authorization: Bearer sbp_test_token_0000"' "$CONFIG"
check "SMTP: Authorization Bearer header is sent via the curl config" $? "$(sed 's/Bearer .*/Bearer <redacted>/' "$CONFIG" 2> /dev/null)"

export SMTP_RATE_LIMIT=030 SMTP_PORT=465 SMTP_SENDER_NAME=Ourney
run bash "$DEPLOY"
jq -e '.rate_limit_email_sent == 30' "$BODY" > /dev/null
check "SMTP: leading zeros in SMTP_RATE_LIMIT are normalised" $? "rc=$RC $(cat "$BODY" 2> /dev/null)"
unset SMTP_RATE_LIMIT SMTP_PORT SMTP_SENDER_NAME

jq -e '.mailer_otp_length == 6 and .mailer_autoconfirm == true and (has("smtp_host") | not)' "$BODY.1" > /dev/null &&
  jq -e '.smtp_host == "smtp.example.com" and (has("mailer_otp_length") | not)' "$BODY.2" > /dev/null
check "SMTP: two PATCHes, Auth config first (no smtp_*) then SMTP" $? "$(ls "$BODY".* 2> /dev/null)"
auth_line="$(grep -n 'Applying Auth config' <<< "$OUT" | cut -d: -f1)"
smtp_line="$(grep -n 'Applying custom SMTP' <<< "$OUT" | cut -d: -f1)"
[ -n "$auth_line" ] && [ -n "$smtp_line" ] && [ "$auth_line" -lt "$smtp_line" ]
check "SMTP: Auth config step is announced before the SMTP step" $? "$OUT"

STUB_CURL_FAIL=2 run bash "$DEPLOY"
[ "$RC" -ne 0 ] && contains "$OUT" "SMTP update failed: x" && ! contains "$OUT" "leak"
check "SMTP: API failure shows the message only, never the body" $? "rc=$RC $OUT"

SUPABASE_API_URL="http://evil.example.com" run bash "$DEPLOY"
[ "$RC" -ne 0 ] && contains "$OUT" "SUPABASE_API_URL must start with https://" && [ ! -s "$LOG" ]
check "SMTP: plain-http remote API URL is rejected before any call" $? "rc=$RC $OUT"
SUPABASE_API_URL="http://localhost.evil.com" run bash "$DEPLOY"
[ "$RC" -ne 0 ] && contains "$OUT" "SUPABASE_API_URL must start with https://"
check "SMTP: http://localhost.evil.com is rejected" $? "rc=$RC $OUT"
SUPABASE_API_URL="http://127.0.0.1:54321" run bash "$DEPLOY"
[ "$RC" -eq 0 ] && contains "$(cat "$LOG")" "http://127.0.0.1:54321/v1/projects/"
check "SMTP: loopback http API URL is allowed" $? "rc=$RC $OUT"

export SMTP_PORT=587 SMTP_SENDER_NAME="Ourney Team" SMTP_RATE_LIMIT=60
run bash "$DEPLOY"
jq -e '.smtp_port == "587" and .smtp_sender_name == "Ourney Team" and .rate_limit_email_sent == 60' "$BODY" > /dev/null
check "SMTP: overrides for port, sender name and rate limit" $? "$(cat "$BODY" 2> /dev/null)"

export SMTP_PORT="46x5"
run bash "$DEPLOY"
[ "$RC" -ne 0 ] && contains "$OUT" "SMTP_PORT must be a number"
check "SMTP: non-numeric port is rejected" $? "rc=$RC $OUT"

clean_env
set_base_env
SUPABASE_API_URL="http://evil.example.com" run bash "$DEPLOY"
[ "$RC" -ne 0 ] && contains "$OUT" "SUPABASE_API_URL must start with https://" && [ ! -s "$LOG" ]
check "Auth config: plain-http remote API URL is rejected even without SMTP" $? "rc=$RC $OUT"

# Email OTP templates (static) ---------------------------------------------------------------------
for t in magic_link confirmation; do
  f="$ROOT/supabase/templates/$t.html"
  grep -qF '{{ .Token }}' "$f" && ! grep -qiE 'ConfirmationURL|href|\{\{ *\.(SiteURL|TokenHash|RedirectTo)' "$f"
  check "template $t.html shows {{ .Token }} and has no link" $? "$f"
  grep -qF '60 phút' "$f" && grep -qF '60 minutes' "$f"
  check "template $t.html is bilingual and states the 60 minute validity" $? "$f"
  grep -qF "content_path = \"./supabase/templates/$t.html\"" "$ROOT/supabase/config.toml"
  check "config.toml wires template $t" $? ""
done

# invite-members.sh -------------------------------------------------------------------------------
echo "invite-members.sh"

clean_env
export STUB_PERMS="lken1514=write"
run bash "$INVITE"
calls="$(cat "$LOG")"
[ "$RC" -eq 0 ] && contains "$OUT" "DRY RUN" &&
  contains "$OUT" "would  invite @thydynh03 with permission=push" &&
  contains "$OUT" "would  invite @nguyenductien-qnm with permission=push" &&
  contains "$OUT" "skip   @lken1514: already a collaborator with 'write'"
check "dry run prints the plan and skips existing collaborators" $? "rc=$RC out=$OUT"
! contains "$calls" "PUT"
check "dry run makes no PUT call" $? "$calls"
contains "$OUT" "Pending invitations"
check "dry run lists pending invitations" $? "$OUT"

run bash "$INVITE" --apply
calls="$(cat "$LOG")"
[ "$RC" -eq 0 ] && contains "$calls" "-X PUT repos/hofang42/Ourney/collaborators/thydynh03 -f permission=push" &&
  contains "$calls" "-X PUT repos/hofang42/Ourney/collaborators/nguyenductien-qnm -f permission=push" &&
  ! contains "$calls" "-X PUT repos/hofang42/Ourney/collaborators/lken1514"
check "--apply PUTs push for the missing users only" $? "rc=$RC calls=$calls"

export STUB_PERMS="thydynh03=admin" STUB_PENDING="nguyenductien-qnm"
REPO="someone/else" run bash "$INVITE" --apply
calls="$(cat "$LOG")"
contains "$OUT" "skip   @nguyenductien-qnm: invitation already pending" &&
  contains "$calls" "-X PUT repos/someone/else/collaborators/lken1514" &&
  ! contains "$calls" "-X PUT repos/someone/else/collaborators/nguyenductien-qnm" &&
  ! contains "$calls" "-X PUT repos/someone/else/collaborators/thydynh03"
check "REPO override; admins and pending invitees are skipped" $? "rc=$RC calls=$calls out=$OUT"

clean_env
STUB_GH_UNAUTH=1 run bash "$INVITE" --apply
[ "$RC" -ne 0 ] && contains "$OUT" "gh is not authenticated" && ! contains "$(cat "$LOG")" "PUT"
check "unauthenticated gh fails clearly and changes nothing" $? "rc=$RC out=$OUT"

STUB_PERMS="thydynh03=ERROR" run bash "$INVITE" --apply
[ "$RC" -ne 0 ] && contains "$OUT" "could not read the permission of @thydynh03" && ! contains "$(cat "$LOG")" "PUT"
check "a non-404 API error is fatal (not treated as 'not a collaborator')" $? "rc=$RC out=$OUT"

run bash "$INVITE" --nope
[ "$RC" -eq 2 ]
check "unknown argument exits 2" $? "rc=$RC"

# preflight.sh ------------------------------------------------------------------------------------
echo "preflight.sh"

clean_env
run bash "$PREFLIGHT" 1.2.3
[ "$RC" -eq 2 ] && contains "$OUT" "must look like vX.Y.Z"
check "rejects tag without the v prefix" $? "rc=$RC $OUT"
run bash "$PREFLIGHT" v1.2
[ "$RC" -eq 2 ] && contains "$OUT" "must look like vX.Y.Z"
check "rejects tag with two components" $? "rc=$RC $OUT"
run bash "$PREFLIGHT" v1.2.3-rc1
[ "$RC" -eq 2 ]
check "rejects pre-release suffix" $? "rc=$RC $OUT"
run bash "$PREFLIGHT"
[ "$RC" -eq 2 ]
check "requires exactly one argument" $? "rc=$RC $OUT"

# A throwaway repo with a local bare "origin" so git checks run offline.
ORIGIN="$TMP/origin.git"
WORK="$TMP/work"
git init -q --bare -b main "$ORIGIN"
git init -q -b main "$WORK"
git -C "$WORK" config user.email "test@example.com"
git -C "$WORK" config user.name "Test"
git -C "$WORK" config commit.gpgsign false
mkdir -p "$WORK/apps/mobile"
printf 'name: ourney\nversion: 0.1.0+3\n' > "$WORK/apps/mobile/pubspec.yaml"
git -C "$WORK" add -A
git -C "$WORK" commit -q -m "init"
git -C "$WORK" remote add origin "$ORIGIN"
git -C "$WORK" push -q origin main
HEAD_SHA="$(git -C "$WORK" rev-parse HEAD)"

in_work() { (cd "$WORK" && "$@"); }
export STUB_CI_JSON="[{\"conclusion\":\"success\",\"headSha\":\"$HEAD_SHA\"}]"

run in_work bash "$PREFLIGHT" v0.1.0
[ "$RC" -eq 0 ] && contains "$OUT" "Preflight passed" && contains "$OUT" "git tag -a v0.1.0" && contains "$OUT" "git push origin v0.1.0"
check "all checks pass and the commands are printed" $? "rc=$RC out=$OUT"
[ -z "$(git -C "$WORK" tag)" ] && [ -z "$(git -C "$ORIGIN" tag)" ]
check "preflight never creates a tag" $?
contains "$(cat "$LOG")" "gh run list --branch main --workflow CI --limit 1 --json"
check "CI status is read with gh run list" $?

run in_work bash "$PREFLIGHT" v0.2.0
[ "$RC" -eq 1 ] && contains "$OUT" "pubspec version name is '0.1.0', expected '0.2.0'"
check "fails when pubspec version differs from the tag" $? "rc=$RC out=$OUT"

touch "$WORK/untracked.txt"
run in_work bash "$PREFLIGHT" v0.1.0
[ "$RC" -eq 1 ] && contains "$OUT" "working tree is not clean"
check "fails on a dirty working tree" $? "rc=$RC out=$OUT"
rm -f "$WORK/untracked.txt"

STUB_CI_JSON='[{"conclusion":"failure","headSha":"'"$HEAD_SHA"'"}]' run in_work bash "$PREFLIGHT" v0.1.0
[ "$RC" -eq 1 ] && contains "$OUT" "concluded 'failure'"
check "fails when the latest CI run failed" $? "rc=$RC out=$OUT"

STUB_CI_JSON='[{"conclusion":"success","headSha":"0000000000000000000000000000000000000000"}]' run in_work bash "$PREFLIGHT" v0.1.0
[ "$RC" -eq 1 ] && contains "$OUT" "not for HEAD"
check "fails when the green CI run is for another commit" $? "rc=$RC out=$OUT"

STUB_CI_JSON='[]' run in_work bash "$PREFLIGHT" v0.1.0
[ "$RC" -eq 1 ] && contains "$OUT" "no finished CI run"
check "fails when there is no CI run" $? "rc=$RC out=$OUT"

git -C "$WORK" tag v0.1.0
run in_work bash "$PREFLIGHT" v0.1.0
[ "$RC" -eq 1 ] && contains "$OUT" "tag v0.1.0 already exists locally"
check "fails when the tag already exists" $? "rc=$RC out=$OUT"
git -C "$WORK" tag -d v0.1.0 > /dev/null

git -C "$WORK" checkout -q -b feature
run in_work bash "$PREFLIGHT" v0.1.0
[ "$RC" -eq 1 ] && contains "$OUT" "on branch 'feature'"
check "fails when not on main" $? "rc=$RC out=$OUT"
git -C "$WORK" checkout -q main

git -C "$WORK" commit -q --allow-empty -m "local only"
run in_work bash "$PREFLIGHT" v0.1.0
[ "$RC" -eq 1 ] && contains "$OUT" "differs from origin/main"
check "fails when main is ahead of origin" $? "rc=$RC out=$OUT"

echo
echo "passed: $PASS, failed: $FAILED"
[ "$FAILED" -eq 0 ]
