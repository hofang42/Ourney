import { handleAutoReply, type Env } from './autoreply';

export default {
  async email(message: ForwardableEmailMessage, env: Env): Promise<void> {
    // Forward first: the owner must get the mail even if the reply fails.
    // A forward error is not caught, so Cloudflare reports it and the
    // sender's server sees a failure instead of a silent drop.
    await message.forward(env.FORWARD_TO);

    try {
      const outcome = await handleAutoReply(message, env);
      console.log(JSON.stringify({ autoreply: outcome }));
    } catch (error) {
      // Log the reason only; never the sender's address or the mail body.
      const reason = error instanceof Error ? error.message : String(error);
      console.error(JSON.stringify({ autoreply: 'failed', reason }));
    }
  },
} satisfies ExportedHandler<Env>;
