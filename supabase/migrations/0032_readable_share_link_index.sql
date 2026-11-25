-- Supabase CLI 2.121.0 runs this statement outside its migration batch.
-- Build before enabling alias writes in 0033 and allow ordinary writes during the scan.
create unique index concurrently journeys_public_slug_key on public.journeys (public_slug)
  where public_slug is not null;
