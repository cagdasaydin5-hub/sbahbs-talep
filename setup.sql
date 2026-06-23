-- =====================================================================
--  SBAHBS Geri Bildirim — Supabase kurulum / güncelleme script'i (v3)
--  Çalıştırma:  Supabase paneli -> SQL Editor -> bu dosyayı yapıştır -> Run
--  (vbobeqgambooxtfefxmd projesi)
-- =====================================================================
--  GÜVENLE TEKRAR ÇALIŞTIRILABİLİR. Mevcut veriyi silmez; eksikleri ekler:
--   * ideas tablosuna: module, minutes (günlük tahmini dk), bransh, il, weighted_votes
--   * participants tablosu (kaç hekim / kaç il katıldı)
--   * Deneyim çarpanı: oylar SB-AHBS deneyimine göre ağırlıklanır (gecis_weight: 1/2/3/4)
--   * Güvenli fonksiyonlar: add_idea, vote_idea(+gecis), register_participant, get_stats
--   * Doğrudan yazma/silme KAPALI (yalnız fonksiyonlarla)
--  v3 NOT: vote_idea imzası değişti (p_gecis eklendi) -> bu script yeniden çalıştırılmalı.
-- =====================================================================

-- 1) ideas tablosu (yoksa oluştur)
create table if not exists public.ideas (
  id         bigint generated always as identity primary key,
  text       text        not null,
  category   text        not null default 'Kolaylaştırılmalı',
  votes      integer     not null default 0,
  created_at timestamptz not null default now()
);

-- 2) Yeni kolonlar (eski tablo için)
alter table public.ideas add column if not exists category   text        not null default 'Kolaylaştırılmalı';
alter table public.ideas add column if not exists votes      integer     not null default 0;
alter table public.ideas add column if not exists created_at timestamptz not null default now();
alter table public.ideas add column if not exists module     text;
alter table public.ideas add column if not exists minutes    integer;   -- günlük tahmini zaman kaybı (dk)
alter table public.ideas add column if not exists bransh     text;
alter table public.ideas add column if not exists il         text;
alter table public.ideas add column if not exists gecis      text;   -- SB-AHBS'ye geçiş süresi
alter table public.ideas add column if not exists weighted_votes numeric not null default 0;  -- deneyim-ağırlıklı oy skoru (1/2/3/4 çarpan)
-- eski (ağırlıksız) satırlar için tek seferlik geri-doldurma: hiç ağırlık yoksa ham oyu baz al
update public.ideas set weighted_votes = votes where weighted_votes = 0 and votes > 0;

-- 3) Katılımcı tablosu (tarayıcı başına 1 kayıt -> kaç hekim / kaç il)
create table if not exists public.participants (
  id         bigint generated always as identity primary key,
  client_id  text unique not null,
  bransh     text,
  il         text,
  gecis      text,
  created_at timestamptz not null default now()
);
alter table public.participants add column if not exists gecis text;

-- 4) RLS
alter table public.ideas        enable row level security;
alter table public.participants enable row level security;

-- ideas: herkes OKUYABİLİR
grant select on public.ideas to anon;
drop policy if exists "ideas_select_anon" on public.ideas;
create policy "ideas_select_anon" on public.ideas for select to anon using (true);

-- ideas + participants: doğrudan yazma/güncelleme/silme KAPALI (yalnız fonksiyonlarla)
revoke insert, update, delete on public.ideas        from anon;
revoke all                     on public.participants from anon;

-- 4b) Deneyim çarpanı: SB-AHBS'ye geçiş süresine göre oy ağırlığı (1 / 2 / 3 / 4)
create or replace function public.gecis_weight(p_gecis text)
returns numeric
language sql
immutable
set search_path = public
as $$
  select case btrim(coalesce(p_gecis, ''))
    when 'Element''ten geçtim' then 4
    when '3-6 ay'              then 3
    when '1-3 ay'              then 2
    when '1 ay içinde'         then 1
    else 1
  end;
$$;

-- 5) Öneri ekleme (imza: module, minutes, bransh, il, gecis)
drop function if exists public.add_idea(text, text);
drop function if exists public.add_idea(text, text, text, integer, text, text);
create or replace function public.add_idea(
  p_text text, p_category text, p_module text, p_minutes integer, p_bransh text, p_il text, p_gecis text
)
returns public.ideas
language plpgsql
security definer
set search_path = public
as $$
declare r public.ideas;
begin
  if char_length(btrim(p_text)) < 3 then
    raise exception 'Metin çok kısa';
  end if;
  insert into public.ideas (text, category, module, minutes, bransh, il, gecis, votes, weighted_votes)
  values (
    left(btrim(p_text), 500),
    coalesce(nullif(btrim(p_category), ''), 'Kolaylaştırılmalı'),
    nullif(btrim(p_module), ''),
    case when p_minutes is null then null
         when p_minutes < 0    then 0
         when p_minutes > 600  then 600
         else p_minutes end,
    nullif(btrim(p_bransh), ''),
    nullif(btrim(p_il), ''),
    nullif(btrim(p_gecis), ''),
    1,
    public.gecis_weight(p_gecis)   -- yazar otomatik oy verir; ağırlığı kendi deneyimi kadar
  )
  returning * into r;
  return r;
end;
$$;
grant execute on function public.add_idea(text, text, text, integer, text, text, text) to anon;

-- 6) Oylama (ham oy + deneyim-ağırlıklı skor; negatife düşmez)
drop function if exists public.vote_idea(bigint, integer);
create or replace function public.vote_idea(p_id bigint, p_delta integer, p_gecis text)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare v integer; w numeric;
begin
  w := public.gecis_weight(p_gecis);
  update public.ideas
     set votes          = greatest(0, votes + p_delta),
         weighted_votes = greatest(0, weighted_votes + (p_delta * w))
   where id = p_id
   returning votes into v;
  return v;
end;
$$;
grant execute on function public.vote_idea(bigint, integer, text) to anon;

-- 7) Katılımcı kaydı (tarayıcı başına 1; upsert)
drop function if exists public.register_participant(text, text, text);
create or replace function public.register_participant(p_client_id text, p_bransh text, p_il text, p_gecis text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_client_id is null or btrim(p_client_id) = '' then return; end if;
  insert into public.participants (client_id, bransh, il, gecis)
  values (btrim(p_client_id), nullif(btrim(p_bransh), ''), nullif(btrim(p_il), ''), nullif(btrim(p_gecis), ''))
  on conflict (client_id) do update
    set bransh = excluded.bransh, il = excluded.il, gecis = excluded.gecis;
end;
$$;
grant execute on function public.register_participant(text, text, text, text) to anon;

-- 8) Panel istatistikleri (kaç hekim / kaç il)
create or replace function public.get_stats()
returns json
language sql
security definer
set search_path = public
as $$
  select json_build_object(
    'participants',  (select count(*) from public.participants),
    'participant_cities', (select count(distinct il) from public.participants where il is not null and il <> ''),
    'idea_cities',   (select count(distinct il) from public.ideas where il is not null and il <> ''),
    'participant_gecis',  (select coalesce(json_object_agg(g, c), '{}'::json)
                             from (select coalesce(nullif(btrim(gecis), ''), '(belirtilmemiş)') g, count(*) c
                                     from public.participants group by 1) s),
    'participant_bransh', (select coalesce(json_object_agg(g, c), '{}'::json)
                             from (select coalesce(nullif(btrim(bransh), ''), '(belirtilmemiş)') g, count(*) c
                                     from public.participants group by 1) s)
  );
$$;
grant execute on function public.get_stats() to anon;

-- Bitti.
