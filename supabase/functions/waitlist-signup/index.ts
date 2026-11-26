// waitlist-signup: beta waitlist of the landing page (apps/landing, section #beta).
//   POST /functions/v1/waitlist-signup
//   body: {"email": "...", "lang": "vi"|"en", "platforms": ["ios","android"], "source": "landing",
//          "website": ""}   <- honeypot, must stay empty
// Stores the email through public.waitlist_signup (migration 0022/0035, service role only) and sends a
// thank-you email through Resend to NEW emails only (an existing email gets the same 200 and no
// mail, so the form can neither reveal who signed up nor be used to mail-bomb someone).
// Anonymous by design: deployed with --no-verify-jwt (config.toml verify_jwt = false).
//
// Secrets (supabase secrets set ...), see docs/runbooks/landing-waitlist.md:
//   RESEND_API_KEY            required to send mail (without it signups are stored, mail skipped)
//   WAITLIST_FROM             sender on a Resend-verified domain, e.g. "Ourney <hello@ourney.tech>"
//   WAITLIST_REPLY_TO         optional reply-to address
//   WAITLIST_NOTIFY_TO        optional: owner address that gets a short note for every new signup
//   WAITLIST_ALLOWED_ORIGINS  optional comma-separated CORS allow-list
//                             (default https://ourney.tech,https://www.ourney.tech)
// No raw IP is stored: rate limiting keys on a keyed HMAC-SHA256 of cf-connecting-ip.
import { isIP } from "node:net";
import { adminClient, json, serviceRoleKey } from "../_shared/admin.ts";

const MAX_BODY_BYTES = 2048;
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;
const DEFAULT_ORIGINS = ["https://ourney.tech", "https://www.ourney.tech"];
const RESEND_URL = "https://api.resend.com/emails";
const RESEND_TIMEOUT_MS = 8000;

type Lang = "vi" | "en";
type SignupResult = { status: "created" | "exists" | "rate_limited" | "invalid"; id?: string };

export type WaitlistDeps = {
  createAdmin?: typeof adminClient;
  rateLimitSecret?: string;
  fetchFn?: typeof fetch;
  envGet?: (key: string) => string | undefined;
};

export function allowedOrigins(envGet: (key: string) => string | undefined = Deno.env.get): string[] {
  const raw = envGet("WAITLIST_ALLOWED_ORIGINS");
  if (!raw) return DEFAULT_ORIGINS;
  return raw.split(",").map((s) => s.trim().replace(/\/+$/, "")).filter(Boolean);
}

function corsHeaders(
  origin: string | null,
  envGet: (key: string) => string | undefined = Deno.env.get,
): Record<string, string> {
  const list = allowedOrigins(envGet);
  const allow = list.includes("*") ? "*" : origin && list.includes(origin) ? origin : list[0] ?? "";
  return {
    "Access-Control-Allow-Origin": allow,
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "content-type",
    "Access-Control-Max-Age": "86400",
    Vary: "Origin",
  };
}

function originAllowed(
  origin: string | null,
  envGet: (key: string) => string | undefined = Deno.env.get,
): boolean {
  const list = allowedOrigins(envGet);
  if (list.includes("*")) return true;
  // Browsers always send Origin on a cross-origin POST; a missing Origin is a script, which the
  // rate limit and the honeypot cover.
  return origin === null || list.includes(origin);
}

export function normalizeEmail(raw: unknown): string | null {
  if (typeof raw !== "string") return null;
  const email = raw.trim().toLowerCase();
  if (email.length < 3 || email.length > 254 || !EMAIL_RE.test(email)) return null;
  return email;
}

export function normalizePlatforms(raw: unknown): string[] {
  const list = Array.isArray(raw) ? raw.filter((p) => p === "ios" || p === "android") : [];
  const unique = [...new Set(list as string[])].sort();
  return unique.length ? unique : ["android", "ios"];
}

/**
 * F-05: Use Cloudflare's ingress `cf-connecting-ip` exclusively (never client-spoofable
 * `X-Forwarded-For` or `X-Real-IP`), canonicalize IPv6, and compute a keyed HMAC-SHA256 digest.
 * When no usable client IP is present, returns `null` so SQL charges the shared fallback bucket.
 */
export async function rateLimitIpHash(req: Request, secret?: string): Promise<string | null> {
  const ip = (req.headers.get("cf-connecting-ip") ?? "").trim();
  const family = isIP(ip);
  if (family === 0 || ip.includes("%")) return null;
  const canonicalIp = family === 6 ? new URL(`http://[${ip}]`).hostname : ip;
  // Cloudflare uses this shared address for cross-zone Worker subrequests.
  if (canonicalIp === "[2a06:98c0:3600::103]") return null;
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret ?? serviceRoleKey()),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const digest = await crypto.subtle.sign("HMAC", key, encoder.encode(`waitlist-signup-ip:v1:${canonicalIp}`));
  return Array.from(new Uint8Array(digest)).map((b) => b.toString(16).padStart(2, "0")).join("");
}

function escapeHtml(s: string): string {
  return s.replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]!);
}

export function confirmationEmail(lang: Lang): { subject: string; text: string; html: string } {
  const c = lang === "en"
    ? {
      subject: "You're on the Ourney beta list",
      hi: "Hi there,",
      body: [
        "Thanks for signing up to try Ourney early. You're on the beta list for iOS and Android.",
        "We'll email you the invite as soon as the first beta wave opens. Until then, there's nothing else you need to do.",
      ],
      sign: "One photo a day. Keep the streak. Go together.",
      team: "The Ourney team",
      foot: "You got this email because this address was entered on ourney.tech. If it wasn't you, just ignore it and we won't email you again.",
    }
    : {
      subject: "Cảm ơn bạn đã đăng ký dùng trước Ourney",
      hi: "Chào bạn,",
      body: [
        "Cảm ơn bạn đã đăng ký dùng trước Ourney. Tụi mình đã ghi tên bạn vào danh sách beta cho iOS và Android.",
        "Khi đợt beta đầu tiên mở, tụi mình sẽ gửi lời mời qua email này. Từ giờ tới lúc đó bạn không cần làm gì thêm.",
      ],
      sign: "Chụp một tấm. Giữ một chuỗi. Đi cùng nhau.",
      team: "Đội ngũ Ourney",
      foot: "Bạn nhận được email này vì địa chỉ này vừa được nhập trên ourney.tech. Nếu không phải bạn, cứ bỏ qua, tụi mình sẽ không gửi thêm.",
    };

  const text = [c.hi, "", ...c.body.flatMap((p) => [p, ""]), c.sign, c.team, "", "—", c.foot].join("\n");
  const paragraphs = c.body
    .map((p) => `<p style="margin:0 0 16px;font-size:16px;line-height:1.55;color:#1B1916">${escapeHtml(p)}</p>`)
    .join("");
  const html = `<!doctype html>
<html lang="${lang}"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>${escapeHtml(c.subject)}</title></head>
<body style="margin:0;padding:0;background:#FFF8EE">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#FFF8EE"><tr><td align="center" style="padding:32px 16px">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:520px;background:#FFFFFF;border:2px solid #1B1916;border-radius:16px">
<tr><td style="padding:28px 28px 8px;font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif">
<p style="margin:0 0 20px;font-size:22px;font-weight:700;color:#1B1916">ourney</p>
<p style="margin:0 0 16px;font-size:16px;line-height:1.55;color:#1B1916">${escapeHtml(c.hi)}</p>
${paragraphs}
<p style="margin:24px 0 4px;font-size:15px;line-height:1.5;color:#1B1916;font-weight:600">${escapeHtml(c.sign)}</p>
<p style="margin:0 0 24px;font-size:15px;line-height:1.5;color:#5A544C">${escapeHtml(c.team)}</p>
</td></tr></table>
<p style="max-width:520px;margin:16px auto 0;font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;font-size:12px;line-height:1.5;color:#5A544C">${escapeHtml(c.foot)}</p>
</td></tr></table>
</body></html>`;
  return { subject: c.subject, text, html };
}

async function sendResend(
  payload: Record<string, unknown>,
  fetchFn: typeof fetch,
  envGet: (key: string) => string | undefined,
): Promise<string | null> {
  const key = envGet("RESEND_API_KEY");
  if (!key) return "mail_not_configured: RESEND_API_KEY missing";
  try {
    const res = await fetchFn(RESEND_URL, {
      method: "POST",
      headers: { Authorization: `Bearer ${key}`, "Content-Type": "application/json" },
      body: JSON.stringify(payload),
      signal: AbortSignal.timeout(RESEND_TIMEOUT_MS),
    });
    if (res.ok) {
      await res.body?.cancel();
      return null;
    }
    return `resend_${res.status}: ${(await res.text()).slice(0, 400)}`;
  } catch (e) {
    return `resend_failed: ${e instanceof Error ? e.message : String(e)}`;
  }
}

async function sendConfirmation(
  email: string,
  lang: Lang,
  fetchFn: typeof fetch,
  envGet: (key: string) => string | undefined,
): Promise<string | null> {
  const from = envGet("WAITLIST_FROM");
  if (!from) return "mail_not_configured: WAITLIST_FROM missing";
  const mail = confirmationEmail(lang);
  const replyTo = envGet("WAITLIST_REPLY_TO");
  return await sendResend(
    {
      from,
      to: [email],
      subject: mail.subject,
      text: mail.text,
      html: mail.html,
      ...(replyTo ? { reply_to: replyTo } : {}),
    },
    fetchFn,
    envGet,
  );
}

async function notifyOwner(
  email: string,
  lang: Lang,
  platforms: string[],
  fetchFn: typeof fetch,
  envGet: (key: string) => string | undefined,
): Promise<void> {
  const to = envGet("WAITLIST_NOTIFY_TO");
  const from = envGet("WAITLIST_FROM");
  if (!to || !from) return;
  const err = await sendResend(
    {
      from,
      to: to.split(",").map((s) => s.trim()).filter(Boolean),
      subject: `[Ourney waitlist] ${email}`,
      text: `New beta signup\nemail: ${email}\nlang: ${lang}\nplatforms: ${platforms.join(", ")}\n`,
    },
    fetchFn,
    envGet,
  );
  if (err) console.error("waitlist-signup owner notify failed", err);
}

export async function handle(req: Request, deps: WaitlistDeps = {}): Promise<Response> {
  const envGet = deps.envGet ?? ((k: string) => Deno.env.get(k));
  const fetchFn = deps.fetchFn ?? fetch;
  const origin = req.headers.get("origin");
  const cors = corsHeaders(origin, envGet);
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: cors });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405, { ...cors, Allow: "POST" });
  if (!originAllowed(origin, envGet)) return json({ error: "forbidden_origin" }, 403, cors);

  const raw = await req.text();
  if (raw.length > MAX_BODY_BYTES) return json({ error: "payload_too_large" }, 413, cors);
  let body: Record<string, unknown>;
  try {
    const parsed = JSON.parse(raw);
    if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) throw new Error("not an object");
    body = parsed as Record<string, unknown>;
  } catch {
    return json({ error: "invalid_body" }, 400, cors);
  }

  // Honeypot: real visitors never see the field. Pretend success so bots learn nothing.
  if (typeof body.website === "string" && body.website.trim() !== "") return json({ ok: true }, 200, cors);

  const email = normalizeEmail(body.email);
  if (!email) return json({ error: "invalid_email" }, 400, cors);
  const lang: Lang = body.lang === "en" ? "en" : "vi";
  const platforms = normalizePlatforms(body.platforms);
  const source = typeof body.source === "string" ? body.source.slice(0, 64) : "landing";
  const ipHash = await rateLimitIpHash(req, deps.rateLimitSecret);

  const admin = (deps.createAdmin ?? adminClient)();
  const { data, error } = await admin.rpc("waitlist_signup", {
    p_email: email,
    p_lang: lang,
    p_platforms: platforms,
    p_source: source,
    p_ip_hash: ipHash,
  });
  if (error) {
    console.error("waitlist-signup rpc failed", error.message);
    return json({ error: "internal" }, 500, cors);
  }
  const result = data as SignupResult;
  if (result.status === "rate_limited") return json({ error: "rate_limited" }, 429, cors);
  if (result.status === "invalid") return json({ error: "invalid_email" }, 400, cors);

  if (result.status === "created" && result.id) {
    const [mailError] = await Promise.all([
      sendConfirmation(email, lang, fetchFn, envGet),
      notifyOwner(email, lang, platforms, fetchFn, envGet),
    ]);
    if (mailError) console.error("waitlist-signup confirmation failed", mailError);
    const { error: markError } = await admin.rpc("waitlist_mark_confirmation", {
      p_id: result.id,
      p_error: mailError,
    });
    if (markError) console.error("waitlist-signup mark failed", markError.message);
  }

  // Same answer for new and existing emails.
  return json({ ok: true }, 200, cors);
}

if (import.meta.main) {
  Deno.serve(async (req: Request): Promise<Response> => {
    try {
      return await handle(req);
    } catch (e) {
      console.error("waitlist-signup failed", e instanceof Error ? e.message : String(e));
      return json({ error: "internal" }, 500, corsHeaders(req.headers.get("origin")));
    }
  });
}
