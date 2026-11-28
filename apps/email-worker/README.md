# support@ourney.tech auto-reply (Cloudflare Email Worker)

Email Routing sends every message for `support@ourney.tech` to this Worker. The Worker:

1. Forwards the message to the owner's inbox (`FORWARD_TO` secret). This runs first, and a failed reply never stops it.
2. Sends one automatic reply, Vietnamese first and English second, from `Ourney Support <support@ourney.tech>` through the Resend API. The reply carries `In-Reply-To`, `References`, the subject `Re: <original>` and `Auto-Submitted: auto-replied`.

There is no reply when any of these is true (`src/filter.ts`):

- the sender is empty, `MAILER-DAEMON`, `postmaster`, `bounce`, or a `no-reply`/`noreply`/`do-not-reply` address;
- the sender is on `@ourney.tech` or a subdomain of it (moderation alerts, Supabase functions, our own mail);
- the message has `Auto-Submitted` (other than `no`), `Precedence: bulk|list|junk`, `List-Id`, `List-Unsubscribe`, `X-Autoreply`, `X-Autorespond`, or `X-Auto-Response-Suppress: All|OOF|AutoReply`;
- it is a bounce report (`multipart/report`);
- Cloudflare's `Authentication-Results` shows neither `spf=pass` nor `dmarc=pass`, so the sender address may be forged;
- the sender already got a reply in the last 24h (KV, `src/rate-limit.ts`);
- `DAILY_REPLY_CAP` replies (default 30) have already gone out today (UTC). Resend's free tier allows 100 emails a day, and that quota is shared with Auth OTP, the waitlist and moderation mail.

KV stores only a SHA-256 hash of the sender address. Logs show only the outcome (`sent`, `skip:<reason>`, `failed`), never addresses or message content.

The reply text is in `src/copy.ts`.

## Development

```sh
npm ci
npm run typecheck
npm test
```

## Deploy (owner, one time)

You need Node 20 or later and the Cloudflare account that holds `ourney.tech`. Run every command in `apps/email-worker`.

1. **Install:** `npm ci`
2. **Log in:** `npx wrangler login`. A browser opens. Pick the account with `ourney.tech` and click **Allow**.
3. **Create the KV namespace:** `npx wrangler kv namespace create AUTOREPLY_KV`. Copy the `id` it prints into `wrangler.toml`, replacing `REPLACE_WITH_KV_NAMESPACE_ID`. The id is not a secret, so you can commit it.
4. **Create a Resend key:** <https://resend.com> → **API Keys** → **Create API key**. Name it `support-autoreply`, set Permission to **Sending access** and Domain to `ourney.tech`, then copy the key (Resend shows it only once). Keep it separate from the Gmail "Send mail as" key so each one can be revoked on its own.
5. **Deploy:** `npx wrangler deploy`. Nothing reaches the Worker until step 7.
6. **Set the secrets.** Paste each value at the prompt; it is not echoed and is never written to the repo.
   - `npx wrangler secret put FORWARD_TO`: your Gmail address. It must already be a **Verified** destination under Email Routing → Destination addresses.
   - `npx wrangler secret put RESEND_API_KEY`: the key from step 4.
7. **Switch the route:** <https://dash.cloudflare.com> → **ourney.tech** → **Email** → **Email Routing** → **Routing rules**. On the `support@ourney.tech` row click **Edit**. Change **Action** from *Send to an email* to **Send to a Worker**, pick **Destination** `ourney-support-autoreply`, and click **Save**. Leave the catch-all and the other rules as they are.

### Test

Use an account that is **not** your Gmail and not on `@ourney.tech`, for example a second Gmail or Outlook.

1. In a terminal, run `npx wrangler tail` to watch the logs live.
2. Send a mail to `support@ourney.tech` with a Vietnamese subject, for example `Thử hỗ trợ lần 1`.
3. Check that:
   - the mail reaches your Gmail as before;
   - the test account gets `Re: Thử hỗ trợ lần 1` from `Ourney Support <support@ourney.tech>`, in the same thread as the mail it sent;
   - on the reply, **⋮ → Show original** shows `SPF: PASS`, `DKIM: PASS` with `ourney.tech`, and `DMARC: PASS`;
   - the tail shows `{"autoreply":"sent"}`.
4. Send a second mail from the same account. It still reaches Gmail, gets no reply, and the tail shows `skip:rate-limited`.
5. Optional: trigger a moderation alert, or send from any `@ourney.tech` address. The tail shows `skip:own-domain`.

To test again with the same account within 24h, delete its key with `npx wrangler kv key list --binding AUTOREPLY_KV --remote` and then `npx wrangler kv key delete --binding AUTOREPLY_KV --remote "sender:<hash>"`.

### Roll back

- **Stop everything right away:** go to Email Routing → Routing rules → `support@ourney.tech` → **Edit**, set Action back to **Send to an email** → your Gmail, and click **Save**. Mail flows exactly as it did before, and nothing is lost.
- **Stop only the replies:** run `npx wrangler secret delete RESEND_API_KEY`. The Worker keeps forwarding and logs `skip:no-api-key`.
- **Remove the Worker** (after the route is switched back): `npx wrangler delete`.
