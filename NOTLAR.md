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
- `panel.html` — **hekime yönelik canlı özet sayfası** (kartlar, yoğunlaşılan konular, modül sıcak noktaları, deneyim-ağırlıklı sıralı top 10, zaman kaybı, katılan hekimlerin deneyim+branş dağılımı). NOT: elle analiz araçları (matris/tablo) kaldırıldı; asıl analizi Claude veri toplanınca Supabase'den çekip yapacak.
- `ANALIZ-PLANI.md` — veri toplandıktan sonra uygulanacak adım adım analiz & sunum yöntemi (Claude için referans)
- `setup.sql` — Supabase kurulum/güncelleme (v3, idempotent)
- `index.original-backup.html` — Netlify'dan kurtarılan ESKİ sürümün yedeği
- `publish/` — SADECE deploy edilecekler (index.html + panel.html). Git'te takipsiz; deploy klasörü.

## Supabase
- Proje ref: `vbobeqgambooxtfefxmd` (e-Derslik `uxwwirucwwusztmewrkd`'den AYRI proje, aynı hesap)
- `index.html` + `panel.html` içindeki `SUPABASE_URL` ve anon key zaten dolu (anon key halka açıktır, sorun değil; `service_role` ASLA koda konmaz)
- Tablolar: `ideas (id,text,category,module,minutes,bransh,il,gecis,votes,weighted_votes,created_at)`, `participants (client_id,bransh,il,gecis,created_at)`
- **Deneyim çarpanı (v3, 2026-06-23):** `weighted_votes` kolonu + `gecis_weight(gecis)` fonksiyonu → 1 ay:1× / 1-3 ay:2× / 3-6 ay:3× / Element'ten geçtim:4×. `vote_idea` artık `(p_id,p_delta,p_gecis)` alıyor; ham `votes` + `weighted_votes` birlikte güncelleniyor. `get_stats` katılımcı deneyim/branş dağılımını da döndürüyor. Sıralama (panel + analiz) ağırlıklı skora göre; hekim oy butonunda HAM oyu görür.
- Güvenlik: anon DOĞRUDAN yazamaz/güncelleyemez/silemez (RLS açık + grant'lar revoke). Tüm yazma/oylama/kayıt yalnız RPC fonksiyonlarıyla (SECURITY DEFINER): `add_idea(7 arg)`, `vote_idea(3 arg)`, `register_participant(4 arg)`, `get_stats`, `gecis_weight`. XSS kapalı. (Not: çarpan p_gecis client'tan gelir; kötü niyetli biri kendini Element gösterip 4× alabilir — iyi niyetli hekim grubu için kabul edilir risk.)
- `setup.sql` v3 UYGULANDI (2026-06-23, get_stats yeni alanları canlıda doğrulandı). Yeni kolon/fonksiyon EKLEMEDİKÇE tekrar çalıştırmak gerekmez.

## Site özellikleri
- Kategoriler (index.html'deki `CATEGORIES` dizisinden tek yerden): **Kolaylaştırılmalı / Yavaş-Performans / Bulması zor / Eksik özellik / Hata-bug**
- Öneri verirken: kategori (zorunlu) + modül (opsiyonel) + "günde ~kaç dk" (opsiyonel)
- İlk açılışta **ZORUNLU tek seferlik profil** (atlanamaz): branş + "SB-AHBS'ye ne zaman geçtiniz" (1 ay içinde / 1-3 ay / 3-6 ay / Element'ten geçtim). İl arayüzden KALDIRILDI; DB'de boş kolon duruyor (geri açmak tek satır).
- panel.html, index'teki "📊 Sonuçlar" linkiyle açılır (hekimlere açık özet sayfası).
- **Oylar deneyime göre ağırlıklı:** sıralamada Element'ten geçen deneyimli hekimlerin desteği daha çok sayar (bkz. Supabase v3).

## DURUM — son güncelleme 2026-06-23

### ✅ Tamamlandı — SİTE YAYINDA
- Kod kurtarıldı; güvenli + kategorili + modüllü + zaman-kayıplı yeniden yazıldı; uçtan uca test edildi (hepsi geçti)
- GitHub'a push'landı: **https://github.com/cagdasaydin5-hub/sbahbs-talep** (dal: `main`)
- **3 yayın-öncesi adımın HEPSİ TAMAM (2026-06-23):**
  1. ✅ Tehlikeli `gece-temizligi` kayıtlı sorgusu Supabase'den silindi
  2. ✅ Test verisi temizlendi (`truncate ideas, participants` — `ideas` boş doğrulandı, anon API `Content-Range: */0`)
  3. ✅ Netlify deploy yapıldı → **CANLI: https://sbahbstalep.netlify.app** (index.html + panel.html). Doğrulandı: index 200 + Supabase ref doğru, panel 200 + get_stats çalışıyor.
- **Site grubu davet etmeye HAZIR.** Temiz veriyle başlıyor.

### 🛠️ Tekrar deploy gerekirse (referans)
- Bu makinelerde netlify CLI/token YOK. Deploy için Netlify **Personal Access Token** üret (User settings → Applications → New access token).
- Komut: `npx netlify-cli deploy --prod --dir <publish> --site 5f523cf5-6aba-4c40-a50f-a4cef7373010` (site `sbahbstalep`).
- **`<publish>` klasörü SADECE `index.html` + `panel.html` içermeli** (NOTLAR.md / setup.sql / backup siteye gitmesin).
- Netlify komutunu repo klasörünün İÇİNDEN çalıştır (CLI o klasöre `.netlify/` artığı bırakır; başka projede çalıştırırsan oraya kirlilik koyar).

### 🔜 Sonraki aşama (veri toplandıktan sonra)
Geri bildirimleri oku → benzerleri grupla → tekrarları birleştir → her maddeyi
**etki (oy × dk × kişi) × düzeltme zorluğu** matrisine diz → Beste Hanım için
"hızlı kazanımlar / orta vadeli / yapısal" öncelik listesi + sunum çıkar.
- Yöntem `ANALIZ-PLANI.md`'de adım adım yazıldı (etki formülü, 1–3 zorluk rubriği, 2×2 matris, sunum iskeleti).
- **panel.html'e analiz konsolu eklendi (2026-06-23):** etki skoru (oy×dk) otomatik; her maddeye grup adı + zorluk (1/2/3) atanıyor → etki×zorluk matrisi kendi diziliyor. Atamalar tarayıcıda (`localStorage`, key `sbahbs_annot_v1`); ⬇/⬆ "Etiketler" ile JSON yedek/taşıma. CSV'ye `etki_skoru, grup, zorluk` kolonları eklendi. DB değişmedi (anon güvenlik aynı).
- ⚠ Bu panel güncellemesi henüz **canlıya deploy EDİLMEDİ** (token yok). `publish/panel.html` güncel; deploy edilince canlıya çıkar.

## Git
Dal `main`, remote `origin` = yukarıdaki GitHub reposu. Her şey commit'li.
Masaüstünde:  `git clone https://github.com/cagdasaydin5-hub/sbahbs-talep.git`
