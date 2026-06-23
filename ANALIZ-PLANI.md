# SBAHBS Geri Bildirim — Analiz & Sunum Planı

> Veri toplandıktan sonra uygulanacak adım adım yöntem. Amaç: ham geri bildirimleri
> **Beste Kaya Varmış**'a sunulacak önceliklendirilmiş bir aksiyon listesine çevirmek.
> Panelden alınan CSV kolonları: `id, category, module, votes, minutes, bransh, gecis, created_at, text`.

---

## 0. Veriyi al
1. `panel.html` → **⬇ Excel (CSV)** → `sbahbs-geribildirim.csv`.
2. CSV'yi Excel/Google Sheets'e aç (BOM'lu, Türkçe karakterler düzgün gelir).
3. Yanına 3 boş kolon ekle: **`grup`**, **`zorluk`**, **`not`** (analiz bu kolonlarda yapılacak).

---

## 1. Temizle & grupla (elle)
Aynı şeyin farklı kelimelerle yazılmış halleri ayrı satırlardır. Bunları birleştirmek şart.
- Her satırı oku, **aynı sorunu** anlatanlara ortak bir `grup` etiketi ver (örn. `recete-yenileme`, `arama-yavas`).
- Bir grubun **etkisi = o gruptaki tüm satırların oyları + dakikaları TOPLAMI** (tek tek değil).
- Çöp/spam/anlamsız satırları `not = ele` ile işaretle, skora katma.
- Modülü boş ama metinden belli olanların `module` değerini elle doldur (sıcak nokta haritası netleşsin).

---

## 2. Etki skoru (veriden hesaplanır)
İki boyutu da kullan; biri yaygınlık, biri zaman.

| Ölçü | Formül | Anlamı |
|---|---|---|
| **Yaygınlık** | grubun toplam **oy**'u | Kaç hekim bu derdi onayladı |
| **Zaman etkisi** | Σ (`votes` × `minutes`) | Günlük toplam kayıp dakika (beyan) |

- `minutes` boşsa zaman etkisi için **1 dk** say (yani sadece oy ağırlığı kalır) — madde yine de yaygınlıkla sıralanır.
- **Birincil sıralama oy'a göre**; eşitlikte zaman etkisi büyük olan öne.
- Panel zaten "oyla ağırlıklı toplam günlük zaman kaybı"nı (`Σ votes×minutes / 60` saat) hesaplıyor → sunumdaki tek büyük rakam bu. **"Katılımcı beyanı, tahmindir"** notu mutlaka düşülecek.

---

## 3. Zorluk skoru (elle — veri yok, yargı gerekir)
DB'de zorluk bilgisi YOK. Her grubu içeriğe bakıp 1–3 arası etiketle (`zorluk` kolonu):

| Zorluk | Ne demek | Örnek | Tahmini efor |
|---|---|---|---|
| **1 — Kolay** | Arayüz/metin/varsayılan | Etiket değişimi, buton yeri, kısayol, uyarı metni, varsayılan değer | gün–hafta |
| **2 — Orta** | Akış/ekran/rapor | Yeni alan/filtre, ekran düzeni, adım ekleme/çıkarma, yeni rapor | hafta–ay |
| **3 — Zor / Yapısal** | Mimari/entegrasyon/paydaş | Veri modeli, e-Nabız/MEDULA entegrasyonu, başka kurum bağımlılığı | ay+ / çok paydaşlı |

> İpucu: `category = Hata / Bug` çoğu zaman 1–2; `Eksik özellik` 2–3; `Yavaş / Performans` çoğu zaman 2–3 (altyapı). Ama kuralı içerik belirler, kategori değil.

---

## 4. Önceliklendirme matrisi (etki × zorluk)
Her grubu şu 2×2'ye yerleştir:

```
              KOLAY (1)            ZOR/YAPISAL (3)
        ┌─────────────────────┬─────────────────────┐
YÜKSEK  │  ⭐ HIZLI KAZANIM   │  🏗 YAPISAL          │
ETKİ    │  (hemen yap)        │  (yol haritası)      │
        ├─────────────────────┼─────────────────────┤
DÜŞÜK   │  ◽ Dolgu            │  ⛔ Erteleme         │
ETKİ    │  (vakit olursa)     │  (şimdilik yapma)    │
        └─────────────────────┴─────────────────────┘
```
- **⭐ Hızlı kazanım** = yüksek oy + zorluk 1 → sunumun yıldızı, "haftalarda çözülür".
- **🏗 Yapısal** = yüksek oy + zorluk 3 → yol haritası/iş planı gerektirir, beklenti yönetimi.
- **◽ Dolgu** = düşük oy + kolay → toplu halde "ufak iyileştirmeler" paketi.
- **⛔ Erteleme** = düşük oy + zor → listede ama en sonda.

Çıktı: her kova için oy sırasına dizili madde listesi.

---

## 5. Beste Hanım'a sunum iskeleti
1. **Kapak + yöntem** — kaç hekim katıldı, kaç madde, nasıl toplandı (anonim, oylamalı), tarih aralığı.
2. **Yönetici özeti (1 slayt)** — en kritik 3–5 ⭐ hızlı kazanım + tek büyük rakam (günlük ~X saat beyan edilen kayıp).
3. **Etki × zorluk matrisi** — yukarıdaki 2×2 görseli, kovalardaki madde sayısıyla.
4. **⭐ Hızlı kazanımlar** — tablo: madde · oy · ~dk/gün · modül · tahmini efor.
5. **🏗 Yapısal başlıklar** — yol haritası önerisiyle (kısa/orta/uzun vade).
6. **Modül sıcak nokta haritası** — sorun hangi ekranlarda yoğunlaşıyor (paneldeki modül grafiği).
7. **Zaman kaybı tahmini** — "katılımcı beyanı" vurgusuyla.
8. **Ek** — tam madde listesi / CSV bağlantısı.

---

## 6. Kalite kontrol (sunumdan önce)
- [ ] Her madde bir gruba bağlı mı? (tekil satır kalmasın)
- [ ] Çöp/spam ayıklandı mı?
- [ ] Zorluk skorları tutarlı mı? (benzer işlere benzer skor)
- [ ] Zaman rakamının yanında "beyan / tahmin" notu var mı?
- [ ] En üstteki 5 maddenin metni anonim ve nötr mü? (hekim/hasta kimliği sızmasın)
- [ ] Sayılar panelle uyuşuyor mu? (toplam oy, katılımcı sayısı)

---

## 7. İsteğe bağlı otomasyon (sonra)
Panel'e (`panel.html`) eklenebilecekler — istenirse yapılır:
- Her maddeye **"etki skoru"** kolonu (oy × dk) + buna göre sıralama.
- CSV export'a `etki_skoru` kolonu eklemek → Excel'de elle hesap gerekmez.
- Modül × kategori çapraz tablosu.
> Zorluk skoru otomatikleştirilemez (içerik yargısı gerektirir) — o elle kalır.
