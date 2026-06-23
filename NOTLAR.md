# SBAHBS Geri Bildirim — Kurulum Notları

Tek dosyalık statik site (HTML+CSS+JS). Sunucu/derleme gerekmez.

## Dosyalar
- `index.html` — sitenin kendisi (kategorili, güvenli sürüm)
- `setup.sql` — yeni Supabase projesinde bir kez çalıştırılacak kurulum
- `index.original-backup.html` — Netlify'dan kurtarılan ESKİ sürümün yedeği

## Kullanılan Supabase projesi
- **Proje:** `vbobeqgambooxtfefxmd` (hesapta zaten mevcut, e-Derslik'ten ayrı proje)
- `index.html` içindeki `SUPABASE_URL` ve `SUPABASE_KEY` zaten dolu (anon key halka açıktır).

## Kurulum (bir kez)
1. Supabase → `vbobeqgambooxtfefxmd` projesi → **SQL Editor**.
2. `setup.sql` içeriğini yapıştır → **Run**.
   (Güvenle tekrar çalıştırılabilir; mevcut tabloyu silmez, eksik `category` kolonunu
   ekler ve güvenli fonksiyonları kurar.)

## Yayına alma (Netlify)
- En basit: Netlify panelinde mevcut `sbahbstalep` sitesine bu klasörü/`index.html`'i sürükle-bırak.
- Veya: git reposuna bağlayıp otomatik deploy.

## Güvenlik mantığı
- Doktorlar yalnızca **okuyabilir + fonksiyonla ekleyebilir/oylayabilir**.
- Doğrudan UPDATE/DELETE kapalı → kimse başkasının yazısını değiştiremez/silemez, sahte oy basamaz.
- Yazılan metin ekranda kaçışlanır (XSS koruması).
- Eski sürümdeki "2 günde bir az oylu önerileri sil" otomatiği KALDIRILDI (veri kaybını önlemek için).
