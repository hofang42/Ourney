// Cloudflare Pages Function: /f/:token
// Calls public.preview_friend_invite server-side and rewrites Open Graph / Twitter / meta tags
// with HTMLRewriter so crawlers that do not execute JS (Messenger, Zalo, iMessage, Telegram)
// display "{Tên} mời bạn kết bạn trên Ourney", and embeds the preview payload on <html data-invite-preview>
// so browsers do not fire a second redundant RPC. Fails open to static /f on timeout (~1.5s) or error.

const DEFAULT_SUPABASE_URL = 'https://dmgpwpaouiphhrtukcie.supabase.co';
const DEFAULT_SUPABASE_ANON_KEY = 'sb_publishable_YP_EL-U5_VqOKJpMuXexmA_eCQpc5Kt';
const FRIEND_TOKEN_RE = /^[a-z0-9]{12}$/;
const RPC_TIMEOUT_MS = 1500;

function sanitizeText(raw) {
  if (typeof raw !== 'string') return '';
  return raw.replace(/[\u0000-\u001F\u007F]/g, '').trim();
}

function serializeEmbeddedJson(payload) {
  return JSON.stringify(payload).replace(/[<>&]/g, (ch) => {
    if (ch === '<') return '\\u003c';
    if (ch === '>') return '\\u003e';
    return '\\u0026';
  });
}

function putEdgeCache(context, edgeCache, cacheKey, assetResponse, responseToCache) {
  if (!assetResponse || !assetResponse.ok || !edgeCache || !cacheKey) return;
  let cloned = null;
  try {
    cloned = responseToCache.clone();
    const putPromise = Promise.resolve(edgeCache.put(cacheKey, cloned)).catch(() => {
      if (cloned && cloned.body && typeof cloned.body.cancel === 'function') {
        try {
          Promise.resolve(cloned.body.cancel()).catch(() => {});
        } catch (_) {}
      }
    });
    if (context && typeof context.waitUntil === 'function') {
      context.waitUntil(putPromise);
    }
  } catch (_) {
    if (cloned && cloned.body && typeof cloned.body.cancel === 'function') {
      try {
        Promise.resolve(cloned.body.cancel()).catch(() => {});
      } catch (_) {}
    }
  }
}

async function fetchStaticFriendPage(context) {
  const { request, env } = context;
  if (env && env.ASSETS && typeof env.ASSETS.fetch === 'function') {
    let res = await env.ASSETS.fetch(new Request(new URL('/f', request.url), { method: 'GET' }));
    if (res.status === 404) {
      res = await env.ASSETS.fetch(new Request(new URL('/f.html', request.url), { method: 'GET' }));
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
    if (!res.ok) return { status: 'error', preview: null };
    const data = await res.json();
    if (!data || typeof data !== 'object') return { status: 'empty', preview: null };
    const displayName = sanitizeText(data.display_name);
    if (!displayName) return { status: 'empty', preview: null };
    return {
      status: 'ok',
      preview: {
        displayName,
        handle: sanitizeText(data.handle).replace(/^@+/, ''),
        avatarInitial: sanitizeText(data.avatar_initial)
      }
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

export async function onRequestGet(context) {
  const rawToken = (context.params && context.params.token) ? String(context.params.token) : '';
  let token = '';
  try {
    token = decodeURIComponent(rawToken).trim().toLowerCase();
  } catch (_) {
    token = '';
  }

  const validFormat = FRIEND_TOKEN_RE.test(token);
  const edgeCache = validFormat ? getEdgeCache() : null;
  const cacheKey = edgeCache && context.request
    ? new Request(new URL(`/f/${encodeURIComponent(token)}`, context.request.url).toString(), { method: 'GET' })
    : null;

  if (edgeCache && cacheKey) {
    try {
      const cached = await edgeCache.match(cacheKey);
      if (cached) return cached;
    } catch (_) {}
  }

  const [assetResponse, lookup] = await Promise.all([
    fetchStaticFriendPage(context),
    validFormat
      ? lookupFriendInvite(token, context.env)
      : Promise.resolve({ status: 'invalid', preview: null })
  ]);

  const headers = new Headers(assetResponse.headers);
  headers.delete('ETag');
  headers.delete('Last-Modified');
  if (lookup.status === 'error' || !assetResponse.ok) {
    headers.set('Cache-Control', 'no-store');
  } else {
    headers.set('Cache-Control', 'public, max-age=60, s-maxage=300, stale-while-revalidate=600');
  }

  const baseResponse = new Response(assetResponse.body, {
    status: assetResponse.status,
    statusText: assetResponse.statusText,
    headers
  });

  if (typeof HTMLRewriter === 'undefined' || !assetResponse.ok || lookup.status === 'error' || lookup.status === 'invalid') {
    return baseResponse;
  }

  if (lookup.status === 'empty' || !lookup.preview) {
    const emptyPayload = serializeEmbeddedJson({ status: 'empty', token, data: null });
    const emptyRewritten = await new HTMLRewriter()
      .on('html', {
        element(el) {
          el.setAttribute('data-invite-preview', emptyPayload);
        }
      })
      .transform(baseResponse);

    putEdgeCache(context, edgeCache, cacheKey, assetResponse, emptyRewritten);
    return emptyRewritten;
  }

  const { preview } = lookup;
  const headline = `${preview.displayName} mời bạn kết bạn trên Ourney`;
  const description = preview.handle
    ? `${headline} (@${preview.handle}) — mở trong ứng dụng để kết nối, chia sẻ hành trình ảnh mỗi ngày và giữ chuỗi cùng nhau.`
    : `${headline} — mở trong ứng dụng để kết nối, chia sẻ hành trình ảnh mỗi ngày và giữ chuỗi cùng nhau.`;
  const canonicalUrl = `https://ourney.tech/f/${encodeURIComponent(token)}`;
  const embeddedPayload = serializeEmbeddedJson({
    status: 'ok',
    token,
    data: {
      display_name: preview.displayName,
      handle: preview.handle,
      avatar_initial: preview.avatarInitial
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

  putEdgeCache(context, edgeCache, cacheKey, assetResponse, rewritten);

  return rewritten;
}

export async function onRequestHead(context) {
  const res = await onRequestGet(context);
  if (res.body && typeof res.body.cancel === 'function') {
    const cancelPromise = Promise.resolve(res.body.cancel()).catch(() => {});
    if (context && typeof context.waitUntil === 'function') {
      context.waitUntil(cancelPromise);
    }
  }
  return new Response(null, {
    status: res.status,
    statusText: res.statusText,
    headers: res.headers
  });
}
