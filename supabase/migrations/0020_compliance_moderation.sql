-- 0020_compliance_moderation: App Store & Google Play compliance backend fixes (Batch 4).
--   CS-02  `public.report_content` validates and stores `target_message_id` (even when `p_user`
--          is also passed by the client), hides reported messages from the reporter across
--          `private.can_read_message`, `private.has_reported_message`, `my_conversations`,
--          `inbox_counts`, and `storage.objects` (`messages_select`).
--   CS-03  Server-side bilingual (vi + en + teencode/leet) objectionable-content filter backed by
--          `private.objectionable_words` (updatable without deploys via `service_role`,
--          `public.upsert_objectionable_word`, or `public.set_objectionable_word_enabled`),
--          enforced on UGC write paths (`profiles`, `journeys`, `check_ins`, `check_in_extras`,
--          `messages`) with error `content_policy` (SQLSTATE 23514).
--          24-hour moderation SLA queue: `due_at = created_at + interval '24 hours'` on
--          `public.reports` and `public.moderation_queue`, auto-quarantine (`moderated_at`)
--          after N >= 2 distinct open reports (or 1 nudity/self_harm report on a public link
--          without a prior dismissed report), moderator view `private.moderation_queue_due`,
--          and service-role RPCs `public.list_moderation_queue`,
--          `public.claim_moderation_notifications`, `public.confirm_moderation_notifications`,
--          `public.release_moderation_notifications`, `public.resolve_moderation_item`, and
--          `private.moderate_queue_item`.
--   CS-05  `public.account_has_password` and `public.check_delete_reauth_rate_limit` (service_role)
--          so `delete-account` Edge Function can re-authenticate password accounts and the App
--          Review demo account via password as well as 6-digit OTP while keeping FS-02 and FS-08 intact.
-- Idempotent (create or replace, drop if exists, if not exists).

-- ---------------------------------------------------------------------------
-- 0. Defense-in-depth helper for service_role-only SECURITY DEFINER RPCs
-- ---------------------------------------------------------------------------
create or replace function private.assert_service_role() returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_jwt_role text := nullif((select auth.jwt() ->> 'role'), '');
  v_guc_role text := nullif(current_setting('role', true), '');
begin
  if coalesce(v_jwt_role, '') in ('anon', 'authenticated')
     or coalesce(v_guc_role, '') in ('anon', 'authenticated')
     or coalesce(v_jwt_role, case when v_guc_role = 'none' then null else v_guc_role end, current_user)
        not in ('service_role', 'postgres', 'supabase_admin') then
    raise exception 'forbidden' using errcode = '42501';
  end if;
end;
$$;

revoke all on function private.assert_service_role() from public, anon, authenticated;
grant execute on function private.assert_service_role() to service_role;

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

-- Remove any legacy tone-ambiguous or over-broad seed terms if a prior revision was partially applied.
delete from private.objectionable_words
 where term in ('dm', 'lam tinh', 'audam', 'concac', 'cailon', 'vailon', 'daubuoi');

insert into private.objectionable_words (term, lang, match_mode, category)
select distinct on (v.term) v.term, v.lang, v.match_mode, v.category
  from (
    values
      -- Vietnamese single-word terms requiring exact diacritics (avoids false positives on lon/cac/buoi/du)
      ('địt', 'vi', 'diacritic_word', 'profanity'),
      ('đụ', 'vi', 'diacritic_word', 'profanity'),
      ('lồn', 'vi', 'diacritic_word', 'profanity'),
      ('cặc', 'vi', 'diacritic_word', 'profanity'),
      ('buồi', 'vi', 'diacritic_word', 'profanity'),
      ('đéo', 'vi', 'diacritic_word', 'profanity'),
      ('đĩ', 'vi', 'diacritic_word', 'slur'),
      ('chịch', 'vi', 'diacritic_word', 'sexual'),
      ('nứng', 'vi', 'diacritic_word', 'sexual'),
      -- Vietnamese accented multi-word phrases (matched before diacritic folding)
      ('địt mẹ', 'vi', 'diacritic_word', 'profanity'),
      ('địt con mẹ', 'vi', 'diacritic_word', 'profanity'),
      ('đụ má', 'vi', 'diacritic_word', 'profanity'),
      ('đụ mẹ', 'vi', 'diacritic_word', 'profanity'),
      ('đù má', 'vi', 'diacritic_word', 'profanity'),
      ('đù mẹ', 'vi', 'diacritic_word', 'profanity'),
      ('đéo mẹ', 'vi', 'diacritic_word', 'profanity'),
      ('con đĩ', 'vi', 'diacritic_word', 'slur'),
      ('vãi lồn', 'vi', 'diacritic_word', 'profanity'),
      ('cái lồn', 'vi', 'diacritic_word', 'profanity'),
      ('mặt lồn', 'vi', 'diacritic_word', 'profanity'),
      ('con cặc', 'vi', 'diacritic_word', 'profanity'),
      ('cục cặc', 'vi', 'diacritic_word', 'profanity'),
      ('đầu buồi', 'vi', 'diacritic_word', 'profanity'),
      ('bú cu', 'vi', 'diacritic_word', 'sexual'),
      ('mút cu', 'vi', 'diacritic_word', 'sexual'),
      ('bú lồn', 'vi', 'diacritic_word', 'sexual'),
      ('vét máng', 'vi', 'diacritic_word', 'sexual'),
      ('gạ tình', 'vi', 'diacritic_word', 'sexual'),
      ('bán dâm', 'vi', 'diacritic_word', 'sexual'),
      ('mua dâm', 'vi', 'diacritic_word', 'sexual'),
      ('hiếp dâm', 'vi', 'diacritic_word', 'violence'),
      ('ấu dâm', 'vi', 'diacritic_word', 'csae'),
      ('loạn luân', 'vi', 'diacritic_word', 'sexual'),
      -- Vietnamese unaccented multi-word phrases (matched before diacritic folding so accented everyday words never false-match)
      ('dit me', 'vi', 'diacritic_word', 'profanity'),
      ('dit con me', 'vi', 'diacritic_word', 'profanity'),
      ('dit cha', 'vi', 'diacritic_word', 'profanity'),
      ('dit ba', 'vi', 'diacritic_word', 'profanity'),
      ('du ma', 'vi', 'diacritic_word', 'profanity'),
      ('du me', 'vi', 'diacritic_word', 'profanity'),
      ('deo me', 'vi', 'diacritic_word', 'profanity'),
      ('con di', 'vi', 'diacritic_word', 'slur'),
      ('vai lon', 'vi', 'diacritic_word', 'profanity'),
      ('cai lon', 'vi', 'diacritic_word', 'profanity'),
      ('mat lon', 'vi', 'diacritic_word', 'profanity'),
      ('con cac', 'vi', 'diacritic_word', 'profanity'),
      ('cuc cac', 'vi', 'diacritic_word', 'profanity'),
      ('dau buoi', 'vi', 'diacritic_word', 'profanity'),
      ('bu cu', 'vi', 'diacritic_word', 'sexual'),
      ('mut cu', 'vi', 'diacritic_word', 'sexual'),
      ('bu lon', 'vi', 'diacritic_word', 'sexual'),
      ('vet mang', 'vi', 'diacritic_word', 'sexual'),
      ('ga tinh', 'vi', 'diacritic_word', 'sexual'),
      ('ban dam', 'vi', 'diacritic_word', 'sexual'),
      ('mua dam', 'vi', 'diacritic_word', 'sexual'),
      ('hiep dam', 'vi', 'diacritic_word', 'violence'),
      ('au dam', 'vi', 'diacritic_word', 'csae'),
      ('loan luan', 'vi', 'diacritic_word', 'sexual'),
      -- Unambiguous Vietnamese teencode tokens & solicitation phrases
      ('chat sex', 'vi', 'word', 'sexual'),
      ('call sex', 'vi', 'word', 'sexual'),
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
      -- Vietnamese compound substrings (matched within single whitespace-delimited tokens)
      ('địtmẹ', 'vi', 'substring', 'profanity'),
      ('địtconmẹ', 'vi', 'substring', 'profanity'),
      ('đụmá', 'vi', 'substring', 'profanity'),
      ('đụmẹ', 'vi', 'substring', 'profanity'),
      ('vãilồn', 'vi', 'substring', 'profanity'),
      ('cáilồn', 'vi', 'substring', 'profanity'),
      ('concặc', 'vi', 'substring', 'profanity'),
      ('đầubuồi', 'vi', 'substring', 'profanity'),
      ('hiếpdâm', 'vi', 'substring', 'violence'),
      ('ấudâm', 'vi', 'substring', 'csae'),
      ('loạnluân', 'vi', 'substring', 'sexual'),
      ('ditme', 'vi', 'substring', 'profanity'),
      ('ditconme', 'vi', 'substring', 'profanity'),
      ('hiepdam', 'vi', 'substring', 'violence'),
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
      ('nigga', 'en', 'word', 'slur'),
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
  ) as v(term, lang, match_mode, category)
 order by v.term
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
  v_diacritic_collapsed_words text;
  v_diacritic_tokens text;
  v_folded text;
  v_leet_folded text;
  v_alpha_words text;
  v_collapsed_words text;
  v_leet_words text;
  v_token_raw text;
  v_token_leet text;
begin
  if p_text is null or btrim(p_text) = '' then
    return false;
  end if;

  -- Strip zero-width characters & soft hyphens first, then normalize NFD combining marks to NFC.
  v_lower := lower(normalize(
    translate(p_text, U&'\00ad\200b\200c\200d\200e\200f\2060\feff', ''),
    NFC
  ));

  v_diacritic_words := ' ' || btrim(regexp_replace(
    v_lower,
    '[^a-zàáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ]+',
    ' ',
    'g'
  )) || ' ';

  v_diacritic_collapsed_words := ' ' || btrim(regexp_replace(
    regexp_replace(
      v_lower,
      '([a-zàáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ])[\._/\-]+(?=[a-zàáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ])',
      '\1',
      'g'
    ),
    '[^a-zàáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ]+',
    ' ',
    'g'
  )) || ' ';

  -- Token-scoped diacritic string (strips intra-token punctuation, preserves whitespace between words).
  v_diacritic_tokens := ' ' || btrim(regexp_replace(
    regexp_replace(v_lower, '[\._/\-]+', '', 'g'),
    '[^a-z0-9àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ]+',
    ' ',
    'g'
  )) || ' ';

  -- Fold Vietnamese diacritics to ASCII (67 source chars -> 67 target chars: 17 a, 11 e, 5 i, 17 o, 11 u, 5 y, 1 d).
  v_folded := translate(
    v_lower,
    'àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ',
    'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd'
  );

  v_leet_folded := translate(
    regexp_replace(v_folded, '!(?=[a-z0-9])', 'i', 'g'),
    '013457@$',
    'oieastas'
  );

  v_alpha_words := ' ' || btrim(regexp_replace(v_folded, '[^a-z]+', ' ', 'g')) || ' ';
  v_collapsed_words := ' ' || btrim(regexp_replace(
    regexp_replace(v_folded, '([a-z])[\._/\-]+(?=[a-z])', '\1', 'g'),
    '[^a-z]+',
    ' ',
    'g'
  )) || ' ';
  v_leet_words := ' ' || btrim(regexp_replace(
    regexp_replace(v_leet_folded, '([a-z])[\._/\-]+(?=[a-z])', '\1', 'g'),
    '[^a-z]+',
    ' ',
    'g'
  )) || ' ';

  -- Token-scoped folded strings for substring mode (never concatenates across whitespace between separate words).
  v_token_raw := ' ' || btrim(regexp_replace(
    regexp_replace(v_folded, '[\._/\-]+', '', 'g'),
    '[^a-z0-9]+',
    ' ',
    'g'
  )) || ' ';
  v_token_leet := ' ' || btrim(regexp_replace(
    regexp_replace(v_leet_folded, '[\._/\-]+', '', 'g'),
    '[^a-z0-9]+',
    ' ',
    'g'
  )) || ' ';

  return exists (
    select 1
      from private.objectionable_words w
     where w.enabled
       and (
         (w.match_mode = 'diacritic_word' and (
              position(' ' || w.term || ' ' in v_diacritic_words) > 0
              or position(' ' || w.term || ' ' in v_diacritic_collapsed_words) > 0
         ))
         or (w.match_mode = 'word' and (
              position(' ' || w.term || ' ' in v_alpha_words) > 0
              or position(' ' || w.term || ' ' in v_collapsed_words) > 0
              or position(' ' || w.term || ' ' in v_leet_words) > 0
         ))
         or (w.match_mode = 'substring' and (
              position(w.term in v_diacritic_tokens) > 0
              or (
                w.term !~ '[àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ]'
                and (
                  position(w.term in v_token_raw) > 0
                  or position(w.term in v_token_leet) > 0
                )
              )
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

-- Trigger functions are SECURITY DEFINER, so authenticated clients do not need direct EXECUTE on filter internals.
revoke all on function private.contains_objectionable_text(text), private.assert_clean_text(text)
  from public, anon, authenticated;
grant execute on function private.contains_objectionable_text(text), private.assert_clean_text(text)
  to service_role;

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
  v_term text := lower(normalize(btrim(coalesce(p_term, '')), NFC));
begin
  perform private.assert_service_role();
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

create or replace function public.set_objectionable_word_enabled(
  p_term text,
  p_enabled boolean default false
) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_term text := lower(normalize(btrim(coalesce(p_term, '')), NFC));
begin
  perform private.assert_service_role();
  if char_length(v_term) not between 2 and 64 then
    raise exception 'invalid';
  end if;
  update private.objectionable_words
     set enabled = coalesce(p_enabled, false)
   where term = v_term;
  if not found then
    raise exception 'not_found';
  end if;
end;
$$;

revoke all on function
  public.upsert_objectionable_word(text, text, text, text, boolean),
  public.set_objectionable_word_enabled(text, boolean)
from public, anon, authenticated;
grant execute on function
  public.upsert_objectionable_word(text, text, text, text, boolean),
  public.set_objectionable_word_enabled(text, boolean)
to service_role;

-- ---------------------------------------------------------------------------
-- 2. CS-03: Enforce objectionable-content filter on UGC write paths
-- ---------------------------------------------------------------------------
create or replace function private.profiles_enforce_content_policy() returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.deleted_at is not null then
    return new;
  end if;
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
declare
  v_old_dna jsonb := case when tg_op = 'UPDATE' then old.dna else null end;
begin
  if new.deleted_at is not null then
    return new;
  end if;
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
  if new.dna is not null then
    if tg_op = 'INSERT' or (new.dna ->> 'trophy') is distinct from (v_old_dna ->> 'trophy') then
      perform private.assert_clean_text(new.dna ->> 'trophy');
    end if;
    if tg_op = 'INSERT' or (new.dna ->> 'place') is distinct from (v_old_dna ->> 'place') then
      perform private.assert_clean_text(new.dna ->> 'place');
    end if;
    if tg_op = 'INSERT' or (new.dna ->> 'habit') is distinct from (v_old_dna ->> 'habit') then
      perform private.assert_clean_text(new.dna ->> 'habit');
    end if;
    if tg_op = 'INSERT' or (new.dna ->> 'reason') is distinct from (v_old_dna ->> 'reason') then
      perform private.assert_clean_text(new.dna ->> 'reason');
    end if;
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
declare
  v_existing_caption text;
begin
  if new.deleted_at is not null or new.caption is null or btrim(new.caption) = '' then
    return new;
  end if;
  if tg_op = 'UPDATE' then
    if new.caption is not distinct from old.caption then
      return new;
    end if;
  elsif new.id is not null then
    -- Client sync uses INSERT ... ON CONFLICT (id) DO UPDATE, which fires BEFORE INSERT first.
    select c.caption into v_existing_caption
      from public.check_ins c
     where c.id = new.id;
    if found and new.caption is not distinct from v_existing_caption then
      return new;
    end if;
  end if;
  perform private.assert_clean_text(new.caption);
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
declare
  v_prev jsonb := case when tg_op = 'UPDATE' then old.extras else null end;
begin
  if new.extras is null or new.extras = '{}'::jsonb then
    return new;
  end if;
  if tg_op = 'INSERT' and new.checkin_id is not null then
    select e.extras into v_prev
      from public.check_in_extras e
     where e.checkin_id = new.checkin_id;
  end if;
  if v_prev is null or (new.extras ->> 'mood') is distinct from (v_prev ->> 'mood') then
    perform private.assert_clean_text(new.extras ->> 'mood');
  end if;
  if v_prev is null or (new.extras ->> 'place') is distinct from (v_prev ->> 'place') then
    perform private.assert_clean_text(new.extras ->> 'place');
  end if;
  if v_prev is null or (new.extras ->> 'dish') is distinct from (v_prev ->> 'dish') then
    perform private.assert_clean_text(new.extras ->> 'dish');
  end if;
  if v_prev is null or (new.extras ->> 'cook') is distinct from (v_prev ->> 'cook') then
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
  if new.deleted_at is not null or new.body is null or btrim(new.body) = '' then
    return new;
  end if;
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
-- 3. CS-02 & CS-03: Quarantine visibility, banned-user enforcement,
--                   24-hour moderation SLA (due_at = created_at + 24h),
--                   message reporting & auto-hide pending review
-- ---------------------------------------------------------------------------
alter table public.reports
  add column if not exists due_at timestamptz not null default (now() + interval '24 hours');

alter table public.moderation_queue
  add column if not exists due_at timestamptz not null default (now() + interval '24 hours'),
  add column if not exists notified_at timestamptz,
  add column if not exists notify_claimed_until timestamptz,
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

-- Banned / soft-deleted profiles are no longer active members for write/read policies.
create or replace function private.is_member(journey uuid) returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.memberships m
      join public.profiles p on p.id = m.user_id and p.deleted_at is null
     where m.journey_id = journey
       and m.user_id = (select auth.uid())
       and m.status = 'active'
       and m.deleted_at is null
  );
$$;

-- Quarantined (moderated_at is not null) check-ins are hidden from all other members/viewers
-- without needing to set deleted_at until a moderator confirms removal.
create or replace function private.can_see_checkin(checkin uuid) returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.check_ins c
     where c.id = checkin
       and c.deleted_at is null
       and c.moderated_at is null
       and private.is_member(c.journey_id)
       and not private.is_blocked_pair(c.user_id)
  );
$$;

drop policy if exists check_ins_select on public.check_ins;
create policy check_ins_select on public.check_ins for select to authenticated
  using (
    user_id = (select auth.uid())
    or (deleted_at is null
        and moderated_at is null
        and private.is_member(journey_id)
        and not private.is_blocked_pair(user_id)
        and not private.has_reported(id))
  );

drop trigger if exists check_ins_touch_metric on public.check_ins;
create trigger check_ins_touch_metric after update of deleted_at, moderated_at on public.check_ins
  for each row
  when (old.deleted_at is distinct from new.deleted_at or old.moderated_at is distinct from new.moderated_at)
  execute function private.touch_checkin_metric();

drop trigger if exists check_ins_touch_extras on public.check_ins;
create trigger check_ins_touch_extras after update of deleted_at, moderated_at on public.check_ins
  for each row
  when (old.deleted_at is distinct from new.deleted_at or old.moderated_at is distinct from new.moderated_at)
  execute function private.touch_checkin_extras();

create or replace function public.checkin_tombstones(since timestamptz default null, lim int default 1000)
returns table (id uuid, journey_id uuid, updated_at timestamptz)
language sql
stable
security definer
set search_path = ''
as $$
  select c.id, c.journey_id, c.updated_at
    from public.check_ins c
   where (c.deleted_at is not null or c.moderated_at is not null)
     and c.user_id <> (select auth.uid())
     and (since is null or c.updated_at >= since)
     and private.is_member(c.journey_id)
   order by c.updated_at, c.id
   limit least(greatest(coalesce(lim, 1000), 1), 1000);
$$;

create or replace function public.group_today(journey uuid)
returns table (
  user_id uuid,
  username text,
  display_name text,
  avatar_path text,
  role public.member_role,
  checked_in boolean,
  checkin_id uuid,
  thumb_path text,
  captured_at timestamptz,
  current_streak int
)
language plpgsql
stable
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_tz text;
  v_today date;
begin
  perform public._uid();
  if not private.is_member(journey) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  select j.timezone into v_tz from public.journeys j where j.id = journey;
  v_today := public.local_date(now(), v_tz);

  return query
  select m.user_id, p.username, p.display_name, p.avatar_path, m.role,
         d.any_today,
         c.id,
         c.thumb_path,
         c.captured_at,
         coalesce(s.current_streak, 0)
    from public.memberships m
    join public.profiles p on p.id = m.user_id and p.deleted_at is null
    -- L7: checked_in counts every photo of today, even ones the caller reported.
    left join lateral (
      select exists (
        select 1 from public.check_ins c3
         where c3.journey_id = m.journey_id and c3.user_id = m.user_id
           and c3.local_date = v_today and c3.deleted_at is null) as any_today
    ) d on true
    -- A-B15 + CS-03: the latest photo of today the caller has not reported and that is not moderated.
    left join lateral (
      select c2.id, c2.thumb_path, c2.captured_at
        from public.check_ins c2
       where c2.journey_id = m.journey_id and c2.user_id = m.user_id
         and c2.local_date = v_today and c2.deleted_at is null
         and (c2.moderated_at is null or c2.user_id = (select auth.uid()))
         and not private.has_reported(c2.id)
       order by c2.captured_at desc, c2.id desc
       limit 1
    ) c on true
    left join lateral public.journey_streak(m.journey_id, m.user_id, v_today) s on true
   where m.journey_id = journey and m.status = 'active' and m.deleted_at is null
     and not private.is_blocked_pair(m.user_id)
   order by m.joined_at, m.user_id;
end;
$$;

create or replace function private.journey_view(p_journey uuid, p_role text) returns json
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  uid uuid := (select auth.uid());
  j public.journeys%rowtype;
  v_member boolean := p_role = 'member';
  v_counts boolean;
  v_photos json;
  v_total int;
  v_members json;
  v_streak int;
  v_sharer uuid;
  v_show_metric boolean;
  v_show_couple boolean;
  v_eval_today date;
  v_cover_id uuid;
  v_cover_blurred boolean := false;
begin
  select * into j from public.journeys where id = p_journey;
  v_counts := v_member or j.show_counts;
  v_show_metric := v_member or exists (
    select 1 from public.memberships m
     where m.journey_id = j.id and m.user_id = j.owner_id and not m.hide_metric);
  -- S29/S30: couple names and partner photo on a group journey require every active member
  -- to have accepted share consent and not be in a blocked pair with the viewer.
  v_show_couple := v_member or j.kind = 'solo' or (
    private.consent_accepted(j.id, j.owner_id)
    and not exists (
      select 1 from public.memberships cm
       where cm.journey_id = j.id and cm.status = 'active' and cm.deleted_at is null
         and (not private.consent_accepted(j.id, cm.user_id) or private.is_blocked_pair(cm.user_id))
    )
  );

  select coalesce(json_agg(json_build_object(
           'checkin_id', ph.id,
           'author', private.person(ph.user_id),
           'local_date', ph.local_date,
           'photo_path', case when not v_member and ph.blur_media then '' else ph.photo_path end,
           'thumb_path', case when not v_member and ph.blur_media then '' else ph.thumb_path end,
           'partner_photo_path', case when (not v_member and ph.blur_media) or not v_show_couple then null else ph.partner_photo_path end,
           'caption', ph.caption,
           'metric_value', case when ph.user_id = uid or not ph.hide_metric then cm.metric_value end,
           'like_count', case when v_counts then rc.cnt else 0 end,
           'liked_by_me', rc.mine,
           'blurred', (not v_member and ph.blur_media))
           order by ph.local_date, ph.captured_at, ph.id), '[]'::json),
         coalesce(sum(rc.cnt), 0)::int
    into v_photos, v_total
    from (
      select c.id, c.user_id, c.local_date, c.photo_path, c.thumb_path, c.partner_photo_path,
             c.caption, c.captured_at, m.hide_metric, m.blur_media
        from public.check_ins c
        join public.memberships m on m.journey_id = c.journey_id and m.user_id = c.user_id
       where c.journey_id = p_journey and c.deleted_at is null and c.moderated_at is null
         and not private.is_blocked_pair(c.user_id)
         and not private.has_reported(c.id)
         and (v_member or private.checkin_shareable(c.id))
    ) ph
    left join public.check_in_metrics cm on cm.checkin_id = ph.id
    cross join lateral (
      select count(*)::int as cnt, coalesce(bool_or(r.user_id = uid), false) as mine
        from public.reactions r where r.checkin_id = ph.id and r.deleted_at is null) rc;

  if j.kind = 'solo' then
    v_members := json_build_array(private.person(j.owner_id));
  else
    select coalesce(json_agg(private.person(m.user_id) order by m.joined_at, m.user_id), '[]'::json)
      into v_members
      from public.memberships m
     where m.journey_id = p_journey and m.status = 'active' and m.deleted_at is null
       and not private.is_blocked_pair(m.user_id)
       and (v_member or private.consent_accepted(p_journey, m.user_id));
  end if;

  if j.origin = 'imported' or (p_role = 'stranger' and j.kind = 'group') then
    v_streak := null;
  elsif j.kind = 'solo' then
    if j.status in ('ended', 'archived') then
      select least(public.local_date(now(), j.timezone),
                   coalesce(max(c.local_date), j.start_date))
        into v_eval_today
        from public.check_ins c
       where c.journey_id = j.id and c.user_id = j.owner_id and c.deleted_at is null;
    else
      v_eval_today := public.local_date(now(), j.timezone);
    end if;
    select s.current_streak into v_streak from public.journey_streak(j.id, j.owner_id, v_eval_today) s;
    v_streak := coalesce(v_streak, 0);
  else
    v_streak := coalesce(private.group_streak(j.id), 0);
  end if;

  if p_role = 'friend' then
    v_sharer := private.earliest_sharer(p_journey, uid);
  end if;

  if j.cover_checkin_id is not null
     and exists (
       select 1 from public.check_ins c
        where c.id = j.cover_checkin_id and c.deleted_at is null and c.moderated_at is null
     )
     and (v_member or private.checkin_shareable(j.cover_checkin_id)) then
    v_cover_id := j.cover_checkin_id;
    if not v_member then
      select coalesce(m.blur_media, true) into v_cover_blurred
        from public.check_ins c
        left join public.memberships m on m.journey_id = c.journey_id and m.user_id = c.user_id
       where c.id = j.cover_checkin_id;
      v_cover_blurred := coalesce(v_cover_blurred, false);
    end if;
  end if;

  return json_build_object(
    'journey_id', j.id,
    'role', p_role,
    'title', j.title,
    'emoji', j.emoji,
    'template_id', j.template_id,
    'kind', j.kind,
    'origin', j.origin,
    'status', j.status,
    'duration_days', j.duration_days,
    'start_date', j.start_date,
    'layout', j.layout,
    'color', j.color,
    'cover', j.cover,
    'couple_self_name', case when v_show_couple then j.couple_self_name end,
    'couple_partner_name', case when v_show_couple then j.couple_partner_name end,
    'cover_blurred', v_cover_blurred,
    'owner', private.owner_for_viewer(j.id),
    'members', v_members,
    'story', json_build_object(
      'title', j.story_title, 'intro', j.story_intro, 'lessons', j.story_lessons,
      'cover_checkin_id', v_cover_id,
      'cover_blurred', v_cover_blurred),
    'photos', v_photos,
    'current_streak', v_streak,
    'like_count', case when v_counts then v_total end,
    'follow_count', case when v_counts then
      (select count(distinct f.owner_id)::int from public.journeys f
        where f.followed_from = j.id and f.deleted_at is null) end,
    'metric_name', case when v_show_metric then j.metric_name end,
    'metric_unit', case when v_show_metric then j.metric_unit end,
    'shared_by', case when v_sharer is not null then private.person(v_sharer) end,
    'can_react', case p_role
                   when 'member' then j.status = 'active'
                   when 'friend' then true
                   else j.public_token is not null and j.allow_public_reactions end,
    'can_reply', p_role = 'friend',
    'can_follow', j.status in ('ended', 'archived'),
    'can_add_owner', p_role = 'stranger' and j.allow_viewer_requests and j.owner_id <> uid
                     and (j.kind = 'solo' or private.consent_accepted(j.id, j.owner_id))
                     and not exists (select 1 from public.friendships f
                                      where f.user_low = least(uid, j.owner_id)
                                        and f.user_high = greatest(uid, j.owner_id)
                                        and f.deleted_at is null)
                     and not private.is_blocked_pair(j.owner_id),
    'saved', exists (select 1 from public.saved_journeys s where s.user_id = uid and s.journey_id = j.id));
end;
$$;

create or replace function public.check_ins_before_write() returns trigger
language plpgsql
set search_path = ''
as $$
declare
  j public.journeys%rowtype;
  v_imported boolean;
begin
  select * into j from public.journeys where id = new.journey_id;
  if not found then
    raise exception 'not_found' using errcode = 'P0001';
  end if;

  -- FS-09: primary key, ownership, timestamp, library flag, and media paths of a check-in are immutable on UPDATE.
  if tg_op = 'UPDATE' and (
       new.id <> old.id
    or new.journey_id <> old.journey_id
    or new.user_id <> old.user_id
    or new.captured_at <> old.captured_at
    or new.photo_path <> old.photo_path
    or new.thumb_path <> old.thumb_path
    or new.partner_photo_path is distinct from old.partner_photo_path
    or new.from_library is distinct from old.from_library
  ) then
    raise exception 'immutable_column' using errcode = '23514';
  end if;

  new.local_date := public.local_date(new.captured_at, j.timezone);
  new.metric_value := null;
  v_imported := j.origin = 'imported' and new.user_id = j.owner_id and (
    (j.status in ('ended', 'archived') and j.duration_days is not null)
    or (
      j.status = 'active'
      and new.from_library
      and new.local_date between j.start_date
                             and coalesce(j.import_end_date, public.local_date(j.created_at, j.timezone))
    )
  );

  if current_user in ('authenticated', 'anon') then
    -- CS-03: banned / soft-deleted profiles cannot insert or update check-ins.
    if not exists (select 1 from public.profiles p where p.id = new.user_id and p.deleted_at is null) then
      raise exception 'forbidden' using errcode = '42501';
    end if;
    if tg_op = 'UPDATE' and old.moderated_at is not null then
      raise exception 'forbidden' using errcode = '42501';
    end if;
    if new.captured_at > now() + interval '10 minutes' then
      raise exception 'invalid_captured_at' using errcode = '22008';
    end if;
    if v_imported then
      if j.deleted_at is not null then
        raise exception 'ended' using errcode = 'P0001';
      end if;
      if new.local_date < j.start_date
         or (j.duration_days is not null and new.local_date > j.start_date + j.duration_days - 1) then
        raise exception 'invalid_captured_at' using errcode = '22008';
      end if;
    else
      if j.status <> 'active' or j.deleted_at is not null then
        raise exception 'ended' using errcode = 'P0001';
      end if;
      if (tg_op = 'INSERT' or new.captured_at is distinct from old.captured_at)
         and (new.local_date < public.local_date(now(), j.timezone) - 3
              or (j.origin = 'imported' and new.local_date < j.start_date)) then
        raise exception 'invalid_captured_at' using errcode = '22008';
      end if;
      if j.duration_days is not null and new.local_date > j.start_date + j.duration_days - 1 then
        raise exception 'ended' using errcode = 'P0001';
      end if;
    end if;
    if tg_op = 'INSERT' then
      new.hidden_by_leave := false;
      new.moderated_at := null;
      new.hidden_in_share := false;
    else
      new.hidden_by_leave := old.hidden_by_leave;
      new.moderated_at := old.moderated_at;
      new.hidden_in_share := old.hidden_in_share;
    end if;
  end if;
  return new;
end;
$$;

-- A conversation becomes read-only as soon as either participant is banned / soft-deleted.
create or replace function private.conversation_read_only(p_conversation uuid) returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((
    select not private.are_friends(c.member_id, c.viewer_id)
           or private.blocked_between(c.member_id, c.viewer_id)
           or exists (
             select 1 from public.profiles p
              where p.id in (c.member_id, c.viewer_id)
                and p.deleted_at is not null
           )
      from public.conversations c where c.id = p_conversation), true);
$$;

create or replace function public.send_message(
  p_id uuid,
  p_conversation uuid,
  p_kind text,
  p_body text,
  p_media_path text,
  p_reply_to uuid default null
) returns json
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := public._uid();
  c public.conversations%rowtype;
  m public.messages%rowtype;
  v_body text := nullif(btrim(p_body), '');
  v_media text;
begin
  if p_id is null then
    raise exception 'invalid';
  end if;
  if not exists (select 1 from public.profiles p where p.id = uid and p.deleted_at is null) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  select * into c from public.conversations where id = p_conversation for update;
  if not found then
    raise exception 'not_found';
  end if;
  if uid not in (c.member_id, c.viewer_id) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  select * into m from public.messages where id = p_id;
  if found then
    if m.sender_id = uid and m.conversation_id = p_conversation then
      return private.message_json(m); -- idempotent retry
    end if;
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if private.conversation_read_only(p_conversation) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if p_kind = 'text' then
    if v_body is null or char_length(v_body) > 500 then
      raise exception 'invalid';
    end if;
  elsif p_kind = 'photo' then
    v_media := p_media_path;
    if v_media is null
       or v_media <> ('messages/' || p_conversation::text || '/' || uid::text || '/' || p_id::text || '.jpg')
       or char_length(v_body) > 500 then
      raise exception 'invalid';
    end if;
  else
    raise exception 'invalid'; -- 'clip' ships with v0.2
  end if;
  if p_reply_to is not null and not exists (
       select 1 from public.check_ins where id = p_reply_to and journey_id = c.journey_id) then
    raise exception 'invalid';
  end if;
  if (select count(*) from public.messages
       where sender_id = uid and created_at > now() - interval '1 minute') >= 60 then
    raise exception 'rate_limited';
  end if;

  insert into public.messages (id, conversation_id, sender_id, kind, body, media_path, reply_to_checkin_id)
  values (p_id, p_conversation, uid, p_kind, v_body, v_media, p_reply_to)
  returning * into m;
  update public.conversations
     set last_message_at = m.created_at,
         member_read_at = case when member_id = uid then m.created_at else member_read_at end,
         viewer_read_at = case when viewer_id = uid then m.created_at else viewer_read_at end
   where id = p_conversation;
  return private.message_json(m);
end;
$$;

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

revoke all on function
  private.is_member(uuid),
  private.can_see_checkin(uuid),
  private.conversation_read_only(uuid),
  private.has_reported_message(uuid),
  private.can_read_message(uuid)
from public, anon;
grant execute on function
  private.is_member(uuid),
  private.can_see_checkin(uuid),
  private.conversation_read_only(uuid),
  private.has_reported_message(uuid),
  private.can_read_message(uuid)
to authenticated, service_role;

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

  -- CS-03: auto-quarantine check-ins pending moderator review after N >= 2 distinct open reports
  -- (or immediately when nudity/self_harm is reported on a public link with no prior dismissed report).
  -- Sets only moderated_at (leaving deleted_at untouched until confirmed removal) so user deletions
  -- and author streaks are never corrupted by false-positive reports.
  -- (For 1-on-1 messages, the reporter is the only recipient and private.has_reported_message
  -- already hides the message immediately on the first report.)
  if p_checkin is not null then
    select count(distinct r.reporter_id)::int into v_open_reports
      from public.reports r
     where r.target_checkin_id = p_checkin
       and r.deleted_at is null
       and r.status = 'open';
    if v_open_reports >= 2
       or (
         v_has_public_link
         and p_reason in ('nudity', 'self_harm')
         and not exists (
           select 1 from public.reports r
            where r.target_checkin_id = p_checkin
              and r.deleted_at is null
              and r.status = 'dismissed'
         )
       ) then
      update public.check_ins
         set moderated_at = coalesce(moderated_at, now())
       where id = p_checkin
         and moderated_at is null;
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
create or replace view private.moderation_queue_due
with (security_invoker = true) as
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
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform private.assert_service_role();
  return query
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
end;
$$;

-- Two-phase notification claim: leases open unnotified rows for 5 minutes so concurrent workers do
-- not send duplicate alerts, while webhook failures or unconfigured runs can release/expire the
-- lease without permanently losing the 24h SLA notification.
create or replace function public.claim_moderation_notifications(p_limit int default 50)
returns setof json
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.assert_service_role();
  return query
  with claimed as (
    update public.moderation_queue q
       set notify_claimed_until = now() + interval '5 minutes'
     where q.id in (
       select mq.id
         from public.moderation_queue mq
        where mq.status = 'open'
          and mq.notified_at is null
          and (mq.notify_claimed_until is null or mq.notify_claimed_until <= now())
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

create or replace function public.confirm_moderation_notifications(p_ids uuid[])
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  n int := 0;
begin
  perform private.assert_service_role();
  update public.moderation_queue
     set notified_at = coalesce(notified_at, now()),
         notify_claimed_until = null
   where id = any(coalesce(p_ids, '{}'));
  get diagnostics n = row_count;
  return n;
end;
$$;

create or replace function public.release_moderation_notifications(p_ids uuid[])
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  n int := 0;
begin
  perform private.assert_service_role();
  update public.moderation_queue
     set notify_claimed_until = null
   where id = any(coalesce(p_ids, '{}'))
     and notified_at is null;
  get diagnostics n = row_count;
  return n;
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
  v_journey_id uuid;
  v_sentinel uuid := '00000000-0000-0000-0000-000000000000'::uuid;
begin
  perform private.assert_service_role();
  if p_queue_id is null or v_action not in ('dismiss', 'remove_content', 'action', 'ban_user') then
    raise exception 'invalid';
  end if;

  select * into q from public.moderation_queue where id = p_queue_id for update;
  if not found then
    raise exception 'not_found';
  end if;

  -- Cannot dismiss an already-actioned moderation decision.
  if v_action = 'dismiss' and q.status = 'actioned' then
    raise exception 'invalid';
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
    -- Restore auto-quarantined content only when not soft-deleted and no actioned report/queue item holds it.
    if q.target_checkin_id is not null then
      update public.check_ins c
         set moderated_at = null
       where c.id = q.target_checkin_id
         and c.moderated_at is not null
         and c.deleted_at is null
         and not exists (
           select 1 from public.reports r
            where r.target_checkin_id = q.target_checkin_id
              and r.deleted_at is null
              and r.status = 'actioned'
         )
         and not exists (
           select 1 from public.moderation_queue mq
            where mq.target_checkin_id = q.target_checkin_id
              and mq.status = 'actioned'
         );
    end if;
    if q.target_message_id is not null then
      update public.messages m
         set moderated_at = null
       where m.id = q.target_message_id
         and m.moderated_at is not null
         and m.deleted_at is null
         and not exists (
           select 1 from public.reports r
            where r.target_message_id = q.target_message_id
              and r.deleted_at is null
              and r.status = 'actioned'
         )
         and not exists (
           select 1 from public.moderation_queue mq
            where mq.target_message_id = q.target_message_id
              and mq.status = 'actioned'
         );
    end if;
  else
    -- remove_content / action / ban_user: permanently moderate the reported check-in or message
    -- and queue its Storage objects for purge.
    if q.target_checkin_id is not null then
      insert into private.pending_storage_purge (bucket, path, user_id)
      select distinct 'media', p, v_sentinel
        from public.check_ins c
        cross join lateral unnest(array[c.photo_path, c.thumb_path, c.partner_photo_path]) as p
       where c.id = q.target_checkin_id
         and p is not null and length(p) between 1 and 1024
      on conflict (bucket, path) do update
        set user_id = v_sentinel,
            attempts = 0,
            next_attempt_at = now(),
            last_error = null;

      update public.check_ins
         set moderated_at = coalesce(moderated_at, now()),
             deleted_at = coalesce(deleted_at, now())
       where id = q.target_checkin_id;
    end if;

    if q.target_message_id is not null then
      insert into private.pending_storage_purge (bucket, path, user_id)
      select distinct 'messages', m.media_path, v_sentinel
        from public.messages m
       where m.id = q.target_message_id
         and m.media_path is not null and length(m.media_path) between 1 and 1024
      on conflict (bucket, path) do update
        set user_id = v_sentinel,
            attempts = 0,
            next_attempt_at = now(),
            last_error = null;

      update public.messages
         set moderated_at = coalesce(moderated_at, now()),
             deleted_at = coalesce(deleted_at, now())
       where id = q.target_message_id;
    end if;

    if v_action = 'ban_user' and q.target_user_id is not null then
      update public.profiles
         set deleted_at = coalesce(deleted_at, now())
       where id = q.target_user_id;

      -- Queue all Storage files belonging to the banned user's check-ins, avatar, and chat messages.
      insert into private.pending_storage_purge (bucket, path, user_id)
      select distinct 'media', p, v_sentinel
        from (
          select unnest(array[c.photo_path, c.thumb_path, c.partner_photo_path]) as p
            from public.check_ins c
           where c.user_id = q.target_user_id
          union all
          select pr.avatar_path as p
            from public.profiles pr
           where pr.id = q.target_user_id
        ) x
       where p is not null and length(p) between 1 and 1024
      on conflict (bucket, path) do update
        set user_id = v_sentinel,
            attempts = 0,
            next_attempt_at = now(),
            last_error = null;

      insert into private.pending_storage_purge (bucket, path, user_id)
      select distinct 'messages', m.media_path, v_sentinel
        from public.messages m
       where m.sender_id = q.target_user_id
         and m.media_path is not null and length(m.media_path) between 1 and 1024
      on conflict (bucket, path) do update
        set user_id = v_sentinel,
            attempts = 0,
            next_attempt_at = now(),
            last_error = null;

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

      -- Remove banned user from active group journeys (transferring ownership if they owned a surviving group).
      for v_journey_id in
        select m.journey_id
          from public.memberships m
          join public.journeys j on j.id = m.journey_id
         where m.user_id = q.target_user_id
           and m.status = 'active'
           and m.deleted_at is null
           and j.kind = 'group'
         order by m.journey_id
      loop
        perform public._leave_journey(v_journey_id, q.target_user_id);
        update public.memberships
           set removed_at = coalesce(removed_at, now())
         where journey_id = v_journey_id and user_id = q.target_user_id;
      end loop;

      update public.journeys
         set public_token = null,
             visibility = case when kind = 'solo' then 'private'::public.journey_visibility else visibility end,
             status = case when kind = 'solo' and status = 'active' then 'archived'::public.journey_status else status end,
             deleted_at = case when kind = 'solo' then coalesce(deleted_at, now()) else deleted_at end
       where owner_id = q.target_user_id;

      update public.journey_shares
         set revoked_at = now()
       where (shared_by = q.target_user_id or viewer_id = q.target_user_id)
         and revoked_at is null;

      update public.friendships
         set deleted_at = now()
       where (user_low = q.target_user_id or user_high = q.target_user_id)
         and deleted_at is null;

      if exists (
        select 1 from information_schema.columns
         where table_schema = 'auth' and table_name = 'users' and column_name = 'banned_until'
      ) then
        execute 'update auth.users set banned_until = now() + interval ''100 years'' where id = $1'
          using q.target_user_id;
      end if;

      if exists (
        select 1 from information_schema.tables
         where table_schema = 'auth' and table_name = 'sessions'
      ) then
        execute 'delete from auth.sessions where user_id = $1'
          using q.target_user_id;
      end if;

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
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.assert_service_role();
  return private.moderate_queue_item(p_queue_id, p_action, p_note);
end;
$$;

-- ---------------------------------------------------------------------------
-- 5. CS-05: Password account detection & per-user re-auth throttle for delete-account
-- ---------------------------------------------------------------------------
create or replace function public.account_has_password(p_user uuid) returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform private.assert_service_role();
  return coalesce((
    select u.encrypted_password is not null and btrim(u.encrypted_password) <> ''
      from auth.users u
     where u.id = p_user
  ), false);
end;
$$;

create or replace function public.check_delete_reauth_rate_limit(
  p_user uuid,
  p_record_failure boolean default false
) returns boolean
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.assert_service_role();
  if p_user is null then
    return false;
  end if;
  delete from private.rate_events
   where user_id = p_user and at < now() - interval '1 day';
  if coalesce(p_record_failure, false) then
    insert into private.rate_events (user_id, kind)
    values (p_user, 'delete_reauth_fail');
  end if;
  return (
    select count(*)
      from private.rate_events
     where user_id = p_user
       and kind = 'delete_reauth_fail'
       and at > now() - interval '15 minutes'
  ) < 10;
end;
$$;

revoke all on function
  public.list_moderation_queue(text, int),
  public.claim_moderation_notifications(int),
  public.confirm_moderation_notifications(uuid[]),
  public.release_moderation_notifications(uuid[]),
  private.moderate_queue_item(uuid, text, text),
  public.resolve_moderation_item(uuid, text, text),
  public.account_has_password(uuid),
  public.check_delete_reauth_rate_limit(uuid, boolean)
from public, anon, authenticated;

grant execute on function
  public.list_moderation_queue(text, int),
  public.claim_moderation_notifications(int),
  public.confirm_moderation_notifications(uuid[]),
  public.release_moderation_notifications(uuid[]),
  private.moderate_queue_item(uuid, text, text),
  public.resolve_moderation_item(uuid, text, text),
  public.account_has_password(uuid),
  public.check_delete_reauth_rate_limit(uuid, boolean)
to service_role;
