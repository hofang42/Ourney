// Cloudflare Pages Function: /j/:code
// Calls public.preview_group_invite server-side and rewrites Open Graph / Twitter / meta tags
// with HTMLRewriter so crawlers that do not execute JS (Messenger, Zalo, iMessage, Telegram)
// display "Vào squad {name} trên Ourney". Fails open to static /j on timeout (~1.5s) or error.

const DEFAULT_SUPABASE_URL = 'https://dmgpwpaouiphhrtukcie.supabase.co';
const DEFAULT_SUPABASE_ANON_KEY = 'sb_publishable_YP_EL-U5_VqOKJpMuXexmA_eCQpc5Kt';
const SQUAD_CODE_RE = /^[A-Z0-9]{8}$/;
const RPC_TIMEOUT_MS = 1500;

function sanitizeText(raw) {
  if (typeof raw !== 'string') return '';
  return raw.replace(/[\u0000-\u001F\u007F]/g, '').trim();
}

async function fetchStaticSquadPage(context) {
  const { request, env } = context;
  if (env && env.ASSETS && typeof env.ASSETS.fetch === 'function') {
    const init = { method: 'GET', headers: request.headers };
    let res = await env.ASSETS.fetch(new Request(new URL('/j', request.url), init));
    if (res.status === 404) {
      res = await env.ASSETS.fetch(new Request(new URL('/j.html', request.url), init));
    }
    return res;
  }
  if (typeof context.next === 'function') {
    return context.next();
  }
  return new Response('Not found', { status: 404 });
}

async function lookupGroupInvite(code, env) {
  const supabaseUrl = ((env && env.SUPABASE_URL) || DEFAULT_SUPABASE_URL).replace(/\/+$/, '');
  const anonKey = (env && env.SUPABASE_ANON_KEY) || DEFAULT_SUPABASE_ANON_KEY;
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), RPC_TIMEOUT_MS);

  try {
    const res = await fetch(`${supabaseUrl}/rest/v1/rpc/preview_group_invite`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        apikey: anonKey,
        Authorization: `Bearer ${anonKey}`
      },
      body: JSON.stringify({ p_code: code }),
      signal: controller.signal
    });
    if (!res.ok) return null;
    const data = await res.json();
    if (!data || typeof data !== 'object') return null;
    const title = sanitizeText(data.title || data.group_name);
    if (!title) return null;
    const memberCount = typeof data.member_count === 'number' && Number.isFinite(data.member_count)
      ? data.member_count
      : null;
    const maxMembers = typeof data.max_members === 'number' && Number.isFinite(data.max_members)
      ? data.max_members
      : null;
    const inviterName = sanitizeText(data.inviter_display_name || data.owner_display_name);
    return { title, memberCount, maxMembers, inviterName };
  } catch (_) {
    return null;
  } finally {
    clearTimeout(timer);
  }
}

export async function handleSquadInviteRequest(context, routePrefix = 'j') {
  const rawCode = (context.params && context.params.code) ? String(context.params.code) : '';
  let code = '';
  try {
    code = decodeURIComponent(rawCode).replace(/[\s\-_.]/g, '').toUpperCase();
  } catch (_) {
    code = '';
  }

  const validFormat = SQUAD_CODE_RE.test(code);
  const [assetResponse, preview] = await Promise.all([
    fetchStaticSquadPage(context),
    validFormat ? lookupGroupInvite(code, context.env) : Promise.resolve(null)
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

  const headline = `Vào squad ${preview.title} trên Ourney`;
  const parts = [];
  if (preview.memberCount !== null && preview.maxMembers !== null) {
    parts.push(`${preview.memberCount}/${preview.maxMembers} thành viên`);
  } else if (preview.memberCount !== null) {
    parts.push(`${preview.memberCount} thành viên`);
  }
  if (preview.inviterName) {
    parts.push(`${preview.inviterName} mời bạn`);
  }
  const detail = parts.length > 0 ? ` (${parts.join(' · ')})` : '';
  const description = `${headline}${detail} — mở trong ứng dụng hoặc dùng mã mời ${code} để tham gia ngay.`;
  const canonicalUrl = `https://ourney.tech/${routePrefix}/${encodeURIComponent(code)}`;

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

export async function onRequestGet(context) {
  return handleSquadInviteRequest(context, 'j');
}
