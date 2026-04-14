# 📋 HEAR ME OUT — Proje Genel Bakış

## 1. Proje Kimliği

| Alan | Bilgi |
|------|-------|
| **Proje Adı** | Hear Me Out |
| **Mimar** | Habil Yazıcı |
| **Konu** | Sağlık Teknolojileri & Engelli Erişilebilirliği |
| **Hedef Kitle** | İşitme/Konuşma Engelli Bireyler & Yakınları |
| **Platform** | Android + iOS (Flutter Cross-Platform) |
| **Çalışma Modu** | Offline-First (İnternetsiz çalışabilir) |
| **Felsefe** | Guest-First (Kayıt olmadan tüm çeviri özellikleri açık) |

---

## 2. Vizyon ve Problem Tanımı

### Problem
Geleneksel iletişim araçları, işaret dili bilmeyen bireylerle işitme/konuşma engelliler arasında büyük bir bariyer oluşturur. Özellikle **acil sağlık durumlarında** bu bariyer hayati risk taşır — bir sağır birey acil serviste ağrısını, alerjisini veya kan grubunu karşısındaki kişiye anlık olarak iletemez.

### Çözüm
Hear Me Out, mobil cihazın kamerasını ve mikrofonunu birer **"tercümana"** dönüştürür:

1. **İşaret → Metin/Ses**: Kullanıcı kameraya işaret dili yapar → AI gerçek zamanlı olarak metne çevirir → İsteğe bağlı sesli okuma (TTS)
2. **Metin/Ses → İşaret**: Karşıdaki kişi yazar veya konuşur → Uygulama işaret dili videosunu oynatır

### Sağlık Odak Noktası
- Acil durumlar (ağrı tarifleme, alerji bildirme)
- Hastane randevuları
- Eczane iletişimi
- Temel sağlık ihtiyaçlarının anlık iletilmesi

---

## 3. Mimari Büyük Resim

```
┌──────────────────────────────────────────────────────────┐
│                     FLUTTER (On-Device)                   │
│                                                           │
│  ┌──────────┐    ┌────────────┐    ┌──────────────────┐  │
│  │  Kamera   │───▶│ MediaPipe  │───▶│  TFLite Model    │  │
│  │  30 FPS   │    │ 106 coord  │    │  LSTM + Attention│  │
│  └──────────┘    └────────────┘    └────────┬─────────┘  │
│                                              │            │
│                                    "ağrı" kelimesi        │
│                                              │            │
│  ┌───────────────────────────────────────────▼─────────┐  │
│  │              UI (Material 3 + Glassmorphism)        │  │
│  │     Metin gösterimi + TTS + Haptic Feedback         │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                           │
│  ┌─────────────────┐    ┌──────────────────────────────┐  │
│  │  Hive (Local DB) │    │  Dio (HTTP Client)          │  │
│  │  • Favoriler     │    │  ↕ Backend (opsiyonel)      │  │
│  │  • Ayarlar       │    │  ↕ Sadece gerektiğinde      │  │
│  │  • Geçmiş        │    └─────────────┬──────────────┘  │
│  └─────────────────┘                   │                  │
└────────────────────────────────────────┼──────────────────┘
                                         │ (internet varsa)
                                         ▼
┌──────────────────────────────────────────────────────────┐
│               BACKEND (Node.js + Express)                 │
│                                                           │
│  • Kullanıcı kaydı / giriş (JWT Auth)                    │
│  • Çeviri geçmişi kaydetme                               │
│  • Sağlık kartı bilgileri (KVKK uyumlu)                  │
│  • İşaret dili video URL'leri (Sözlük CDN)               │
│  • Model güncelleme (gelecekte OTA)                      │
│  • PostgreSQL + Prisma ORM                                │
└──────────────────────────────────────────────────────────┘
```

### Mimari Prensipler
- **Clean Architecture**: Data → Domain → Presentation katmanları ayrı
- **Feature-First**: Her özellik kendi klasöründe izole yaşar
- **Offline-First**: Çekirdek AI tamamen cihaz üzerinde, backend opsiyonel
- **Guest-First**: Kayıt olmadan tüm çeviri özellikleri erişilebilir

---

## 4. Çift Yönlü İletişim Akışı

### Akış 1: İşaret Dili → Metin/Ses (Kamera)
```
Kullanıcı işaret yapar
        ↓
Kamera 30 FPS yakalama
        ↓
MediaPipe: 53 landmark → 106 koordinat (x, y)
        ↓
60 karelik sliding window oluştur
        ↓
TFLite LSTM+Attention modeli tahmin eder
        ↓
Confidence score kontrolü (bkz. `ai-ml.md` Bölüm 9 — Canonical Eşik Tablosu)
   ├── ≥ %90 (yeşil): Kelimeyi göster + haptic feedback
   ├── %80–90 (sarı): Kelimeyi göster
   ├── %70–80 (kırmızı): Kelimeyi göster + uyarı ikonu
   └── < %70: "Emin değilim" — atla
        ↓
Cümle Modu: Kelimeler tampona eklenir → cümle oluşturulur
        ↓
[Opsiyonel] TTS ile sesli okuma
```

### Akış 2: Metin/Ses → İşaret Dili (Çevirici)
```
Kullanıcı metin yazar veya konuşur (STT)
        ↓
Metin kelimelere ayrılır
        ↓
Her kelime sözlükte aranır
   ├── Bulundu: İşaret dili videosu oynatılır
   └── Bulunamadı: "Sözlükte yok" + alternatif önerileri
        ↓
Cümle Modu: Videolar sırayla oynatılır
```

---

## 5. Proje Aşamaları ve Mevcut Durum

| Aşama | Durum | Açıklama |
|-------|-------|----------|
| 📊 Veri Seti Hazırlık | ✅ Tamamlandı | AUTSL veri seti seçildi (226 sınıf, ~36K video) |
| 🔧 Feature Extraction | 🔄 Devam Ediyor | MediaPipe ile koordinat çıkarma işlemi |
| 🧠 Model Eğitimi | ⏳ Bekliyor | LSTM + Multi-Head Attention (Colab üzerinde) |
| 📱 Flutter Frontend | ⏳ Bekliyor | Sıfırdan başlanacak |
| 💻 Node.js Backend | ⏳ Bekliyor | Sıfırdan başlanacak |
| 🧪 Test & Optimizasyon | ⏳ Bekliyor | TFLite dönüşüm + mobil test |
| 🚀 Deploy | ⏳ Bekliyor | Play Store / App Store |

---

## 6. İlgili Dokümantasyon

| Dosya | İçerik |
|-------|--------|
| `ai-ml.md` | Yapay zeka modeli, veri pipeline, eğitim stratejisi |
| `flutter.md` | Frontend mimarisi, Riverpod, klasör yapısı, paketler |
| `backend.md` | Node.js API, Express, middleware yapısı |
| `database.md` | PostgreSQL tabloları, Prisma şeması |
| `ui-ux.md` | Ekran tasarımları, navigasyon, kullanıcı akışları |
| `security.md` | KVKK, şifreleme, veri güvenliği |
| `tech-stack.md` | Tüm teknolojiler ve seçim gerekçeleri |
