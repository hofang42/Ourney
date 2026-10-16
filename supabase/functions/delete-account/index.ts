// delete-account (FR-A4, NFR-4): permanently deletes the caller's account.
//   1. authenticate the caller from their own JWT (Authorization: Bearer <access token>)
//   2. remove every storage object of the user (public.account_media_paths lists the real
//      objects in bucket `media`: avatars/{uid}/*, checkins/*/{uid}/*, and all media of
//      journeys that die with the account). Repeated until empty, so retries are safe.
//   3. auth.admin.deleteUser -> cascades to public.profiles; the profiles BEFORE DELETE trigger
//      hands group ownership to the earliest joined member / archives empty groups and
//      deletes journeys nobody else is active in. Everything else cascades.
// The service key comes only from the function environment.
import { adminClient, chunk, json } from "../_shared/admin.ts";

const MAX_ROUNDS = 20;

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405, { Allow: "POST" });

  const auth = req.headers.get("Authorization") ?? "";
  const token = auth.startsWith("Bearer ") ? auth.slice(7).trim() : "";
  if (!token) return json({ error: "unauthenticated" }, 401);

  const admin = adminClient();
  const { data: userData, error: userError } = await admin.auth.getUser(token);
  const userId = userData?.user?.id;
  if (userError || !userId) return json({ error: "unauthenticated" }, 401);

  let removed = 0;
  for (let round = 0; ; round++) {
    const { data: paths, error } = await admin.rpc("account_media_paths", { p_user: userId });
    if (error) {
      console.error("account_media_paths failed", error.message);
      return json({ error: "storage_listing_failed" }, 500);
    }
    const list = (paths ?? []) as string[];
    if (list.length === 0) break;
    if (round >= MAX_ROUNDS) return json({ error: "storage_cleanup_incomplete" }, 500);
    for (const part of chunk(list, 100)) {
      const { error: removeError } = await admin.storage.from("media").remove(part);
      if (removeError) {
        console.error("storage remove failed", removeError.message);
        return json({ error: "storage_cleanup_failed" }, 500);
      }
      removed += part.length;
    }
  }

  const { error: deleteError } = await admin.auth.admin.deleteUser(userId);
  if (deleteError) {
    console.error("deleteUser failed", deleteError.message);
    return json({ error: "delete_failed" }, 500);
  }
  return json({ deleted: true, removed_objects: removed });
});
