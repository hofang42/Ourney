// Cloudflare Pages Function: /join/:code
// Shares the server-side squad preview and HTMLRewriter Open Graph / Twitter tag handler with /j/:code.

import { handleSquadInviteRequest } from '../j/[code].js';

export async function onRequestGet(context) {
  return handleSquadInviteRequest(context, 'join');
}

export async function onRequestHead(context) {
  const res = await handleSquadInviteRequest(context, 'join');
  return new Response(null, {
    status: res.status,
    statusText: res.statusText,
    headers: res.headers
  });
}
