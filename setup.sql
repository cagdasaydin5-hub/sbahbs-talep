-- =====================================================================
--  SBAHBS Geri Bildirim — Supabase kurulum / güncelleme script'i
--  Çalıştırma:  Supabase paneli -> SQL Editor -> bu dosyayı yapıştır -> Run
--  (vbobeqgambooxtfefxmd projesi — içinde zaten 'ideas' tablosu var)
-- =====================================================================
--  Bu script GÜVENLE TEKRAR ÇALIŞTIRILABİLİR. Mevcut tabloyu silmez,
--  sadece eksikleri tamamlar:
--   * 'category' kolonunu ekler (eski tabloda yoktu)
--   * Güvenli ekleme/oylama fonksiyonlarını oluşturur
--   * Doğrudan yazma/güncelleme/silmeyi kapatır (RLS)
-- =====================================================================

-- 1) Tablo yoksa oluştur (varsa dokunmaz)
create table if not exists public.ideas (
  id         bigint generated always as identity primary key,
  text       text        not null,
  category   text        not null default 'Kolaylaştırılmalı',
  votes      integer     not null default 0,
  created_at timestamptz not null default now()
);

-- 2) Eksik kolonları tamamla (eski tablo için)
alter table public.ideas add column if not exists category   text        not null default 'Kolaylaştırılmalı';
alter table public.ideas add column if not exists votes      integer     not null default 0;
alter table public.ideas add column if not exists created_at timestamptz not null default now();

-- 3) Satır bazlı güvenlik (RLS) aç
alter table public.ideas enable row level security;

-- 4) Herkes (anon) listeyi OKUYABİLİR
grant select on public.ideas to anon;
drop policy if exists "ideas_select_anon" on public.ideas;
create policy "ideas_select_anon"
  on public.ideas for select
  to anon
  using (true);

-- 5) Doğrudan yazma/güncelleme/silme KAPALI (yalnızca aşağıdaki fonksiyonlarla)
revoke insert, update, delete on public.ideas from anon;

-- 6) Öneri ekleme fonksiyonu (votes=1 sabit, metin temizlenir/kırpılır)
create or replace function public.add_idea(p_text text, p_category text)
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
  insert into public.ideas (text, category, votes)
  values (
    left(btrim(p_text), 500),
    coalesce(nullif(btrim(p_category), ''), 'Kolaylaştırılmalı'),
    1
  )
  returning * into r;
  return r;
end;
$$;
grant execute on function public.add_idea(text, text) to anon;

-- 7) Oylama fonksiyonu (sadece votes değişir, negatife düşmez)
create or replace function public.vote_idea(p_id bigint, p_delta integer)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare v integer;
begin
  update public.ideas
     set votes = greatest(0, votes + p_delta)
   where id = p_id
   returning votes into v;
  return v;
end;
$$;
grant execute on function public.vote_idea(bigint, integer) to anon;

-- Bitti. Tablo güncel, fonksiyonlar yetkili, doğrudan yazma kapalı.
