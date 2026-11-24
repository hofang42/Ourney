-- 0022_landing_waitlist: beta waitlist of the landing page (apps/landing, section #beta).
--
-- The landing form posts to the waitlist-signup Edge Function, which calls
-- public.waitlist_signup() with the service key and then sends the thank-you email (Resend).
-- Service role only: both tables live in the private schema with RLS on and no policies, nothing
-- is granted to anon or authenticated, and the RPCs are executable by service_role only.
--
-- Reading the list: Supabase Dashboard -> Table Editor -> schema "private" -> table "waitlist"
-- (or SQL Editor: select * from private.waitlist order by created_at desc). See
-- docs/runbooks/landing-waitlist.md.
--
-- Privacy: no raw IP is stored. Rate limiting keys on sha256 of the IP computed by the function;
-- attempt rows older than one day are deleted on the next signup.

create table private.waitlist (
  id uuid primary key default gen_random_uuid(),
  email text not null unique
    check (length(email) between 3 and 254 and email = lower(btrim(email)) and position('@' in email) > 1),
  lang text not null default 'vi' check (lang in ('vi', 'en')),
  platforms text[] not null default array['ios', 'android']::text[]
    check (platforms <@ array['ios', 'android']::text[]),
  source text check (source is null or length(source) <= 64),
  created_at timestamptz not null default now(),
  -- Thank-you email: sent_at set on success, error kept (truncated) on failure for a manual resend.
  confirmation_sent_at timestamptz,
  confirmation_error text check (confirmation_error is null or length(confirmation_error) <= 500)
);
create index waitlist_created_at_idx on private.waitlist (created_at desc);
alter table private.waitlist enable row level security;
revoke all on private.waitlist from public, anon, authenticated;
grant select, insert, update, delete on private.waitlist to service_role;

create table private.waitlist_attempts (
  ip_hash text not null check (length(ip_hash) = 64),
  created_at timestamptz not null default now()
);
create index waitlist_attempts_ip_idx on private.waitlist_attempts (ip_hash, created_at);
alter table private.waitlist_attempts enable row level security;
revoke all on private.waitlist_attempts from public, anon, authenticated;
grant select, insert, update, delete on private.waitlist_attempts to service_role;

-- Adds an email to the waitlist. Returns {"status": "created", "id": ...} for a new email,
-- {"status": "exists"} when it is already there (the caller then sends nothing, so the form can't
-- be used to mail-bomb someone), {"status": "rate_limited"} after 5 attempts from the same IP hash
-- within an hour, {"status": "invalid"} for input the table would reject.
create function public.waitlist_signup(
  p_email text,
  p_lang text default 'vi',
  p_platforms text[] default array['ios', 'android']::text[],
  p_source text default null,
  p_ip_hash text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_email text := lower(btrim(coalesce(p_email, '')));
  v_lang text := case when p_lang = 'en' then 'en' else 'vi' end;
  v_platforms text[];
  v_id uuid;
begin
  if length(v_email) not between 3 and 254 or v_email !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' then
    return jsonb_build_object('status', 'invalid');
  end if;

  select coalesce(array_agg(distinct p order by p), array['ios', 'android']::text[])
    into v_platforms
    from unnest(coalesce(p_platforms, array[]::text[])) as p
   where p in ('ios', 'android');

  if p_ip_hash is not null then
    if length(p_ip_hash) <> 64 then
      return jsonb_build_object('status', 'invalid');
    end if;
    delete from private.waitlist_attempts where created_at < now() - interval '1 day';
    if (select count(*) from private.waitlist_attempts
         where ip_hash = p_ip_hash and created_at > now() - interval '1 hour') >= 5 then
      return jsonb_build_object('status', 'rate_limited');
    end if;
    insert into private.waitlist_attempts (ip_hash) values (p_ip_hash);
  end if;

  insert into private.waitlist (email, lang, platforms, source)
  values (v_email, v_lang, v_platforms, nullif(left(btrim(coalesce(p_source, '')), 64), ''))
  on conflict (email) do nothing
  returning id into v_id;

  if v_id is null then
    return jsonb_build_object('status', 'exists');
  end if;
  return jsonb_build_object('status', 'created', 'id', v_id);
end;
$$;

-- Records the outcome of the thank-you email (p_error null = sent).
create function public.waitlist_mark_confirmation(p_id uuid, p_error text default null)
returns void
language sql
security definer
set search_path = ''
as $$
  update private.waitlist
     set confirmation_sent_at = case when p_error is null then now() else confirmation_sent_at end,
         confirmation_error = left(p_error, 500)
   where id = p_id;
$$;

revoke all on function
  public.waitlist_signup(text, text, text[], text, text),
  public.waitlist_mark_confirmation(uuid, text)
from public, anon, authenticated;
grant execute on function
  public.waitlist_signup(text, text, text[], text, text),
  public.waitlist_mark_confirmation(uuid, text)
to service_role;
