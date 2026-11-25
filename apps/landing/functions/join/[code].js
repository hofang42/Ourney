// Cloudflare Pages Function: /join/:code
// Shares the server-side squad preview and HTMLRewriter Open Graph / Twitter tag handler with /j/:code.

import { handleSquadInviteRequest, handleSquadInviteHead } from '../j/[code].js';

export async function onRequestGet(context) {
  return handleSquadInviteRequest(context, 'join');
}

export async function onRequestHead(context) {
  return handleSquadInviteHead(context, 'join');
}
