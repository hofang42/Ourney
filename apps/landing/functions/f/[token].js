// Cloudflare Pages Function: /f/:token
// Calls public.preview_friend_invite server-side and rewrites Open Graph / Twitter / meta tags
// with HTMLRewriter so crawlers that do not execute JS (Messenger, Zalo, iMessage, Telegram)
// display "{Tên} mời bạn kết bạn trên Ourney". Fails open to static /f on timeout (~1.5s) or error.

const DEFAULT_SUPABASE_URL = 'https://dmgpwpaouiphhrtukcie.supabase.co';
const DEFAULT_SUPABASE_ANON_KEY = 'sb_publishable_YP_EL-U5_VqOKJpMuXexmA_eCQpc5Kt';
const FRIEND_TOKEN_RE = /^[a-z0-9]{12}$/;
const RPC_TIMEOUT_MS = 1500;

function sanitizeText(raw) {
  if (typeof raw !== 'string') return '';
  return raw.replace(/[\u0000-\u001F\u007F]/g, '').trim();
}

async function fetchStaticFriendPage(context) {
  const { request, env } = context;
  if (env && env.ASSETS && typeof env.ASSETS.fetch === 'function') {
    const init = { method: 'GET', headers: request.headers };
    let res = await env.ASSETS.fetch(new Request(new URL('/f', request.url), init));
    if (res.status === 404) {
      res = await env.ASSETS.fetch(new Request(new URL('/f.html', request.url), init));
    }
    return res;
  }
  if (typeof context.next === 'function') {
    return context.next();
  }
  return new Response('Not found', { status: 404 });
}

async function lookupFriendInvite(token, env) {
  const supabaseUrl = ((env && env.SUPABASE_URL) || DEFAULT_SUPABASE_URL).replace(/\/+$/, '');
  const anonKey = (env && env.SUPABASE_ANON_KEY) || DEFAULT_SUPABASE_ANON_KEY;
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), RPC_TIMEOUT_MS);

  try {
    const res = await fetch(`${supabaseUrl}/rest/v1/rpc/preview_friend_invite`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        apikey: anonKey,
        Authorization: `Bearer ${anonKey}`
      },
      body: JSON.stringify({ p_token: token }),
      signal: controller.signal
    });
    if (!res.ok) return null;
    const data = await res.json();
    if (!data || typeof data !== 'object') return null;
    const displayName = sanitizeText(data.display_name);
    if (!displayName) return null;
    return {
      displayName,
      handle: sanitizeText(data.handle).replace(/^@+/, ''),
      avatarInitial: sanitizeText(data.avatar_initial)
    };
  } catch (_) {
    return null;
  } finally {
    clearTimeout(timer);
  }
}

export async function onRequestGet(context) {
  const rawToken = (context.params && context.params.token) ? String(context.params.token) : '';
  let token = '';
  try {
    token = decodeURIComponent(rawToken).trim().toLowerCase();
  } catch (_) {
    token = '';
  }

  const validFormat = FRIEND_TOKEN_RE.test(token);
  const [assetResponse, preview] = await Promise.all([
    fetchStaticFriendPage(context),
    validFormat ? lookupFriendInvite(token, context.env) : Promise.resolve(null)
  ]);

  const headers = new Headers(assetResponse.headers);
  headers.set('Cache-Control', 'public, max-age=60, s-maxage=300, stale-while-revalidate=600');
  const baseResponse = new Response(assetResponse.body, {
    status: assetResponse.status,
    statusText: assetResponse.statusText,
    headers
  });

  if (!preview || typeof HTMLRewriter === 'undefined') {
    return baseResponse;
  }

  const headline = `${preview.displayName} mời bạn kết bạn trên Ourney`;
  const description = preview.handle
    ? `${headline} (@${preview.handle}) — mở trong ứng dụng để kết nối, chia sẻ hành trình ảnh mỗi ngày và giữ chuỗi cùng nhau.`
    : `${headline} — mở trong ứng dụng để kết nối, chia sẻ hành trình ảnh mỗi ngày và giữ chuỗi cùng nhau.`;
  const canonicalUrl = `https://ourney.tech/f/${encodeURIComponent(token)}`;

  return new HTMLRewriter()
    .on('title', {
      element(el) {
        el.setInnerContent(`ourney · ${headline}`, { html: false });
      }
    })
    .on('meta[name="description"]', {
      element(el) {
        el.setAttribute('content', description);
      }
    })
    .on('meta[property="og:title"]', {
      element(el) {
        el.setAttribute('content', headline);
      }
    })
    .on('meta[property="og:description"]', {
      element(el) {
        el.setAttribute('content', description);
      }
    })
    .on('meta[property="og:url"]', {
      element(el) {
        el.setAttribute('content', canonicalUrl);
      }
    })
    .on('meta[name="twitter:title"]', {
      element(el) {
        el.setAttribute('content', headline);
      }
    })
    .on('meta[name="twitter:description"]', {
      element(el) {
        el.setAttribute('content', description);
      }
    })
    .on('meta[name="twitter:url"]', {
      element(el) {
        el.setAttribute('content', canonicalUrl);
      }
    })
    .transform(baseResponse);
}
