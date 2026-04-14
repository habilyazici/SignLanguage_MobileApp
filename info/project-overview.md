# 📋 HEAR ME OUT — Proje Genel Bakış

## 1. Proje Kimliği

| Alan | Bilgi |
|------|-------|
| **Proje Adı** | Hear Me Out |
| **Konu** | Sağlık Teknolojileri & Engelli Erişilebilirliği |
| **Hedef Kitle** | İşitme/Konuşma Engelli Bireyler & Yakınları |
| **Platform** | Android + iOS (Flutter Cross-Platform) |
| **Çalışma Modu** | Offline-First (İnternetsiz çalışabilir) |
| **Felsefe** | Guest-First (Kayıt olmadan hesap gerektirmeden çeviri) |

## 2. Amaç
İşitme/konuşma engelli bireylerin acil sağlık durumlarında (ağrı, alerji, hastane işlemleri) doktor ve sağlık personeli ile anlık iletişim kurmasını sağlayan iki yönlü bir çeviri asistanı.

## 3. Mimari Büyük Resim

```text
┌──────────────────────────────────────────────┐
│                    FLUTTER                   │
│  [Kamera] -> [MediaPipe] -> [TFLite Model]   │
│                 (offline)                    │
│                     ↓                        │
│             [UI & Metin/Ses]                 │
│                     ↕                        │
│            [Hive Local Data]                 │
└─────────────────────┬────────────────────────┘
                      │ (opsiyonel)
┌─────────────────────▼────────────────────────┐
│                   BACKEND                    │
│      [Node.js API] <-> [PostgreSQL DB]       │
└──────────────────────────────────────────────┘
```

**Prensipler:**
- **Clean Architecture:** Data → Domain → Presentation katman izalasyonu.
- **Feature-First Modülerlik:** Hedef feature'a özel klasörleme.
- **Offline-First:** Model inference on-device (TFLite) yapılarak internet gereksinimi kaldırılmıştır. Çeviriler ve history local (Hive) üzerinden çalışır.

## 4. İletişim Akışı

### Akış 1: İşaret Dili → Metin/Ses (Kamera)
1. **Giriş:** Kamera 30FPS akış yakalar.
2. **Landmark Extraction:** MediaPipe cihaz üzerinde frame'den yüz, vücut, el landmark coordinatlarını çıkarır (53 landmark -> 106 koordinat (x,y)).
3. **Pipeline:** 60 frame'lik sekans penceresi oluşturulur.
4. **Tahmin:** TFLite (LSTM + Attention) modeli prediction üretir.
5. **Threshold:**
   - Yeşil (≥ 90%): Göster ve Haptic feedback.
   - Sarı (80-90%): Sadece göster.
   - Kırmızı (70-80%): Göster + uyarı ikon.
6. **Çıkış:** Kelime cümleye eklenir, süreklilik halinde otomatik TTS ile seslendirilir.

### Akış 2: Metin/Ses → İşaret Dili (Çevirici)
1. **Giriş:** Kullanıcı text yazar veya STT (Speech-to-Text) kullanır.
2. **İşleme:** Metin parsellenir, lookup yapılır.
3. **Çıkış:** İlgili işaret dili MP4/GIF referans videoları UI'da sırayla oynatılır.