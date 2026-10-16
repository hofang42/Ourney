-- 0003_storage: private bucket `media` + path-based policies.
--   checkins/{journey_id}/{user_id}/{checkin_id}.jpg  (and {checkin_id}_t.jpg thumbnails)
--   avatars/{user_id}/{uuid}.jpg
-- Clients only ever receive signed URLs (TTL 1h).

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('media', 'media', false, 10485760, array['image/jpeg'])
on conflict (id) do update
  set public = false,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- Read: own check-in media; otherwise active members of the journey, for authors who are
-- still active members and not blocked either way (see public.can_read_checkin_media).
-- Avatars are readable by any authenticated user (profiles are).
create policy media_select on storage.objects for select to authenticated
using (
  bucket_id = 'media'
  and (
    (
      (storage.foldername(name))[1] = 'checkins'
      and array_length(storage.foldername(name), 1) = 3
      and public.can_read_checkin_media(
            public.try_uuid((storage.foldername(name))[2]),
            public.try_uuid((storage.foldername(name))[3]))
    )
    or (
      (storage.foldername(name))[1] = 'avatars'
      and array_length(storage.foldername(name), 1) = 2
    )
  )
);

-- Write: only into the caller's own {user_id} segment, with strict file names.
create policy media_insert on storage.objects for insert to authenticated
with check (
  bucket_id = 'media'
  and (
    (
      (storage.foldername(name))[1] = 'checkins'
      and array_length(storage.foldername(name), 1) = 3
      and (storage.foldername(name))[3] = (select auth.uid())::text
      and public.is_member(public.try_uuid((storage.foldername(name))[2]))
      and storage.filename(name) ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}(_t)?\.jpg$'
    )
    or (
      (storage.foldername(name))[1] = 'avatars'
      and array_length(storage.foldername(name), 1) = 2
      and (storage.foldername(name))[2] = (select auth.uid())::text
      and storage.filename(name) ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.jpg$'
    )
  )
);

create policy media_update on storage.objects for update to authenticated
using (
  bucket_id = 'media'
  and (
    ((storage.foldername(name))[1] = 'checkins'
      and (storage.foldername(name))[3] = (select auth.uid())::text
      and public.is_member(public.try_uuid((storage.foldername(name))[2])))
    or ((storage.foldername(name))[1] = 'avatars'
      and (storage.foldername(name))[2] = (select auth.uid())::text)
  )
)
with check (
  bucket_id = 'media'
  and (
    ((storage.foldername(name))[1] = 'checkins'
      and array_length(storage.foldername(name), 1) = 3
      and (storage.foldername(name))[3] = (select auth.uid())::text
      and public.is_member(public.try_uuid((storage.foldername(name))[2])))
    or ((storage.foldername(name))[1] = 'avatars'
      and array_length(storage.foldername(name), 1) = 2
      and (storage.foldername(name))[2] = (select auth.uid())::text)
  )
);

-- Delete: own objects only (a user may remove their own media even after leaving a group).
create policy media_delete on storage.objects for delete to authenticated
using (
  bucket_id = 'media'
  and (
    ((storage.foldername(name))[1] = 'checkins'
      and (storage.foldername(name))[3] = (select auth.uid())::text)
    or ((storage.foldername(name))[1] = 'avatars'
      and (storage.foldername(name))[2] = (select auth.uid())::text)
  )
);
