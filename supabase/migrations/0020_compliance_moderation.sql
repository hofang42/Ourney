-- 0020_compliance_moderation: App Store & Google Play compliance backend fixes (Batch 4).
--   CS-02  `public.report_content` validates and stores `target_message_id` (even when `p_user`
--          is also passed by the client), hides reported messages from the reporter across
--          `private.can_read_message`, `private.has_reported_message`, `my_conversations`,
--          `inbox_counts`, and `storage.objects` (`messages_select`).
--   CS-03  Server-side bilingual (vi + en + teencode/leet) objectionable-content filter backed by
--          `private.objectionable_words` (updatable without deploys via `service_role` or
--          `public.upsert_objectionable_word`), enforced on UGC write paths (`profiles`,
--          `journeys`, `check_ins`, `check_in_extras`, `messages`) with error `content_policy`
--          (SQLSTATE 23514).
--          24-hour moderation SLA queue: `due_at = created_at + interval '24 hours'` on
--          `public.reports` and `public.moderation_queue`, auto-quarantine (`moderated_at`)
--          after N >= 2 distinct open reports (or 1 nudity/self_harm report on a public link),
--          moderator view `private.moderation_queue_due`, and service-role RPCs
--          `public.list_moderation_queue`, `public.claim_moderation_notifications`,
--          `public.resolve_moderation_item`, and `private.moderate_queue_item`.
--   CS-05  `public.account_has_password` (service_role) so `delete-account` Edge Function can
--          re-authenticate password accounts and the App Review demo account via password as
--          well as 6-digit OTP while keeping FS-02 and FS-08 intact.
-- Idempotent (create or replace, drop if exists, if not exists).

-- ---------------------------------------------------------------------------
-- 1. CS-03: Objectionable-content word list table & text filter functions
-- ---------------------------------------------------------------------------
create table if not exists private.objectionable_words (
  term text primary key check (char_length(btrim(term)) between 2 and 64),
  lang text not null default 'vi' check (lang in ('vi', 'en', 'any')),
  match_mode text not null default 'word' check (match_mode in ('word', 'substring', 'diacritic_word')),
  category text not null default 'profanity'
    check (category in ('profanity', 'slur', 'sexual', 'csae', 'self_harm', 'violence')),
  enabled boolean not null default true,
  created_at timestamptz not null default now()
);

alter table private.objectionable_words enable row level security;
revoke all on private.objectionable_words from public, anon, authenticated;
grant select, insert, update, delete on private.objectionable_words to service_role;

insert into private.objectionable_words (term, lang, match_mode, category)
values
  -- Vietnamese single-word terms requiring diacritics (avoids false positives on lon/cac/buoi/du)
  ('địt', 'vi', 'diacritic_word', 'profanity'),
  ('lồn', 'vi', 'diacritic_word', 'profanity'),
  ('cặc', 'vi', 'diacritic_word', 'profanity'),
  ('buồi', 'vi', 'diacritic_word', 'profanity'),
  ('đéo', 'vi', 'diacritic_word', 'profanity'),
  ('đĩ', 'vi', 'diacritic_word', 'slur'),
  ('chịch', 'vi', 'diacritic_word', 'sexual'),
  ('nứng', 'vi', 'diacritic_word', 'sexual'),
  -- Vietnamese unaccented phrases & teencode tokens (matched on word boundaries)
  ('dit me', 'vi', 'word', 'profanity'),
  ('dit con me', 'vi', 'word', 'profanity'),
  ('dit cha', 'vi', 'word', 'profanity'),
  ('dit ba', 'vi', 'word', 'profanity'),
  ('du ma', 'vi', 'word', 'profanity'),
  ('du me', 'vi', 'word', 'profanity'),
  ('deo me', 'vi', 'word', 'profanity'),
  ('con di', 'vi', 'word', 'slur'),
  ('vai lon', 'vi', 'word', 'profanity'),
  ('cai lon', 'vi', 'word', 'profanity'),
  ('mat lon', 'vi', 'word', 'profanity'),
  ('con cac', 'vi', 'word', 'profanity'),
  ('cuc cac', 'vi', 'word', 'profanity'),
  ('dau buoi', 'vi', 'word', 'profanity'),
  ('bu cu', 'vi', 'word', 'sexual'),
  ('mut cu', 'vi', 'word', 'sexual'),
  ('bu lon', 'vi', 'word', 'sexual'),
  ('vet mang', 'vi', 'word', 'sexual'),
  ('lam tinh', 'vi', 'word', 'sexual'),
  ('chat sex', 'vi', 'word', 'sexual'),
  ('call sex', 'vi', 'word', 'sexual'),
  ('ban dam', 'vi', 'word', 'sexual'),
  ('mua dam', 'vi', 'word', 'sexual'),
  ('hiep dam', 'vi', 'word', 'violence'),
  ('au dam', 'vi', 'word', 'csae'),
  ('loan luan', 'vi', 'word', 'sexual'),
  ('dm', 'vi', 'word', 'profanity'),
  ('dmm', 'vi', 'word', 'profanity'),
  ('dcm', 'vi', 'word', 'profanity'),
  ('dcmm', 'vi', 'word', 'profanity'),
  ('dkm', 'vi', 'word', 'profanity'),
  ('dkmm', 'vi', 'word', 'profanity'),
  ('vcl', 'vi', 'word', 'profanity'),
  ('vkl', 'vi', 'word', 'profanity'),
  ('vl', 'vi', 'word', 'profanity'),
  ('clm', 'vi', 'word', 'profanity'),
  ('clgt', 'vi', 'word', 'profanity'),
  -- Vietnamese compound substrings (caught even inside concatenated handles/text)
  ('ditme', 'vi', 'substring', 'profanity'),
  ('ditconme', 'vi', 'substring', 'profanity'),
  ('vailon', 'vi', 'substring', 'profanity'),
  ('cailon', 'vi', 'substring', 'profanity'),
  ('concac', 'vi', 'substring', 'profanity'),
  ('daubuoi', 'vi', 'substring', 'profanity'),
  ('hiepdam', 'vi', 'substring', 'violence'),
  ('audam', 'vi', 'substring', 'csae'),
  ('loanluan', 'vi', 'substring', 'sexual'),
  -- English profanity, slurs, sexual solicitation, CSAE & self-harm terms
  ('fuck', 'en', 'word', 'profanity'),
  ('fucker', 'en', 'word', 'profanity'),
  ('fucking', 'en', 'word', 'profanity'),
  ('fucked', 'en', 'word', 'profanity'),
  ('motherfucker', 'en', 'word', 'profanity'),
  ('shit', 'en', 'word', 'profanity'),
  ('bullshit', 'en', 'word', 'profanity'),
  ('bitch', 'en', 'word', 'profanity'),
  ('bitches', 'en', 'word', 'profanity'),
  ('cunt', 'en', 'word', 'profanity'),
  ('cunts', 'en', 'word', 'profanity'),
  ('dick', 'en', 'word', 'profanity'),
  ('dickhead', 'en', 'word', 'profanity'),
  ('cock', 'en', 'word', 'profanity'),
  ('pussy', 'en', 'word', 'sexual'),
  ('whore', 'en', 'word', 'slur'),
  ('slut', 'en', 'word', 'slur'),
  ('bastard', 'en', 'word', 'profanity'),
  ('asshole', 'en', 'word', 'profanity'),
  ('nigger', 'en', 'word', 'slur'),
  ('nigga', 'en', 'word', 'slur'),
  ('faggot', 'en', 'word', 'slur'),
  ('fag', 'en', 'word', 'slur'),
  ('retard', 'en', 'word', 'slur'),
  ('chink', 'en', 'word', 'slur'),
  ('kike', 'en', 'word', 'slur'),
  ('spic', 'en', 'word', 'slur'),
  ('rape', 'en', 'word', 'violence'),
  ('rapist', 'en', 'word', 'violence'),
  ('pedophile', 'en', 'word', 'csae'),
  ('pedo', 'en', 'word', 'csae'),
  ('child porn', 'en', 'word', 'csae'),
  ('child abuse', 'en', 'word', 'csae'),
  ('csam', 'en', 'word', 'csae'),
  ('kill yourself', 'en', 'word', 'self_harm'),
  ('kys', 'en', 'word', 'self_harm'),
  -- English / global unambiguous substrings
  ('motherfuck', 'en', 'substring', 'profanity'),
  ('nigger', 'en', 'substring', 'slur'),
  ('faggot', 'en', 'substring', 'slur'),
  ('childporn', 'en', 'substring', 'csae'),
  ('pedophil', 'en', 'substring', 'csae'),
  ('pornhub', 'any', 'substring', 'sexual'),
  ('xvideos', 'any', 'substring', 'sexual'),
  ('xnxx', 'any', 'substring', 'sexual')
on conflict (term) do update
  set lang = excluded.lang,
      match_mode = excluded.match_mode,
      category = excluded.category;

create or replace function private.contains_objectionable_text(p_text text) returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_lower text;
  v_diacritic_words text;
  v_folded text;
  v_alpha_words text;
  v_collapsed_words text;
  v_leet_words text;
  v_compact_raw text;
  v_compact_leet text;
begin
  if p_text is null or btrim(p_text) = '' then
    return false;
  end if;

  v_lower := lower(p_text);
  v_diacritic_words := ' ' || btrim(regexp_replace(
    v_lower,
    '[^a-zàáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ]+',
    ' ',
    'g'
  )) || ' ';

  v_folded := translate(
    v_lower,
    'àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ',
    'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiioooooooooooooooooouuuuuuuuuuuyyyyyd'
  );

  v_alpha_words := ' ' || btrim(regexp_replace(v_folded, '[^a-z]+', ' ', 'g')) || ' ';
  v_collapsed_words := ' ' || btrim(regexp_replace(
    regexp_replace(v_folded, '([a-z])[\._\-]+(?=[a-z])', '\1', 'g'),
    '[^a-z]+',
    ' ',
    'g'
  )) || ' ';
  v_leet_words := ' ' || btrim(regexp_replace(
    translate(v_folded, '01345@$', 'oieasas'),
    '[^a-z]+',
    ' ',
    'g'
  )) || ' ';
  v_compact_raw := regexp_replace(v_folded, '[^a-z0-9]+', '', 'g');
  v_compact_leet := regexp_replace(translate(v_folded, '01345@$', 'oieasas'), '[^a-z0-9]+', '', 'g');

  return exists (
    select 1
      from private.objectionable_words w
     where w.enabled
       and (
         (w.match_mode = 'diacritic_word' and position(' ' || w.term || ' ' in v_diacritic_words) > 0)
         or (w.match_mode = 'word' and (
              position(' ' || w.term || ' ' in v_alpha_words) > 0
              or position(' ' || w.term || ' ' in v_collapsed_words) > 0
              or position(' ' || w.term || ' ' in v_leet_words) > 0
         ))
         or (w.match_mode = 'substring' and (
              position(w.term in v_compact_raw) > 0
              or position(w.term in v_compact_leet) > 0
         ))
       )
  );
end;
$$;

create or replace function private.assert_clean_text(p_text text) returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if private.contains_objectionable_text(p_text) then
    raise exception 'content_policy' using errcode = '23514';
  end if;
end;
$$;

revoke all on function private.contains_objectionable_text(text), private.assert_clean_text(text) from public, anon;
grant execute on function private.contains_objectionable_text(text), private.assert_clean_text(text) to authenticated, service_role;

-- Service-role helper to add, update, or disable terms in private.objectionable_words without a deploy.
create or replace function public.upsert_objectionable_word(
  p_term text,
  p_lang text default 'vi',
  p_match_mode text default 'word',
  p_category text default 'profanity',
  p_enabled boolean default true
) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_term text := lower(btrim(coalesce(p_term, '')));
begin
  if char_length(v_term) not between 2 and 64
     or coalesce(p_lang, '') not in ('vi', 'en', 'any')
     or coalesce(p_match_mode, '') not in ('word', 'substring', 'diacritic_word')
     or coalesce(p_category, '') not in ('profanity', 'slur', 'sexual', 'csae', 'self_harm', 'violence') then
    raise exception 'invalid';
  end if;
  insert into private.objectionable_words (term, lang, match_mode, category, enabled)
  values (v_term, p_lang, p_match_mode, p_category, coalesce(p_enabled, true))
  on conflict (term) do update
    set lang = excluded.lang,
        match_mode = excluded.match_mode,
        category = excluded.category,
        enabled = excluded.enabled;
end;
$$;

revoke all on function public.upsert_objectionable_word(text, text, text, text, boolean) from public, anon, authenticated;
grant execute on function public.upsert_objectionable_word(text, text, text, text, boolean) to service_role;

-- ---------------------------------------------------------------------------
-- 2. CS-03: Enforce objectionable-content filter on UGC write paths
-- ---------------------------------------------------------------------------
create or replace function private.profiles_enforce_content_policy() returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' or new.username is distinct from old.username then
    perform private.assert_clean_text(new.username);
  end if;
  if tg_op = 'INSERT' or new.display_name is distinct from old.display_name then
    perform private.assert_clean_text(new.display_name);
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_enforce_content_policy on public.profiles;
create trigger profiles_enforce_content_policy
  before insert or update of username, display_name on public.profiles
  for each row execute function private.profiles_enforce_content_policy();

create or replace function private.journeys_enforce_content_policy() returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' or new.title is distinct from old.title then
    perform private.assert_clean_text(new.title);
  end if;
  if tg_op = 'INSERT' or new.story_title is distinct from old.story_title then
    perform private.assert_clean_text(new.story_title);
  end if;
  if tg_op = 'INSERT' or new.story_intro is distinct from old.story_intro then
    perform private.assert_clean_text(new.story_intro);
  end if;
  if tg_op = 'INSERT' or new.story_lessons is distinct from old.story_lessons then
    perform private.assert_clean_text(new.story_lessons);
  end if;
  if tg_op = 'INSERT' or new.couple_self_name is distinct from old.couple_self_name then
    perform private.assert_clean_text(new.couple_self_name);
  end if;
  if tg_op = 'INSERT' or new.couple_partner_name is distinct from old.couple_partner_name then
    perform private.assert_clean_text(new.couple_partner_name);
  end if;
  if tg_op = 'INSERT' or new.metric_name is distinct from old.metric_name then
    perform private.assert_clean_text(new.metric_name);
  end if;
  if tg_op = 'INSERT' or new.metric_unit is distinct from old.metric_unit then
    perform private.assert_clean_text(new.metric_unit);
  end if;
  if (tg_op = 'INSERT' or new.dna is distinct from old.dna) and new.dna is not null then
    perform private.assert_clean_text(new.dna ->> 'trophy');
    perform private.assert_clean_text(new.dna ->> 'place');
    perform private.assert_clean_text(new.dna ->> 'habit');
    perform private.assert_clean_text(new.dna ->> 'reason');
  end if;
  return new;
end;
$$;

drop trigger if exists journeys_enforce_content_policy on public.journeys;
create trigger journeys_enforce_content_policy
  before insert or update of title, story_title, story_intro, story_lessons,
                             couple_self_name, couple_partner_name, metric_name, metric_unit, dna
  on public.journeys
  for each row execute function private.journeys_enforce_content_policy();

create or replace function private.check_ins_enforce_content_policy() returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' or new.caption is distinct from old.caption then
    perform private.assert_clean_text(new.caption);
  end if;
  return new;
end;
$$;

drop trigger if exists check_ins_enforce_content_policy on public.check_ins;
create trigger check_ins_enforce_content_policy
  before insert or update of caption on public.check_ins
  for each row execute function private.check_ins_enforce_content_policy();

create or replace function private.check_in_extras_enforce_content_policy() returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (tg_op = 'INSERT' or new.extras is distinct from old.extras) and new.extras is not null then
    perform private.assert_clean_text(new.extras ->> 'mood');
    perform private.assert_clean_text(new.extras ->> 'place');
    perform private.assert_clean_text(new.extras ->> 'dish');
    perform private.assert_clean_text(new.extras ->> 'cook');
  end if;
  return new;
end;
$$;

drop trigger if exists check_in_extras_enforce_content_policy on public.check_in_extras;
create trigger check_in_extras_enforce_content_policy
  before insert or update of extras on public.check_in_extras
  for each row execute function private.check_in_extras_enforce_content_policy();

create or replace function private.messages_enforce_content_policy() returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' or new.body is distinct from old.body then
    perform private.assert_clean_text(new.body);
  end if;
  return new;
end;
$$;

drop trigger if exists messages_enforce_content_policy on public.messages;
create trigger messages_enforce_content_policy
  before insert or update of body on public.messages
  for each row execute function private.messages_enforce_content_policy();

revoke all on function
  private.profiles_enforce_content_policy(),
  private.journeys_enforce_content_policy(),
  private.check_ins_enforce_content_policy(),
  private.check_in_extras_enforce_content_policy(),
  private.messages_enforce_content_policy()
from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 3. CS-02 & CS-03: 24-hour moderation SLA (due_at = created_at + 24h),
--                   message reporting & auto-hide pending review
-- ---------------------------------------------------------------------------
alter table public.reports
  add column if not exists due_at timestamptz not null default (now() + interval '24 hours');

alter table public.moderation_queue
  add column if not exists due_at timestamptz not null default (now() + interval '24 hours'),
  add column if not exists notified_at timestamptz,
  add column if not exists resolution_note text check (resolution_note is null or char_length(resolution_note) <= 500);

alter table public.messages
  add column if not exists moderated_at timestamptz;

update public.reports
   set due_at = created_at + interval '24 hours'
 where due_at is distinct from created_at + interval '24 hours';

update public.moderation_queue
   set due_at = created_at + interval '24 hours'
 where due_at is distinct from created_at + interval '24 hours';

create or replace function private.set_moderation_due_at() returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.created_at is null then
    new.created_at := now();
  end if;
  new.due_at := new.created_at + interval '24 hours';
  return new;
end;
$$;

drop trigger if exists reports_set_due_at on public.reports;
create trigger reports_set_due_at
  before insert or update of created_at on public.reports
  for each row execute function private.set_moderation_due_at();

drop trigger if exists moderation_queue_set_due_at on public.moderation_queue;
create trigger moderation_queue_set_due_at
  before insert or update of created_at on public.moderation_queue
  for each row execute function private.set_moderation_due_at();

revoke all on function private.set_moderation_due_at() from public, anon, authenticated;

create index if not exists reports_due_idx
  on public.reports (due_at)
  where status = 'open' and deleted_at is null;

create index if not exists moderation_queue_due_idx
  on public.moderation_queue (due_at)
  where status = 'open';

create index if not exists moderation_queue_unnotified_idx
  on public.moderation_queue (created_at)
  where status = 'open' and notified_at is null;

create or replace function private.has_reported_message(p_message uuid) returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.reports r
     where r.target_message_id = p_message
       and r.reporter_id = (select auth.uid())
       and r.deleted_at is null
  );
$$;

create or replace function private.can_read_message(p_message uuid) returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.messages m
      join public.conversations c on c.id = m.conversation_id
     where m.id = p_message
       and m.deleted_at is null
       and m.moderated_at is null
       and (select auth.uid()) in (c.member_id, c.viewer_id)
       and not private.blocked_between(c.member_id, c.viewer_id)
       and m.created_at > coalesce(
             case when c.member_id = (select auth.uid()) then c.member_cleared_at else c.viewer_cleared_at end,
             '-infinity'::timestamptz)
       and not exists (select 1 from public.message_hides h
                        where h.message_id = m.id and h.user_id = (select auth.uid()))
       and not private.has_reported_message(m.id)
  );
$$;

revoke all on function private.has_reported_message(uuid), private.can_read_message(uuid) from public, anon;
grant execute on function private.has_reported_message(uuid), private.can_read_message(uuid) to authenticated, service_role;

create or replace function public.report_content(
  p_checkin uuid,
  p_user uuid,
  p_reason public.report_reason,
  p_note text default null,
  p_message uuid default null
) returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
  v_target_user uuid := p_user;
  v_id uuid;
  v_note text := left(nullif(btrim(p_note), ''), 500);
  v_open_reports int := 0;
  v_has_public_link boolean := false;
begin
  if (p_checkin is null and p_user is null and p_message is null) or p_reason is null then
    raise exception 'invalid';
  end if;
  if p_checkin is not null and p_message is not null then
    raise exception 'invalid';
  end if;
  perform 1 from public.profiles where id = uid and deleted_at is null for no key update;
  if not found then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  if p_message is not null then
    select m.sender_id into v_target_user
      from public.messages m
      join public.conversations c on c.id = m.conversation_id
     where m.id = p_message
       and m.deleted_at is null
       and m.moderated_at is null
       and uid in (c.member_id, c.viewer_id)
       and not private.blocked_between(c.member_id, c.viewer_id)
       and m.created_at > coalesce(
             case when c.member_id = uid then c.member_cleared_at else c.viewer_cleared_at end,
             '-infinity'::timestamptz)
       and not exists (select 1 from public.message_hides h
                        where h.message_id = m.id and h.user_id = uid);
    if v_target_user is null then
      raise exception 'not_found';
    end if;
    if p_user is not null and p_user <> v_target_user then
      raise exception 'invalid';
    end if;
  elsif p_checkin is not null then
    if not (
      private.can_see_checkin(p_checkin)
      or exists (
        select 1 from public.check_ins c
          join public.journeys j on j.id = c.journey_id
         where c.id = p_checkin
           and private.checkin_shareable(c.id)
           and not private.is_blocked_pair(c.user_id)
           and not private.is_blocked_pair(j.owner_id)
           and (private.has_active_share(j.id, uid) or j.public_token is not null)
      )
    ) then
      raise exception 'not_found';
    end if;
    select c.user_id, (j.public_token is not null)
      into v_target_user, v_has_public_link
      from public.check_ins c
      join public.journeys j on j.id = c.journey_id
     where c.id = p_checkin;
    if p_user is not null and p_user <> v_target_user then
      raise exception 'invalid';
    end if;
  elsif p_user = uid
     or not (exists (
       select 1 from public.memberships a
         join public.memberships b on b.journey_id = a.journey_id
        where a.user_id = uid and b.user_id = p_user
          and a.status = 'active' and b.status = 'active')
       or private.can_see_profile(p_user)) then
    raise exception 'not_found';
  end if;

  if v_target_user = uid then
    raise exception 'invalid';
  end if;

  -- FS-38: deduplicate repeated open reports on the same target by the same reporter.
  select r.id into v_id
    from public.reports r
   where r.reporter_id = uid
     and r.deleted_at is null
     and r.status = 'open'
     and r.target_checkin_id is not distinct from p_checkin
     and r.target_message_id is not distinct from p_message
     and r.target_user_id is not distinct from v_target_user
   order by r.created_at desc
   limit 1;
  if v_id is not null then
    return v_id;
  end if;

  -- If a prior report on this specific message or check-in was already resolved/dismissed,
  -- the content remains hidden from the caller (FR-F2) and cannot be reported again.
  if (p_message is not null and not private.can_read_message(p_message))
     or (p_checkin is not null and private.has_reported(p_checkin)) then
    raise exception 'not_found';
  end if;

  if (select count(*) from public.reports
       where reporter_id = uid and created_at > now() - interval '24 hours') >= 20 then
    raise exception 'rate_limited';
  end if;

  insert into public.reports (
    reporter_id, target_checkin_id, target_user_id, target_message_id, reason, note, due_at
  )
  values (
    uid, p_checkin, v_target_user, p_message, p_reason, v_note, now() + interval '24 hours'
  )
  returning id into v_id;

  insert into public.moderation_queue (
    kind, report_id, actor_id, target_user_id, target_checkin_id, target_message_id, reason, note, due_at
  )
  values (
    'report', v_id, uid, v_target_user, p_checkin, p_message, p_reason, v_note, now() + interval '24 hours'
  );

  -- CS-03: auto-hide (quarantine pending moderator review) after N >= 2 distinct open reports
  -- on the same check-in or message (or immediately when nudity/self_harm is reported on a public link).
  if p_checkin is not null then
    select count(distinct r.reporter_id)::int into v_open_reports
      from public.reports r
     where r.target_checkin_id = p_checkin
       and r.deleted_at is null
       and r.status = 'open';
    if v_open_reports >= 2
       or (v_has_public_link and p_reason in ('nudity', 'self_harm')) then
      update public.check_ins
         set moderated_at = coalesce(moderated_at, now()),
             deleted_at = coalesce(deleted_at, now())
       where id = p_checkin
         and (moderated_at is null or deleted_at is null);
    end if;
  elsif p_message is not null then
    select count(distinct r.reporter_id)::int into v_open_reports
      from public.reports r
     where r.target_message_id = p_message
       and r.deleted_at is null
       and r.status = 'open';
    if v_open_reports >= 2 then
      update public.messages
         set moderated_at = coalesce(moderated_at, now()),
             deleted_at = coalesce(deleted_at, now())
       where id = p_message
         and (moderated_at is null or deleted_at is null);
    end if;
  end if;

  return v_id;
end;
$$;

revoke all on function public.report_content(uuid, uuid, public.report_reason, text, uuid) from public, anon;
grant execute on function public.report_content(uuid, uuid, public.report_reason, text, uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 4. CS-03: Moderator view & service-role RPCs for the 24-hour moderation queue
-- ---------------------------------------------------------------------------
create or replace view private.moderation_queue_due as
select
  q.id,
  q.kind,
  q.report_id,
  q.status,
  q.reason,
  q.note,
  q.created_at,
  q.due_at,
  q.notified_at,
  q.handled_at,
  q.resolution_note,
  (q.status = 'open' and q.due_at <= now()) as overdue,
  round((extract(epoch from (q.due_at - now())) / 3600.0)::numeric, 2) as hours_remaining,
  q.actor_id,
  ap.username as actor_username,
  q.target_user_id,
  tp.username as target_username,
  tp.display_name as target_display_name,
  q.target_checkin_id,
  ci.caption as checkin_caption,
  ci.photo_path as checkin_photo_path,
  ci.moderated_at as checkin_moderated_at,
  q.target_message_id,
  msg.body as message_body,
  msg.media_path as message_media_path,
  msg.moderated_at as message_moderated_at,
  (
    select count(distinct r.reporter_id)::int
      from public.reports r
     where r.deleted_at is null
       and r.status = 'open'
       and (
         (q.target_checkin_id is not null and r.target_checkin_id = q.target_checkin_id)
         or (q.target_message_id is not null and r.target_message_id = q.target_message_id)
         or (q.target_checkin_id is null and q.target_message_id is null
             and q.target_user_id is not null and r.target_user_id = q.target_user_id
             and r.target_checkin_id is null and r.target_message_id is null)
       )
  ) as distinct_open_reporters
from public.moderation_queue q
left join public.profiles ap on ap.id = q.actor_id
left join public.profiles tp on tp.id = q.target_user_id
left join public.check_ins ci on ci.id = q.target_checkin_id
left join public.messages msg on msg.id = q.target_message_id;

revoke all on private.moderation_queue_due from public, anon, authenticated;
grant select on private.moderation_queue_due to service_role;

create or replace function public.list_moderation_queue(
  p_status text default 'open',
  p_limit int default 100
) returns setof json
language sql
stable
security definer
set search_path = ''
as $$
  select row_to_json(v)
    from (
      select *
        from private.moderation_queue_due d
       where p_status is null or p_status = 'all' or d.status = p_status
       order by
         case when d.status = 'open' then 0 else 1 end,
         d.due_at asc,
         d.created_at asc,
         d.id asc
       limit greatest(1, least(coalesce(p_limit, 100), 500))
    ) v;
$$;

create or replace function public.claim_moderation_notifications(p_limit int default 50)
returns setof json
language plpgsql
security definer
set search_path = ''
as $$
begin
  return query
  with claimed as (
    update public.moderation_queue q
       set notified_at = now()
     where q.id in (
       select mq.id
         from public.moderation_queue mq
        where mq.status = 'open'
          and mq.notified_at is null
        order by mq.due_at asc, mq.created_at asc, mq.id asc
        limit greatest(1, least(coalesce(p_limit, 50), 200))
        for update skip locked
     )
    returning q.id
  )
  select row_to_json(d)
    from private.moderation_queue_due d
    join claimed c on c.id = d.id
   order by d.due_at asc, d.created_at asc, d.id asc;
end;
$$;

create or replace function private.moderate_queue_item(
  p_queue_id uuid,
  p_action text,
  p_note text default null
) returns json
language plpgsql
security definer
set search_path = ''
as $$
declare
  q public.moderation_queue%rowtype;
  v_action text := lower(btrim(coalesce(p_action, '')));
  v_note text := left(nullif(btrim(p_note), ''), 500);
  v_new_status text;
begin
  if p_queue_id is null or v_action not in ('dismiss', 'remove_content', 'action', 'ban_user') then
    raise exception 'invalid';
  end if;

  select * into q from public.moderation_queue where id = p_queue_id for update;
  if not found then
    raise exception 'not_found';
  end if;

  v_new_status := case when v_action = 'dismiss' then 'dismissed' else 'actioned' end;

  update public.moderation_queue
     set status = v_new_status,
         handled_at = now(),
         resolution_note = coalesce(v_note, resolution_note)
   where id = q.id
  returning * into q;

  if q.report_id is not null then
    update public.reports set status = v_new_status where id = q.report_id;
  end if;

  if q.target_checkin_id is not null then
    update public.reports
       set status = v_new_status
     where target_checkin_id = q.target_checkin_id and status = 'open';
    update public.moderation_queue
       set status = v_new_status,
           handled_at = coalesce(handled_at, now()),
           resolution_note = coalesce(resolution_note, v_note)
     where target_checkin_id = q.target_checkin_id and status = 'open';
  end if;

  if q.target_message_id is not null then
    update public.reports
       set status = v_new_status
     where target_message_id = q.target_message_id and status = 'open';
    update public.moderation_queue
       set status = v_new_status,
           handled_at = coalesce(handled_at, now()),
           resolution_note = coalesce(resolution_note, v_note)
     where target_message_id = q.target_message_id and status = 'open';
  end if;

  if v_action = 'dismiss' then
    -- Restore auto-quarantined content if no other actioned report holds it.
    if q.target_checkin_id is not null then
      update public.check_ins
         set moderated_at = null,
             deleted_at = case when hidden_by_leave then deleted_at else null end
       where id = q.target_checkin_id
         and moderated_at is not null;
    end if;
    if q.target_message_id is not null then
      update public.messages
         set moderated_at = null,
             deleted_at = null
       where id = q.target_message_id
         and moderated_at is not null;
    end if;
  else
    -- remove_content / action / ban_user: permanently moderate the reported check-in or message.
    if q.target_checkin_id is not null then
      update public.check_ins
         set moderated_at = coalesce(moderated_at, now()),
             deleted_at = coalesce(deleted_at, now())
       where id = q.target_checkin_id;
    end if;
    if q.target_message_id is not null then
      update public.messages
         set moderated_at = coalesce(moderated_at, now()),
             deleted_at = coalesce(deleted_at, now())
       where id = q.target_message_id;
    end if;

    if v_action = 'ban_user' and q.target_user_id is not null then
      update public.profiles
         set deleted_at = coalesce(deleted_at, now())
       where id = q.target_user_id;
      update public.check_ins
         set moderated_at = coalesce(moderated_at, now()),
             deleted_at = coalesce(deleted_at, now())
       where user_id = q.target_user_id
         and (moderated_at is null or deleted_at is null);
      update public.messages
         set moderated_at = coalesce(moderated_at, now()),
             deleted_at = coalesce(deleted_at, now())
       where sender_id = q.target_user_id
         and (moderated_at is null or deleted_at is null);
      update public.journeys
         set public_token = null,
             visibility = case when kind = 'solo' then 'private'::public.journey_visibility else visibility end
       where owner_id = q.target_user_id
         and public_token is not null;
      update public.reports
         set status = 'actioned'
       where target_user_id = q.target_user_id and status = 'open';
      update public.moderation_queue
         set status = 'actioned',
             handled_at = coalesce(handled_at, now()),
             resolution_note = coalesce(resolution_note, v_note)
       where target_user_id = q.target_user_id and status = 'open';
    end if;
  end if;

  return json_build_object(
    'id', q.id,
    'status', q.status,
    'action', v_action,
    'handled_at', q.handled_at,
    'target_user_id', q.target_user_id,
    'target_checkin_id', q.target_checkin_id,
    'target_message_id', q.target_message_id
  );
end;
$$;

create or replace function public.resolve_moderation_item(
  p_queue_id uuid,
  p_action text,
  p_note text default null
) returns json
language sql
security definer
set search_path = ''
as $$
  select private.moderate_queue_item(p_queue_id, p_action, p_note);
$$;

-- ---------------------------------------------------------------------------
-- 5. CS-05: Password account detection for delete-account re-authentication
-- ---------------------------------------------------------------------------
create or replace function public.account_has_password(p_user uuid) returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((
    select u.encrypted_password is not null and btrim(u.encrypted_password) <> ''
      from auth.users u
     where u.id = p_user
  ), false);
$$;

revoke all on function
  public.list_moderation_queue(text, int),
  public.claim_moderation_notifications(int),
  private.moderate_queue_item(uuid, text, text),
  public.resolve_moderation_item(uuid, text, text),
  public.account_has_password(uuid)
from public, anon, authenticated;

grant execute on function
  public.list_moderation_queue(text, int),
  public.claim_moderation_notifications(int),
  private.moderate_queue_item(uuid, text, text),
  public.resolve_moderation_item(uuid, text, text),
  public.account_has_password(uuid)
to service_role;
