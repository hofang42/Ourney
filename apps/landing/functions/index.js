// Keep these strings in sync with main.js COPY.en.
const EN = {
  title: 'Ourney · One photo at a time, at your own pace',
  meta_desc: 'A photo diary for what you want to keep up: study, running, body goals, a trip, reading. Each check-in is one photo, kept private or shared with friends.',
  og_title: 'Ourney · One photo at a time, at your own pace',
  og_url: 'https://ourney.tech/?lang=en',
  og_locale: 'en_US',
  og_locale_alt: 'vi_VN',
  og_image: 'https://ourney.tech/assets/og/og-default-en.png',
  og_image_alt: 'Ourney: One photo at a time, at your own pace. Daily photo diary on Android and iOS'
};

export async function onRequestGet(context) {
  if (new URL(context.request.url).searchParams.get('lang') !== 'en') {
    return context.next();
  }

  const response = await context.next();
  if (typeof HTMLRewriter === 'undefined' || !response.ok) return response;

  const rewriter = new HTMLRewriter()
    .on('html', { element(el) { el.setAttribute('lang', 'en'); } })
    .on('title', { element(el) { el.setInnerContent(EN.title, { html: false }); } })
    .on('#link-canonical', { element(el) { el.setAttribute('href', EN.og_url); } });

  for (const [selector, content] of [
    ['meta[name="description"], #meta-og-desc, #meta-tw-desc', EN.meta_desc],
    ['#meta-og-url, #meta-tw-url', EN.og_url],
    ['#meta-og-title, #meta-tw-title', EN.og_title],
    ['#meta-og-locale', EN.og_locale],
    ['#meta-og-locale-alt', EN.og_locale_alt],
    ['#meta-og-image, #meta-og-image-secure, #meta-tw-image', EN.og_image],
    ['#meta-og-image-alt, #meta-tw-image-alt', EN.og_image_alt]
  ]) {
    rewriter.on(selector, { element(el) { el.setAttribute('content', content); } });
  }

  return rewriter.transform(response);
}

export async function onRequestHead(context) {
  const response = await onRequestGet(context);
  if (response.body && typeof response.body.cancel === 'function') {
    const cancellation = Promise.resolve(response.body.cancel()).catch(() => {});
    if (typeof context.waitUntil === 'function') context.waitUntil(cancellation);
  }
  return new Response(null, {
    status: response.status,
    statusText: response.statusText,
    headers: response.headers
  });
}
