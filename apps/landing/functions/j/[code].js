// Cloudflare Pages Function: /j/:code
// Calls public.preview_group_invite server-side and rewrites Open Graph / Twitter / meta tags
// with HTMLRewriter so crawlers that do not execute JS (Messenger, Zalo, iMessage, Telegram)
// display "Vào squad {name} trên Ourney", and embeds the preview payload on <html data-invite-preview>
// so browsers do not fire a second redundant RPC. Fails open to static /j on timeout (~1.5s) or error.

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
    let res = await env.ASSETS.fetch(new Request(new URL('/j', request.url), { method: 'GET' }));
    if (res.status === 404) {
      res = await env.ASSETS.fetch(new Request(new URL('/j.html', request.url), { method: 'GET' }));
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
    if (!res.ok) return { status: 'error', preview: null };
    const data = await res.json();
    if (!data || typeof data !== 'object') return { status: 'empty', preview: null };
    const title = sanitizeText(data.title || data.group_name);
    if (!title) return { status: 'empty', preview: null };
    const memberCount = typeof data.member_count === 'number' && Number.isFinite(data.member_count)
      ? data.member_count
      : null;
    const maxMembers = typeof data.max_members === 'number' && Number.isFinite(data.max_members)
      ? data.max_members
      : null;
    const ownerName = sanitizeText(data.owner_display_name);
    return {
      status: 'ok',
      preview: { title, memberCount, maxMembers, ownerName }
    };
  } catch (_) {
    return { status: 'error', preview: null };
  } finally {
    clearTimeout(timer);
  }
}

function getEdgeCache() {
  if (typeof caches !== 'undefined' && caches && caches.default) {
    return caches.default;
  }
  return null;
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
  const edgeCache = validFormat ? getEdgeCache() : null;
  const cacheKey = edgeCache && context.request
    ? new Request(new URL(`/${routePrefix}/${encodeURIComponent(code)}`, context.request.url).toString(), { method: 'GET' })
    : null;

  if (edgeCache && cacheKey) {
    try {
      const cached = await edgeCache.match(cacheKey);
      if (cached) return cached;
    } catch (_) {}
  }

  const [assetResponse, lookup] = await Promise.all([
    fetchStaticSquadPage(context),
    validFormat
      ? lookupGroupInvite(code, context.env)
      : Promise.resolve({ status: 'invalid', preview: null })
  ]);

  const headers = new Headers(assetResponse.headers);
  headers.delete('ETag');
  headers.delete('Last-Modified');
  if (lookup.status === 'error') {
    headers.set('Cache-Control', 'no-store');
  } else {
    headers.set('Cache-Control', 'public, max-age=60, s-maxage=300, stale-while-revalidate=600');
  }

  const baseResponse = new Response(assetResponse.body, {
    status: assetResponse.status,
    statusText: assetResponse.statusText,
    headers
  });

  if (typeof HTMLRewriter === 'undefined' || lookup.status === 'error' || lookup.status === 'invalid') {
    return baseResponse;
  }

  if (lookup.status === 'empty' || !lookup.preview) {
    const emptyPayload = JSON.stringify({ status: 'empty', code, data: null });
    const emptyRewritten = await new HTMLRewriter()
      .on('html', {
        element(el) {
          el.setAttribute('data-invite-preview', emptyPayload);
        }
      })
      .transform(baseResponse);

    if (edgeCache && cacheKey) {
      try {
        const putPromise = edgeCache.put(cacheKey, emptyRewritten.clone());
        if (typeof context.waitUntil === 'function') context.waitUntil(putPromise);
      } catch (_) {}
    }
    return emptyRewritten;
  }

  const { preview } = lookup;
  const headline = `Vào squad ${preview.title} trên Ourney`;
  const parts = [];
  if (preview.memberCount !== null && preview.maxMembers !== null) {
    parts.push(`${preview.memberCount}/${preview.maxMembers} thành viên`);
  } else if (preview.memberCount !== null) {
    parts.push(`${preview.memberCount} thành viên`);
  }
  if (preview.ownerName) {
    parts.push(`Squad của ${preview.ownerName}`);
  }
  const detail = parts.length > 0 ? ` (${parts.join(' · ')})` : '';
  const description = `${headline}${detail} — mở trong ứng dụng hoặc dùng mã mời ${code} để tham gia ngay.`;
  const canonicalUrl = `https://ourney.tech/${routePrefix}/${encodeURIComponent(code)}`;
  const embeddedPayload = JSON.stringify({
    status: 'ok',
    code,
    data: {
      title: preview.title,
      member_count: preview.memberCount,
      max_members: preview.maxMembers,
      owner_display_name: preview.ownerName || null
    }
  });

  const rewritten = await new HTMLRewriter()
    .on('html', {
      element(el) {
        el.setAttribute('data-invite-preview', embeddedPayload);
      }
    })
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

  if (edgeCache && cacheKey) {
    try {
      const putPromise = edgeCache.put(cacheKey, rewritten.clone());
      if (typeof context.waitUntil === 'function') context.waitUntil(putPromise);
    } catch (_) {}
  }

  return rewritten;
}

export async function onRequestGet(context) {
  return handleSquadInviteRequest(context, 'j');
}

export async function onRequestHead(context) {
  const res = await handleSquadInviteRequest(context, 'j');
  return new Response(null, {
    status: res.status,
    statusText: res.statusText,
    headers: res.headers
  });
}
