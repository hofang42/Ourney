// Cloudflare Pages Function: /join/:code
// Shares the server-side squad preview and HTMLRewriter Open Graph / Twitter tag handler with /j/:code.

import { handleSquadInviteRequest } from '../j/[code].js';

export async function onRequestGet(context) {
  return handleSquadInviteRequest(context, 'join');
}
