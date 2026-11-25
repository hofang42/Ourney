#!/usr/bin/env bash
# Publish the Android update policy after the public APK has been mirrored.
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 vX.Y.Z" >&2
  exit 2
fi

service_key="${SUPABASE_SERVICE_ROLE_KEY:-}"
if [ -z "${service_key//[[:space:]]/}" ]; then
  echo "::warning::SUPABASE_SERVICE_ROLE_KEY not set; skipping Android update policy publication."
  exit 0
fi

supabase_url="${SUPABASE_URL:-}"
supabase_url="${supabase_url%/}"
url_re='^https://[a-zA-Z0-9.-]+(:[0-9]+)?$'
if ! [[ "$supabase_url" =~ $url_re ]]; then
  echo "::error::SUPABASE_URL must be an HTTPS origin."
  exit 1
fi
key_re='^[a-zA-Z0-9._-]+$'
if ! [[ "$service_key" =~ $key_re ]]; then
  echo "::error::SUPABASE_SERVICE_ROLE_KEY has an invalid format."
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir/../.."
payload="$(node "$script_dir/metadata.mjs" request "$1")"
download_url="$(jq -r '.p_download_url' <<< "$payload")"

# Check the tagged URL without credentials, including the final asset redirect.
if ! status="$(curl -q --silent --show-error --fail --head --location \
    --proto '=https' --proto-redir '=https' --max-time 30 \
    --retry 4 --retry-all-errors --retry-delay 3 \
    --output /dev/null --write-out '%{http_code}' "$download_url")" || [ "$status" != 200 ]; then
  echo "::error::Public APK for $1 is unavailable; update policy publication failed."
  exit 1
fi

# Pass the credential through curl's config stream and keep the response out of the logs.
if ! status="$(printf '%s' "$payload" | curl -q --silent --show-error --fail \
    --proto '=https' --max-time 30 --output /dev/null --write-out '%{http_code}' \
    --config <(printf 'header = "apikey: %s"\nheader = "Authorization: Bearer %s"\n' "$service_key" "$service_key") \
    --header 'Content-Type: application/json' --data-binary @- \
    "$supabase_url/rest/v1/rpc/admin_service_publish_release")" || [ "$status" != 200 ]; then
  echo "::error::Supabase refused Android update policy for $1 (HTTP ${status:-unknown})."
  exit 1
fi
echo "Published Android update policy for $1."
