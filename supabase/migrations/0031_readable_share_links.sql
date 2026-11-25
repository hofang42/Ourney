-- Keep the ACCESS EXCLUSIVE lock to metadata changes. Existing rows keep
-- their opaque tokens and get neutral aliases on the first owner link action.
alter table public.journeys
  add column public_slug text,
  add constraint journeys_public_slug_check check (
    public_slug is null or (
      public_token is not null and char_length(public_slug) <= 40
      and public_slug collate "C" ~ '^[a-z0-9]+(-[a-z0-9]+)*-[a-z2-7]{16}$'
    )
  ) not valid;
