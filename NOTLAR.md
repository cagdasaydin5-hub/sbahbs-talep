# SBAHBS Geri Bildirim — Proje Durumu & Devam Notları

> Bu dosya, projeyi başka makinede / yeni sohbette devralmak için yazıldı.
> Tek dosyalık statik site (HTML+CSS+JS) — sunucu/derleme gerekmez. Tarayıcıda açılır.

## Amaç
SB-AHBS (Sağlık Bakanlığı Aile Hekimliği Bilgi Sistemi) hakkında ~4000 kişilik doktor
grubundan geri bildirim toplamak. Toplanan veri sonra **kategorize edilip değiştirme
zorluğuna göre sıralanacak**; SB-AHBS proje yöneticisi **Beste Kaya Varmış**'a sunulacak
rapor/sunum hazırlanacak.

## Dosyalar
- `index.html` — doktorların kullandığı geri bildirim sayfası
- `panel.html` — yönetici/sonuç paneli (özet kartlar, kategori/modül dağılımı, top 10, zaman kaybı, CSV export)
- `setup.sql` — Supabase kurulum/güncelleme (v2, idempotent)
- `index.original-backup.html` — Netlify'dan kurtarılan ESKİ sürümün yedeği

## Supabase
- Proje ref: `vbobeqgambooxtfefxmd` (e-Derslik `uxwwirucwwusztmewrkd`'den AYRI proje, aynı hesap)
- `index.html` + `panel.html` içindeki `SUPABASE_URL` ve anon key zaten dolu (anon key halka açıktır, sorun değil; `service_role` ASLA koda konmaz)
- Tablolar: `ideas (id,text,category,module,minutes,bransh,il,gecis,votes,created_at)`, `participants (client_id,bransh,il,gecis,created_at)`
- Güvenlik: anon DOĞRUDAN yazamaz/güncelleyemez/silemez (RLS açık + grant'lar revoke). Tüm yazma/oylama/kayıt yalnız RPC fonksiyonlarıyla (SECURITY DEFINER): `add_idea(7 arg)`, `vote_idea`, `register_participant(4 arg)`, `get_stats`. XSS kapalı. (Doğrulandı: doğrudan anon DELETE/PATCH/INSERT → 401.)
- `setup.sql` yeni kolon/fonksiyon EKLEMEDİKÇE tekrar çalıştırmak gerekmez. Şu anki şema güncel ve test edildi.

## Site özellikleri
- Kategoriler (index.html'deki `CATEGORIES` dizisinden tek yerden): **Kolaylaştırılmalı / Yavaş-Performans / Bulması zor / Eksik özellik / Hata-bug**
- Öneri verirken: kategori (zorunlu) + modül (opsiyonel) + "günde ~kaç dk" (opsiyonel)
- İlk açılışta **ZORUNLU tek seferlik profil** (atlanamaz): branş + "SB-AHBS'ye ne zaman geçtiniz" (1 ay içinde / 1-3 ay / 3-6 ay / Element'ten geçtim). İl arayüzden KALDIRILDI; DB'de boş kolon duruyor (geri açmak tek satır).
- panel.html, index'teki "📊 Sonuçlar" linkiyle açılır.

## DURUM — son güncelleme 2026-06-23

### ✅ Tamamlandı
- Kod kurtarıldı; güvenli + kategorili + modüllü + zaman-kayıplı yeniden yazıldı; uçtan uca test edildi (hepsi geçti)
- GitHub'a push'landı: **https://github.com/cagdasaydin5-hub/sbahbs-talep** (dal: `main`)

### ⏳ Yayın öncesi kalan adımlar
1. **(Güvenlik)** Supabase SQL Editor'daki `cron.schedule('gece-temizligi'...)` adlı **KAYITLI SORGUYU SİL.** Çalıştırılırsa her gece az-oylu (≤1) ve 2 günden eski önerileri siler → veri kaybı. Şu an `cron.job` **BOŞ** (görev aktif değil, kontrol edildi) ama pg_cron etkin; kazara "Run" edilmesin diye sorgu silinmeli.
2. **Test verisini temizle** (SQL Editor):
   ```sql
   truncate public.ideas, public.participants restart identity;
   ```
3. **Netlify deploy:** `index.html` + `panel.html` BİRLİKTE, mevcut `sbahbstalep` sitesinin üstüne (URL aynı: https://sbahbstalep.netlify.app/). Bu makinelerde netlify CLI/token YOK → ya tarayıcıdan **Deploys → sürükle-bırak**, ya da Netlify **Personal Access Token** ile CLI.

### 🔜 Sonraki aşama (veri toplandıktan sonra)
Geri bildirimleri oku → benzerleri grupla → tekrarları birleştir → her maddeyi
**etki (oy × dk × kişi) × düzeltme zorluğu** matrisine diz → Beste Hanım için
"hızlı kazanımlar / orta vadeli / yapısal" öncelik listesi + sunum çıkar.

## Git
Dal `main`, remote `origin` = yukarıdaki GitHub reposu. Her şey commit'li.
Masaüstünde:  `git clone https://github.com/cagdasaydin5-hub/sbahbs-talep.git`
