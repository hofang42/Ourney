# Runbook: Ourney Admin Dashboard (`admin.ourney.tech`)

> Code: migration [`0023_admin.sql`](../../supabase/migrations/0023_admin.sql), pgTAP test [`23_admin.test.sql`](../../supabase/tests/23_admin.test.sql), Edge Function [`admin-action`](../../supabase/functions/admin-action/index.ts), deploy script [`scripts/supabase/deploy-hosted.sh`](../../scripts/supabase/deploy-hosted.sh).

---

## 1. Architecture & Privacy-by-Construction Overview

- **RPC-Only Boundary (`schema admin`):** The Admin web app uses **only** the public `VITE_SUPABASE_ANON_KEY` and calls `supabase.schema('admin').rpc(...)` with the signed-in admin's Bearer JWT. Schema `admin` exposes **30 `SECURITY DEFINER` RPC functions** (plus feature-request admin RPCs added by `0024_feature_requests.sql`) and **zero tables or views**.
- **Private Storage & Audit Tables (`schema private`):** `private.admins`, `private.admin_audit` (append-only via `immutable_audit_log` trigger), `private.admin_media_grants` (5-minute TTL), and `private.user_moderation` all have RLS enabled and zero grants to `anon` or `authenticated`.
- **Zero Casual Browsing of Private UGC:**
  - Admins cannot browse arbitrary `check_ins`, `check_in_metrics` (weights/distances), `check_in_extras`, `conversations`, or `messages`.
  - In `admin.list_journeys`, journey `title` and `emoji` are `NULL` in SQL unless `public_token IS NOT NULL`.
  - In `admin.get_moderation_item`, only the single reported check-in or single reported chat message is returned—never surrounding chat messages.
  - Reported photos require an explicit click on **"Reveal Reported Media"**, which calls `admin.reveal_reported_media(p_queue_id, p_purpose)`, logs `moderation.reveal_media` in `private.admin_audit`, and grants `storage.objects` `SELECT` permission on **only** that item's paths for **5 minutes**.

---

## 2. Bootstrap the First Owner Admin (One-Time SQL)

1. Sign into Ourney at least once (via the mobile app or the admin OTP screen) so your email exists in `auth.users`.
2. Open **Supabase Dashboard → SQL Editor** and run the following snippet (replace `owner@ourney.tech` with your real account email):

```sql
-- Bootstrap the first Ourney owner admin.
-- Replace 'owner@ourney.tech' with your real Ourney account email, then run in Supabase SQL Editor.
do $$
declare
  v_email constant text := lower(btrim('owner@ourney.tech'));
  v_uid uuid;
begin
  select u.id into v_uid
    from auth.users u
   where lower(u.email) = v_email
   limit 1;

  if v_uid is null then
    raise exception 'No auth.users account found for %. Sign in once via the app or OTP first, then re-run.', v_email;
  end if;

  insert into private.admins (user_id, role, note, added_by)
  values (v_uid, 'owner', 'Initial owner bootstrap', v_uid)
  on conflict (user_id) do update
    set role = 'owner',
        updated_at = now();

  insert into private.admin_audit (admin_id, admin_email, action, target_type, target_id, reason, meta)
  values (
    v_uid,
    v_email,
    'admins.bootstrap_owner',
    'admin',
    v_uid::text,
    'Initial SQL Editor bootstrap by project owner',
    jsonb_build_object('role', 'owner')
  );
end $$;
```

3. Once bootstrapped as `owner`, you can add or remove `moderator` or co-`owner` accounts directly from the Admin UI (**Settings & System Ops → Admin Team**) via `admin.upsert_admin_user` and `admin.remove_admin_user`. The database prevents removing or demoting the last remaining `owner` (`cannot_remove_last_owner`).

---

## 3. Hosted Supabase Schema Exposure (`db_schemas`) & Edge Function Secrets

### 3.1 Exposing the `admin` Schema in PostgREST
- **Local development (`supabase start`):** Configured in [`supabase/config.toml`](../../supabase/config.toml) under `[api]`:
  ```toml
  schemas = ["public", "graphql_public", "admin"]
  ```
- **Hosted Supabase (`deploy-hosted.sh`):** Because `supabase db push` does not push `config.toml`'s `[api].schemas` to a hosted project, [`scripts/supabase/deploy-hosted.sh`](../../scripts/supabase/deploy-hosted.sh) automatically runs:
  - `PATCH /v1/projects/$SUPABASE_PROJECT_REF/postgrest` with `{"db_schema":"public,graphql_public,admin"}`
  - `supabase functions deploy admin-action --project-ref "$SUPABASE_PROJECT_REF"` (with JWT verification enabled)
- **Manual Dashboard verification:** In **Supabase Dashboard → Project Settings → Data API → Exposed schemas**, confirm `admin` is listed alongside `public` and `graphql_public`.

### 3.2 Edge Function Secrets for `admin-action`
`admin-action` reuses the existing project secrets configured for `waitlist-signup` and `notify-moderation`:

| Secret | Required For | Description |
| :--- | :---: | :--- |
| `RESEND_API_KEY` | `waitlist_resend` | Resend API key for re-sending waitlist confirmation emails. |
| `WAITLIST_FROM` | `waitlist_resend` | Verified sender address, e.g. `Ourney <hello@ourney.tech>`. |
| `WAITLIST_REPLY_TO` | *(optional)* | Reply-to address on waitlist confirmation emails. |
| `MODERATION_WEBHOOK_URL` | `trigger_moderation_notify` | Resend (`https://api.resend.com/emails`) or webhook URL for 24h SLA alerts. |
| `MODERATION_WEBHOOK_API_KEY` | *(optional)* | Bearer key for `MODERATION_WEBHOOK_URL`. |
| `MODERATION_NOTIFY_EMAIL` | *(optional)* | Recipient for moderation alerts (default `support@ourney.tech`). |
| `ADMIN_ALLOWED_ORIGINS` | *(optional)* | Comma-separated CORS allow-list for `admin-action` (default includes `https://admin.ourney.tech` and local dev ports). |

---

## 4. Cloudflare Pages Deployment & Cloudflare Zero Trust Access Setup

### 4.1 Cloudflare Pages Project Setup (`admin.ourney.tech`)
1. In **Cloudflare Dashboard → Compute (Workers & Pages) → Pages**, create a project connected to the `Ourney` repository named **`ourney-admin`**.
2. Configure **Build settings** ([Cloudflare Pages Build configuration docs](https://developers.cloudflare.com/pages/configuration/build-configuration/)):
   - **Production branch:** `main`
   - **Root directory (Path):** `apps/admin`
   - **Build command:** `npm ci && npm run build`
   - **Build output directory:** `dist`
   - **Build watch paths:** Include `apps/admin/**` only (so commits outside `apps/admin/` do not trigger unnecessary builds).
3. Configure **Environment Variables** (Production & Preview):
   - `NODE_VERSION`: `22` (Node 20+ supported)
   - `VITE_SUPABASE_URL`: `https://<project-ref>.supabase.co`
   - `VITE_SUPABASE_ANON_KEY`: your public anon/publishable key
   - `VITE_CF_BEACON_TOKEN` *(optional)*: Cloudflare Web Analytics site token. When set at build time, `src/lib/cfBeacon.ts` injects `https://static.cloudflareinsights.com/beacon.min.js` at startup; when unset, no beacon is injected. Keep Cloudflare Pages automatic Web Analytics injection **disabled** so there is no double counting or CSP conflict.
   - **NEVER** add `SUPABASE_SERVICE_ROLE_KEY` or `SUPABASE_ACCESS_TOKEN` to Cloudflare Pages.
4. Assign custom domain `admin.ourney.tech`.
5. **Headers & SPA routing:**
   - [`apps/admin/public/_headers`](../../apps/admin/public/_headers) is copied by Vite into `dist/_headers` ([Cloudflare Pages Headers docs](https://developers.cloudflare.com/pages/configuration/headers/)) and enforces `X-Robots-Tag: noindex, nofollow, noarchive, nosnippet`, `Referrer-Policy: no-referrer`, `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Permissions-Policy: camera=(), microphone=(), geolocation=()`, and a strict `Content-Security-Policy`.
   - Because `apps/admin` has no top-level `404.html`, Cloudflare Pages automatically provides SPA fallback to `/index.html` for deep links such as `/users/123`, while [`apps/admin/public/assets/404.html`](../../apps/admin/public/assets/404.html) uses Pages' hierarchical not-found lookup so missing chunk requests under `/assets/*` still return `404 Not Found` ([Serving Pages docs](https://developers.cloudflare.com/pages/configuration/serving-pages/)).
6. **Legacy Vercel rollback configuration:** `apps/admin/vercel.json` is legacy and kept intact only for rollback until DNS cutover from Vercel to Cloudflare Pages is complete; a subsequent cleanup task removes it.

### 4.2 Cloudflare Zero Trust Access Perimeter Gate (Recommended)
To put a free pre-app identity gate in front of `https://admin.ourney.tech` before the bundle even loads:
1. In **Cloudflare Dashboard → Zero Trust → Access → Applications**, click **Add an application → Self-hosted**.
2. Set **Application domain** to `admin.ourney.tech` and **Session Duration** to `24 hours`.
3. Under **Authentication**, enable **One-time PIN** (or Google Workspace / GitHub SSO).
4. Add an **Allow** policy (`Admin Operators`) with selector **Emails** matching your admin email(s) (e.g. `owner@ourney.tech`).
5. Under **CORS / Bypass rules**, do not bypass any path: `admin.ourney.tech` is a static SPA that talks directly to `https://<project-ref>.supabase.co`.

---

## 5. Daily 24-Hour SLA Triage & Operations Workflow

### 5.1 Morning 60-Second Health Check (`/`)
Open `https://admin.ourney.tech` each morning and check the **Urgent Action Banner** at the top of **Overview**:
1. **Open Moderation Reports (`24h SLA`):** Must be triaged before `hours_remaining` hits `0h` (Apple App Store Guideline 1.2 & Google Play UGC policy require acting within 24 hours).
2. **Untriaged Feature Requests (`status = 'new'`):** Review new community ideas, merge duplicates, or move to `under_review` / `planned`.
3. **Failed Waitlist Confirmation Emails:** Click through to `/waitlist?mail_status=failed` and click **Bulk Retry Failed Emails**.
4. **Stuck Storage Purge Items (`attempts >= 20`):** Click through to `/settings`, inspect `last_error`, click **Reset Stuck Retries**, and click **Run Storage Purge Sweep Now**.

### 5.2 Triage a UGC Report Within the 24-Hour SLA (`/moderation`)
1. Open `/moderation` (sorted by `open` first → `due_at ASC` → severity `self_harm` / `nudity` / `harassment`).
2. Select the top queue item to open the right-hand inspector (`admin.get_moderation_item`, audited as `moderation.view_item`).
3. Review the reporter's reason, sibling report count (`distinct_open_reporters`), the target user's strike history (`target_prior_actions`), and the scoped text excerpt.
4. If media is attached and visual verification is required:
   - Click **Reveal Reported Media (Audited, 5m TTL)** (`admin.reveal_reported_media`, audited as `moderation.reveal_media`).
   - Toggle the safety blur (`Blur / Unblur`) only as needed.
5. Choose one resolution action (always include a clear resolution note):
   - **Dismiss (`dismiss`):** False alarm or benign photo; restores any auto-quarantined item (`moderated_at = null`) and marks open reports `dismissed`.
   - **Quarantine (`quarantine_moderation_target`):** Hides the item immediately (`moderated_at = now()`) while keeping the queue item `open` for investigation.
   - **Remove Content (`remove_content`):** Permanently moderates the check-in or message, queues its Storage objects into `private.pending_storage_purge`, and closes sibling open reports as `actioned`.
   - **Ban User & Wipe Content (`ban_user`):** Suspends the user, revokes sessions and public links, runs full UGC takedown, and closes all open reports against that user.

### 5.3 Reversible Ban vs. Severe Wipe-UGC Ban (`/users`)
- **Reversible Ban (`admin.ban_user(user_id, reason, p_wipe_ugc = false)` — default):**
  - Sets `auth.users.banned_until = now() + 100 years`, revokes all active `auth.sessions` and `auth.refresh_tokens`, records the ban in `private.user_moderation`, and revokes any active `journeys.public_token`.
  - **Does NOT set `public.profiles.deleted_at`** (which is reserved for account deletion) and **does NOT delete private check-in photos**, so mistaken suspensions can be cleanly reversed via `admin.unban_user`.
- **Severe Abuse Takedown (`admin.ban_user(user_id, reason, p_wipe_ugc = true)`):**
  - Performs all ban actions above **plus** moderates all check-ins and messages, queues all user media for Storage purge, removes the user from group journeys (transferring group ownership if needed), and revokes shares and friendships.
- **Verified Delete-on-Request (`POST /functions/v1/admin-action` `{ action: "delete_user" }` — `owner` only):**
  - Used only for verified GDPR / Vietnam Decree 13 account erasure requests. Permanently deletes the `auth.users` account, drains `pending_storage_purge`, and logs `users.delete_on_request` with `sha256(email)` (never plaintext email).
