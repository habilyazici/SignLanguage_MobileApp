# 🎨 HEAR ME OUT — UI/UX Kodlama Kılavuzu

## 1. Navigasyon

**Bottom Navigation (GoRouter ShellRoute):**
- **[Ortada Büyük İkon]:** Ana Sayfa (Hub)
- **Sol Taraf:** Sözlük, Kamera (İşaret → Metin)
- **Sağ Taraf:** Çevirici (Metin → İşaret), Profil

**Kamera <-> Çevirici Kesintisiz Geçişi:**
Kamera ve Çevirici arasında yatay kaydırma (`PageView`) ile swipe desteği.

## 2. Ekran Şemaları

**Splash / Onboarding**
- 2 sn Splash -> 3 adım Onboarding -> Hub. 
- İlk kullanıcılar için swipe tutorial overlay.

**Hub (Ana Sayfa)**
- Çeviri modlarına giden Swipe yönlendirmeli dev butonlar.
- **Günün Kelimesi** dinamik komponenti.
- **Acil Durum Modu:** Kırmızı renkli, pulsating acil durum butonları ('Ağrım Var', 'Alerjim Var', 'Kan Grubu').

**İşaret -> Metin (Kamera)**
- Tam ekran vizör. Üstünde (seviye/geçiş) indikatörler.
- Glassmorphism stili ile çeviri text bar'ı.
- Confidence Score bar: `≥90% Yeşil, 80-90% Sarı, 70-80% Kırmızı`.
- Kelime kuyruklama / Cümle build etme opsiyonları paneli (TTS buton, Panoya al, Paylaş).

**Metin -> İşaret (Çevirici)**
- Metin Input + STT mikrofon butonu + Auto-complete suggestions.
- Üstte eşleşen videoyu (MP4/GIF) gösteren full genişlikli video player (Playback speed kontrollü).

**Sözlük**
- Kategori Chip dizilimi (Sağlık, Günlük, vs.)
- Önizlemeli ızgara liste `GridView`.
- Arama barı + Favori ekleme etkileşimleri.

**Ayarlar Merkezi (Settings)**
Ayarlar menüsü kullanıcının ihtiyacına göre şekillenebilen kapsamlı ve kategorize edilmiş bir yapıya sahiptir:
- **Genel Cihaz & Görünüm:**
  - Tema (Sistem / Koyu / Açık Mode)
  - Uygulama Metin Boyutu (Dinamik tipografi: Standart / Büyük / Ekstra Büyük)
  - Solak Modu (Kamera deklanşörünü ve ana UI butonlarını sola hizalar)
- **Kamera & Yapay Zeka (AI) Optimizasyonları:**
  - Çeviri Hassasiyet Eşiği (Düşük/Orta/Yüksek - Modelin el hareketlerini ne kadar tolere edeceği)
  - Çerçeve Hızı (FPS) Limitörü (Batarya çok ısındığında veya düşük güç modunda kamerayı 30FPS'den 15FPS'e sabitleme)
  - Haptic Feedback (Titreşim) Kalibrasyonu (Aç/Kapat veya Yoğunluk Seviyesi)
- **Veri Kullanımı & Video Sunucusu (Backend Streaming):**
  - Hücresel Veride Video Oynatmayı Devre Dışı Bırak (Backend'den video çekerken data tasarrufu)
  - Video Kalitesi Seçimi (Yüksek 720p / Veri Tasarrufu 360p)
  - Local Cache (Önbellek) Yönetimi: Cihaz hafızası doluluğa göre limit atama ve "Önbelleği Temizle" seçeneği. (Videolar şuanlık backend'de duracağı için streaming yaparken cihazda cache birikimini yönetir).
- **Gizlilik & Veri Kontrolü:**
  - Sıfır-Veri Modu: Çeviri geçmişini (history) lokalde bile tutmaz.
  - Bulut Eşzamanlaması (Ayarları ve Sağlık Kartını hesabınıza senkronize edin/kapatın).
  - Hesabı tamamen sil ve tüm verilerimi indir (GDPR/KVKK gereksinimleri).

**Profil & Sağlık Kartı**
- Ad/Soyad, Acil durum telefonu, sağlık notları. ve ...

## 3. Tasarım Notları (Design System Specs)
*(Referans kodlama)*
- **Glassmorphism Spec:** `Color(0x1AFFFFFF)`, `ImageFilter.blur(sigmaX: 10, sigmaY: 10)`, `BorderRadius.circular(20)`
- **Erişilebilirlik:** Touch targets min `48x48`. State değişiklikleri (başarılı inference, hata) Haptic Feedback ve Toast ile güçlendirilmeli.
- **Tipografi:** Google Fonts `Inter`.
