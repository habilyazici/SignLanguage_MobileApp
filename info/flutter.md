# 📱 HEAR ME OUT — Flutter Mimari Notları

## 1. Temel Stack
- **Framework:** Flutter (Dart).
- **Core Packages:** `flutter_riverpod` (State), `go_router` (Routing), `dio` (API), `hive_flutter` (Storage).
- **AI & OS Bridge:** `camera`, `tflite_flutter`, `google_mlkit_pose_detection`, `flutter_tts`, `speech_to_text`.
- **UI:** `shimmer`, `flutter_animate`.

## 2. Dizin Organizasyonu (Feature-First)
Her feature, Presentation, Domain, ve Data katmanlarını tek çatı altında barındırır.
```text
lib/
 ├─ core/
 │   ├─ constants/ (API_URL, strings, colors, asset yolları)
 │   ├─ theme/     (M3 theme configurations, glassmorphism statics)
 │   ├─ network/   (Dio instance)
 │   └─ utils/     
 ├─ shared/        (Global widgetlar, global tts, cache servisleri)
 ├─ navigation/    (GoRouter configuration)
 └─ features/
     ├─ recognition/   (Kamera, Tflite, LandmarkOverlay, Confidence buffer)
     ├─ translator/    (VideoPlayer, STT/Text Input UI)
     ├─ dictionary/    
     ├─ emergency/     (Sağlık kartı display modülü, Acil durum ekranı)
     ├─ profile/       
     ├─ home/          
     └─ settings/      
```

## 3. GoRouter Şeması
- `/splash` 
- `/onboarding`
- `/home` (Shell Route Root)
- `/dictionary` (Tab)
- `/çeviri` (Tab)
- `/translator` (Tab)
- `/profile` (Tab)
- `/settings`
- `/emergency`
- `/word/:id` 

## 4. Video Akışı & Backend Hosting Stratejisi
Projenin boyutunu devasa boyutlara ulaştırmamak adına **"Metin -> İşaret" çevirisinde kullanılan MP4/GIF videoları şuanlık tamamen Backend üzerinde tutulacaktır.** 
- **Streaming & Cache:** API'dan video linkleri istendikten sonra oynatıcıya verilir ve süreçte `flutter_cache_manager` devreye girer. Bu sayede ilk defa izlenen video Backend üzerinden aktarılır (stream edilir), eğer aynı kelime daha sonra tekrar aranırsa Backend'e çıkılmaz, direkt olarak cihazın local Cache (Önbellek) klasöründen oynatılarak veri tasarrufu yapılır.
- **Cache Temizliği:** Kullanıcı ayarlar üzerinden bu cache birikintilerini "Ayarlar -> Önbelleği Temizle" komutuyla boşaltabilir. Cache Manager default olarak LRU (Least Recently Used) algoritmasıyla doluluk limitine geldiğinde en eski izlenenleri (storage hit) temizler.
