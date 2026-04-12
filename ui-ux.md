# 🎨 HEAR ME OUT — UI/UX Dokümantasyonu

## 1. Tasarım Felsefesi

| Prensip | Açıklama |
|---------|----------|
| **Erişilebilirlik Öncelikli** | Sağır/dilsiz kullanıcılar için tasarlanmış — görsel geri bildirim, haptic, büyük dokunma alanları |
| **Guest-First** | Kayıt olmadan tüm çeviri özellikleri açık |
| **Offline-First** | İnternetsiz çalışabilmeli |
| **Premium Hissi** | Glassmorphism, animasyonlar, akıcı geçişler |
| **Tek Elle Kullanım** | Acil durumda tek elle erişilebilir |

---

## 2. Navigasyon Yapısı

### Bottom Navigation Bar (5 İkon)

```
┌───────┬───────┬──────────────────┬──────────┬──────┐
│  📚   │  📸   │       🏠          │   🔄    │  👤  │
│Sözlük │Kamera │   [ANA SAYFA]    │Çevirici │Profil│
│       │       │  ↑ BÜYÜK İKON ↑   │         │      │
└───────┴───────┴──────────────────┴──────────┴──────┘
```

- **Ana Sayfa**: Ortada, diğerlerinden büyük ve çıkıntılı (FloatingActionButton tarzı)
- **Kamera & Çevirici**: Ana Sayfa'nın hemen yanlarında — swipe ile de geçilebilir
- **Sözlük & Profil**: Kenarlarda

### Swipe Navigasyon (Ana Özellik)

```
  📸 Kamera  ←──── swipe ────→  🔄 Çevirici
```

- Kamera ve Çevirici arasında `PageView` ile yatay kaydırma
- Üstte nokta göstergesi: ● ○ veya ○ ●
- Alt bar'daki ikonlara basarak da geçiş yapılabilir

### Uygulama Açılış Akışı

```
İlk Açılış:
  Splash (2sn) → Onboarding (3 sayfa) → Ana Sayfa Hub

Sonraki Açılışlar:
  Splash (2sn) → Ana Sayfa Hub (swipe ipuçları ile)
```

---

## 3. Ekran Detayları

### 🚀 Splash Screen
- **Süre**: 2 saniye
- **İçerik**: Lottie animasyonlu logo + "Hear Me Out" yazısı
- **Arka plan**: Gradient (primaryColor → backgroundDark)
- **İşlev**: Model + veri ön yükleme

### 📖 Onboarding (3 Sayfa)
| Sayfa | Başlık | Görsel | Açıklama |
|-------|--------|--------|----------|
| 1 | "İşareti Algılıyoruz" | El + kamera animasyonu | Kameranıza işaret yapın, biz anlayalım |
| 2 | "Sesinizi Çeviriyoruz" | Mikrofon + video animasyonu | Konuşun veya yazın, işaret dilinde gösterelim |
| 3 | "İnternetsiz Çalışır" | Uçak modu ikonu | Her yerde, her zaman kullanın |

- Sayfa göstergesi: ● ○ ○ → ○ ● ○ → ○ ○ ●
- "Atla" linki (sağ üst)
- "Hemen Başla" butonu (son sayfada)

### 🏠 Ana Sayfa Hub

```
┌─────────────────────────────────────────┐
│ Hear Me Out              ⚙️             │  ← AppBar
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────┐    │
│  │  ← İşaret → Metin              │    │  ← Animasyonlu kart
│  │  Kameranızla işaret dilini      │    │    (tıkla veya sola kaydır)
│  │  anlık metne çeviriyoruz        │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  Metin → İşaret →              │    │  ← Animasyonlu kart
│  │  Yazın veya konuşun, işaret     │    │    (tıkla veya sağa kaydır)
│  │  dili videosunu gösterelim      │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  🆘 ACİL DURUM                  │    │  ← Kırmızı pulsing buton
│  │  Sağlık cümlelerine hızlı erişim│    │
│  └─────────────────────────────────┘    │
│                                         │
│  ── Günün Kelimesi ─────────────────    │
│  │ 🤟 "Teşekkür ederim"   ▶️ İzle  │    │
│                                         │
│  ── Son Çeviriler ──────────────────    │
│  │ ağrı │ yardım │ hastane │ >>>   │    │  ← Yatay kaydırmalı
│                                         │
└─────────────────────────────────────────┘
```

### 📸 Kamera Ekranı (İşaret → Metin)

```
┌─────────────────────────────────────────┐
│         ● ○ (sayfa göstergesi)         │
├─────────────────────────────────────────┤
│                                         │
│                                         │
│          KAMERA GÖRÜNTÜSÜ               │
│     (tam ekran, landmark overlay)       │
│                                         │
│     🦴 İskelet çizgiler (opsiyonel)     │
│                                         │
│                                         │
├─────────────────────────────────────────┤
│  ██████████████████░░░░  85%  ✅        │  ← Confidence bar
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐ │
│ │  "Baba geldi ve..."                 │ │  ← Glassmorphism panel
│ │  📋 Kopyala  |  🔊 Sesli Oku       │ │    (yarı şeffaf, cümle modu)
│ │  💾 Kaydet   |  📤 Paylaş          │ │
│ └─────────────────────────────────────┘ │
├─────────────────────────────────────────┤
│  📸 Ön/Arka  |  [ÇEVIRICI İÇIN →]    │
└─────────────────────────────────────────┘

#### Sürekli Çeviri (Cümle Modu) Metin Akışı:
Kullanıcı art arda işaret yaptığında ekrandaki metin şu mantıkla akar:
1. **İlk Kelime**: Büyük harfle başlar ("Baba").
2. **Ekleme**: Sonraki kelimeler sağa küçük harfle eklenir ("Baba", "Baba geldi").
3. **Güven Düzeyi Renklendirme ve Filtreleme (Ayarlanabilir)**: 
   AI'ın kelimeyi bilme oranına (confidence) göre renk ataması yapılır:
   - **Yeşil**: %90+ yüksek güven, kesin doğru kelime.
   - **Sarı / Turuncu**: %80-90 orta güven.
   - **Kırmızı**: %70-80 düşük güven, ucu ucuna kabul. 
   - 🚫 **Yok Sayma (Sınır Altı)**: Tahmin **%75'in altındaysa** ekrana hiçbir kelime yazılmaz, işaret "anlamsız hareket" (garbage) sayılarak çöpe atılır. 
   *(Sadece net ve kesinlik oranı yüksek işaretler kabul edilecektir. Bu asgari %75 barajı, uygulamanın asla yanlış kelime türetmemesini sağlar).*
4. **Taşma (Overflow) ve Temizleme**: Metin kutuya sığmayacak kadar uzadığında (veya satır dolduğunda), ekran temizlenir ancak devam ettiğini belirtmek için `...` ile başlar ve yeni kelime küçük harfle devam eder ("... oturdu").
5. **Cümle Sonu**: Uzun duraksamada cümle tamamlanır ve otomatik noktalanır.
```

### 🔄 Çevirici Ekranı (Metin → İşaret)

```
┌─────────────────────────────────────────┐
│         ○ ● (sayfa göstergesi)         │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  Metin girin veya konuşun...    │    │  ← TextField
│  │                          🎤     │    │  ← Mikrofon butonu
│  └─────────────────────────────────┘    │
│                                         │
│  Öneriler: [ağrı] [yardım] [hastane]   │  ← Autocomplete chip'leri
│                                         │
│  ┌─────────────────────────────────┐    │
│  │                                 │    │
│  │       🎬 VIDEO OYNATICI         │    │  ← İşaret dili videosu
│  │                                 │    │
│  │    ◀◀  ▶️   ▶▶                   │    │  ← Kontroller
│  │    0.5x  1x  1.5x  2x          │    │  ← Hız kontrolü
│  └─────────────────────────────────┘    │
│                                         │
│  [← KAMERA İÇİN]                      │
└─────────────────────────────────────────┘
```

### 🆘 Acil Durum Ekranı

```
┌─────────────────────────────────────────┐
│  ← Geri          ACİL DURUM            │
├─────────────────────────────────────────┤
│                                         │
│  ┌──────────────┐  ┌──────────────┐    │
│  │   😣         │  │   🏥         │    │
│  │  AĞRIM VAR   │  │  HASTANEYE   │    │  ← Büyük dokunma
│  │              │  │  GÖTÜRÜN    │    │    alanları
│  └──────────────┘  └──────────────┘    │
│                                         │
│  ┌──────────────┐  ┌──────────────┐    │
│  │   ⚠️         │  │   🩸         │    │
│  │  ALERJİM VAR │  │  KAN GRUBUM  │    │
│  │              │  │   A+         │    │
│  └──────────────┘  └──────────────┘    │
│                                         │
│  ┌──────────────┐  ┌──────────────┐    │
│  │   💊         │  │   📞         │    │
│  │  İLAÇ        │  │  ACİL KİŞİ  │    │
│  │  KULLANIYORUM│  │  ARAYIN      │    │
│  └──────────────┘  └──────────────┘    │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  🔊 SESSİZCE SÖYLE (TTS)      │    │  ← Tek dokunuşla
│  └─────────────────────────────────┘    │    sesli oku
└─────────────────────────────────────────┘
```

### 📚 Sözlük & Öğren

```
┌─────────────────────────────────────────┐
│  Sözlük                         🔍     │
├──────────────────┬──────────────────────┤
│   Kelimeler      │       Öğren         │  ← TabBar (2 alt tab)
├──────────────────┴──────────────────────┤
│                                         │
│  [Sağlık🏥] [Günlük💬] [Acil🆘] [...]   │  ← Kategori chip'leri
│                                         │
│  ┌────────┐ ┌────────┐ ┌────────┐      │
│  │ 🎬     │ │ 🎬     │ │ 🎬     │      │  ← Grid görünümü
│  │ Ağrı   │ │ Yardım │ │Hastane │      │    (video önizlemeli)
│  │ ⭐     │ │        │ │ ⭐     │      │
│  └────────┘ └────────┘ └────────┘      │
│  ┌────────┐ ┌────────┐ ┌────────┐      │
│  │ 🎬     │ │ 🎬     │ │ 🎬     │      │
│  │ İlaç   │ │ Evet   │ │ Hayır  │      │
│  │        │ │        │ │        │      │
│  └────────┘ └────────┘ └────────┘      │
│                                         │
│  📊 226 kelime | ⭐ 3 favori           │
└─────────────────────────────────────────┘
```

### 👤 Profil Ekranı

```
┌─────────────────────────────────────────┐
│  Profil                                 │
├─────────────────────────────────────────┤
│          ┌──────┐                       │
│          │  👤  │                       │  ← Avatar
│          │      │                       │
│          └──────┘                       │
│      Habil Yazıcı                       │
│      habil@email.com                    │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ 🩸 Sağlık Kartı            →  │    │
│  ├─────────────────────────────────┤    │
│  │ 📜 Çeviri Geçmişi          →  │    │
│  ├─────────────────────────────────┤    │
│  │ ⭐ Favori Kelimeler         →  │    │
│  ├─────────────────────────────────┤    │
│  │ 📊 İstatistikler            →  │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ── İstatistiklerim ────────────────    │
│  │ 🔄 247 çeviri │ 📚 89 kelime   │    │
│  │ 🔥 12 gün streak │ ⭐ 15 fav   │    │
│                                         │
└─────────────────────────────────────────┘
```

---

## 4. Tasarım Sistemi

### Renk Paleti

> **Resmi marka renkleri için bkz:** [brand.md](file:///c:/Users/habil/OneDrive/Belgeler/GitHub/SignLanguageMobileApp/brand.md)

| Renk | HEX | Kullanım |
|------|-----|----------|
| **Primary** | `#1E3A5F` | Ana butonlar, seçili tab, aktif elemanlar |
| **Secondary** | `#4DA8DA` | Vurgu, linkler, aktif göstergeler |
| **Soft Grey** | `#F2F4F7` | Light mode arka plan |
| **Mid Grey** | `#8A94A6` | İkincil metin, placeholder |
| **Dark BG** | `#0F172A` | Koyu tema arka plan |
| **Dark Card** | `#1E293B` | Koyu tema kart |
| **Success** | `#22C55E` | Confidence yeşil (>80%) |
| **Warning** | `#F59E0B` | Confidence sarı (50-80%) |
| **Error** | `#EF4444` | Hata, acil durum, düşük confidence |

### Tipografi

| Stil | Font | Boyut | Ağırlık | Kullanım |
|------|------|-------|---------|----------|
| H1 | Poppins | 28px | Bold | Ekran başlıkları |
| H2 | Poppins | 22px | SemiBold | Bölüm başlıkları |
| H3 | Poppins | 18px | SemiBold | Kart başlıkları |
| Body | Montserrat | 16px | Regular | Genel metin (minimum!) |
| Body Small | Montserrat | 14px | Regular | Alt metinler |
| Caption | Montserrat | 12px | Regular | Etiketler, tarihler |
| Button | Poppins | 16px | SemiBold | Buton metinleri |

### Glassmorphism Kılavuzu
- **Arka plan**: `rgba(255, 255, 255, 0.1)` (koyu temada)
- **Blur**: `sigmaX: 10, sigmaY: 10`
- **Border**: `rgba(255, 255, 255, 0.2)`, 1px
- **Border radius**: 20px
- **Shadow**: `rgba(0, 0, 0, 0.1)`, blur 30, offset y:10

### Animasyonlar ve Mikro-etkileşimler

| Eleman | Animasyon | Süre |
|--------|-----------|------|
| Sayfa geçişi | Slide + Fade | 300ms |
| Kart dokunma | Scale down (0.95) + shadow | 150ms |
| Confidence bar | Smooth width transition | 200ms |
| İşaret tanınma | Haptic + yeşil flash | 100ms |
| Buton hover/press | Color shift + elevation | 150ms |
| Favori ekleme | ⭐ scale bounce | 300ms |
| Acil buton | Pulsing glow (infinite) | 1500ms |
| Swipe ipucu | Fade in/out (ilk açılış) | 2000ms |

---

## 5. Erişilebilirlik Özellikleri

| Özellik | Açıklama |
|---------|----------|
| **Büyük dokunma alanı** | Minimum 48×48 dp tüm interaktif elemanlar |
| **Haptic feedback** | İşaret tanındığında titreşim — sağır kullanıcılar için kritik |
| **Yüksek kontrast modu** | Arka plan/metin kontrastı WCAG AA standardı |
| **Ayarlanabilir font** | 4 kademe: küçük, normal, büyük, çok büyük |
| **Screen reader** | TalkBack (Android) / VoiceOver (iOS) desteği |
| **Renk körlüğü** | Confidence göstergesinde renk + ikon birlikte kullanılır |
| **Tek elle kullanım** | Kritik butonlar ekranın alt yarısında |
| **Otomatik TTS** | İsteğe bağlı otomatik sesli okuma |
