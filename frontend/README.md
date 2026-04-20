# 🤟 Hear Me Out — Türk İşaret Dili (TİD) Mobil Uygulaması

**Hear Me Out**, işitme ve konuşma engelli bireylerin günlük hayatta dijital veya yüz yüze iletişimlerini kolaylaştırmak için geliştirilmiş, gerçek zamanlı yapay zeka destekli bir Flutter mobil uygulamasıdır.

Uygulama temel olarak telefonun kamerasından kişinin ellerini ve vücut hareketlerini izler, bunları anında Türk İşaret Dili (TİD) verisi olarak algılar ve saniyeler içinde ekrana cümleye çevirerek Türkçe olarak seslendirir. 

---

## 🚀 Öne Çıkan Özellikler

*   **Gerçek Zamanlı TİD Algılama (Offline AI):** Cihaz üzerinde çalışan TFLite modeli ile gecikmesiz, internet bağlantısı gerektirmeyen anlık kelime ve hareket tespiti.
*   **Akıllı Cümle Oluşturma ve Seslendirme (TTS):** Tespiti yapılan işaret dilinin yapay zeka (Temporal Smoothing) filtresinden geçirilip ekrana kelime kelime dökülmesi ve tek bir tuşla Türkçe sesli okunması.
*   **İleri Seviye Kamera ve Sensör Yönetimi:** Performans modu (düşük güç tüketimi) veya Yüksek Kalite FPS tercihleri, cihaz ısınmasını önleyen Buffer (Bellek) optimizasyonu.
*   **Geliştirilebilir Ayarlar ve Erişilebilirlik:** Modern karanlık mod (Dark Mode)/açık mod, Sağ/Sol el kullanım desteği, duyusal geri bildirimler (Haptic Feedback) ve çok daha fazlası.
*   **Geliştirici (Dev) Modu:** Yapay zekanın kameradan algıladığı 106 parçalı noktayı (Landmarks) canlı olarak ekranda çizen ve stabilizasyon verisini gösteren özel arayüz.
*   **Sıfır Gecikmeli Başlangıç:** "Native Splash" yapılandırması sayesinde uygulama ikonuna basıldığı anda pürüzsüz yükleme deneyimi.

---

## 🛠 Kullanılan Teknolojiler & Mimari

Bu uygulama, sürdürülebilirlik, ölçeklenebilirlik ve performans gözetilerek **Clean Architecture (Temiz Mimari)** ve **Feature-First (Özellik Tabanlı) Klasör Yapısı** ile kodlanmıştır.

*   **UI/Framework:** Flutter (Material & Glassmorphism UI)
*   **State Management:** Riverpod 
*   **Navigasyon:** GoRouter (Ağaç yapılı modern yönlendirme)
*   **Yapay Zeka (ML) Entegrasyonu:** TFLite Flutter, Google ML Kit (Pose Detection) & hand_detection paketleri
*   **Yerel Veritabanı / Cache:** Shared Preferences
*   **Ses Paketi:** Flutter TTS (Text-to-Speech)

---

## 📦 Kurulum ve Çalıştırma

Geliştirmeye başlamak veya projeyi çalıştırmak oldukça basittir. Ancak öncelikle sisteminizde **Flutter SDK** ve **Android Studio (veya Mac için Xcode)** kurulu olmalıdır.

### 1. Klasörü Çekme ve Bağımlılıklar
Projeyi indirdikten veya klonladıktan sonra `frontend` klasörüne girip şu komutları çalıştırın:
```bash
flutter clean
flutter pub get
```

### 2. Apple / iOS İçin Ekstra Adımlar (Sadece Mac)
Eğer iPhone cihazı veya simülasyonunda test yapacaksanız iOS kütüphanelerinin işletim sistemine bağlanması gerekir:
```bash
cd ios
pod install
cd ..
```

### 3. Uygulamayı Başlatma
Telefonu kabloyla bilgisayara bağlayın (USB Hata Ayıklama veya Developer Mode açık olduğundan emin olun) ve komutu verin:
```bash
flutter run
```

Eğer tam performanslı (kasmayan, ısınmayan) nihai bir APK (Release Mod) çıktısı almak isterseniz:
```bash
flutter build apk --release
```

---

## 📂 Ana Klasör Yapısı (`lib/`)

- `core/`: Tema tipleri, kalıcı renk kodları, sabit değişkenler (Constants), hata yakalayıcılar ve genel ayarlar.
- `features/`: Uygulamanın modüllerinin barındırıldığı yer. Her özellik kendi içinde UI, Data ve Domain klasörlerine ayrılır.
  - `auth/` (Hesap oluşturma ve giriş arayüzleri)
  - `dictionary/` (Sözlük ve video kütüphanesi)
  - `recognition/` (Yapay zekanın kalbi! Kameradan kare okuma, ML tespiti ve ekrana çizdirme yapıları)
  - `settings/` (Tercihler, duyusal geri bildirim ve performans ayarları)
  - `onboarding/` (Uygulamaya ilk giriş slaytları)
- `navigation/`: GoRouter sınıflarını ve ortak navigasyon alt barı (`ScaffoldWithNav`) içeren merkez yapı.

---

> _Uygulama mimarisindeki yapay zeka (ML) verilerinin eğitilmesi ve veri seti koordinat çıkarımı hakkında daha derin teknik bilgi için projenin ana dizinindeki `info/ai` klasörünü inceleyebilirsiniz._
