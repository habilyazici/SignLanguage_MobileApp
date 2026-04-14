# 📱 HEAR ME OUT — Flutter Frontend Dokümantasyonu

## 1. Genel Bakış

| Alan | Bilgi |
|------|-------|
| **Framework** | Flutter (Dart) |
| **State Management** | Riverpod |
| **Mimari** | Clean Architecture + Feature-First |
| **Tasarım Sistemi** | Material 3 + Custom Glassmorphism |
| **HTTP Client** | Dio |
| **Yerel Depolama** | Hive + SharedPreferences |
| **AI Inference** | tflite_flutter + MediaPipe |
| **Platform** | Android + iOS |

---

## 2. Neden Riverpod?

| Özellik | Riverpod | Bloc | Provider |
|---------|----------|------|----------|
| Boilerplate | ✅ Az | ❌ Çok (Event+State+Bloc) | ✅ Az |
| Compile-time safety | ✅ | ❌ | ❌ |
| Test edilebilirlik | ✅ Provider override | ✅ | ⚠️ Zor |
| Reactive streams | ✅ StreamProvider | ✅ StreamSubscription | ❌ |
| Flutter dışı kullanım | ✅ | ❌ | ❌ |
| Kamera + AI uyumu | ✅ Doğal | ⚠️ Karmaşık | ❌ |

**Bu proje için kritik avantaj**: Kamera stream + MediaPipe + TFLite inference zinciri tamamen reactive (akışkan) — Riverpod'un `StreamProvider` ve `AsyncNotifierProvider` yapısı bu akış için biçilmiş kaftan.

---

## 3. Klasör Yapısı (Feature-First + Clean Architecture)

```
lib/
├── core/                              # 🔧 Merkezi Ayarlar (Değişmez)
│   ├── constants/
│   │   ├── api_constants.dart         # Backend URL, timeout süresi
│   │   ├── app_strings.dart           # Tüm sabit metinler (i18n hazırlığı)
│   │   ├── asset_paths.dart           # Model dosya yolları, resimler
│   │   └── app_colors.dart            # Renk paleti sabitleri
│   │
│   ├── theme/
│   │   ├── app_theme.dart             # Material 3 ThemeData
│   │   ├── dark_theme.dart            # Koyu tema
│   │   ├── light_theme.dart           # Açık tema
│   │   └── text_styles.dart           # Tipografi sistemi
│   │
│   ├── error/
│   │   ├── failures.dart              # Failure sınıfları (ServerFailure, CacheFailure, vb.)
│   │   └── exceptions.dart            # Exception sınıfları
│   │
│   ├── network/
│   │   ├── dio_client.dart            # Dio instance, interceptors, auth header
│   │   └── network_info.dart          # İnternet bağlantı kontrolü
│   │
│   └── utils/
│       ├── extensions.dart            # Dart extension methods
│       ├── validators.dart            # Form doğrulama fonksiyonları
│       └── haptic_utils.dart          # Titreşim yardımcıları
│
├── features/                          # 💪 Modüler Özellikler
│   │
│   ├── recognition/                   # 📸 İşaret → Metin (Kamera + AI)
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── sign_prediction_model.dart    # JSON ↔ Dart model
│   │   │   ├── repositories/
│   │   │   │   └── sign_recognition_repo_impl.dart
│   │   │   └── sources/
│   │   │       ├── tflite_source.dart             # TFLite interpreter wrapper
│   │   │       └── mediapipe_source.dart           # MediaPipe landmark çıkarma
│   │   │
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── sign_prediction.dart           # Kelime + confidence entity
│   │   │   ├── repositories/
│   │   │   │   └── i_sign_recognition_repo.dart   # Abstract repository
│   │   │   └── use_cases/
│   │   │       ├── recognize_sign_use_case.dart    # Tek kelime tanıma
│   │   │       └── sentence_mode_use_case.dart     # Cümle modu mantığı
│   │   │
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── camera_screen.dart              # Tam ekran kamera UI
│   │       ├── providers/
│   │       │   ├── camera_provider.dart            # Kamera state yönetimi
│   │       │   ├── recognition_provider.dart       # AI tahmin state
│   │       │   └── sentence_buffer_provider.dart   # Cümle tamponu
│   │       └── widgets/
│   │           ├── landmark_overlay.dart           # İskelet çizim katmanı
│   │           ├── confidence_bar.dart             # Yeşil/sarı/kırmızı çubuk
│   │           ├── prediction_text.dart            # Canlı tahmin metni
│   │           └── camera_controls.dart            # Buton grubu (TTS, kaydet vb.)
│   │
│   ├── translator/                    # 🔄 Metin → İşaret (Video Oynatıcı)
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── sign_video_model.dart
│   │   │   └── repositories/
│   │   │       └── translator_repo_impl.dart
│   │   │
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── sign_video.dart
│   │   │   ├── repositories/
│   │   │   │   └── i_translator_repo.dart
│   │   │   └── use_cases/
│   │   │       ├── get_video_use_case.dart         # Tek kelime videosu
│   │   │       └── sentence_video_use_case.dart    # Cümle modu (sıralı video)
│   │   │
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── translator_screen.dart
│   │       ├── providers/
│   │       │   ├── translator_provider.dart
│   │       │   └── speech_to_text_provider.dart    # Mikrofon → metin
│   │       └── widgets/
│   │           ├── text_input_area.dart
│   │           ├── video_player_widget.dart
│   │           ├── autocomplete_suggestions.dart
│   │           └── speed_control.dart
│   │
│   ├── dictionary/                    # 📚 Sözlük
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── word_model.dart
│   │   │   └── repositories/
│   │   │       └── dictionary_repo_impl.dart
│   │   │
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── word_entity.dart
│   │   │   ├── repositories/
│   │   │   │   └── i_dictionary_repo.dart
│   │   │   └── use_cases/
│   │   │       ├── search_word_use_case.dart
│   │   │       └── get_categories_use_case.dart
│   │   │
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── dictionary_screen.dart          # Ana sözlük (kategori filtreli grid)
│   │       │   └── word_detail_screen.dart          # Kelime detayı + video
│   │       ├── providers/
│   │       │   ├── dictionary_provider.dart
│   │       │   └── favorites_provider.dart
│   │       └── widgets/
│   │           ├── word_card.dart
│   │           ├── category_chip.dart
│   │           └── search_bar_widget.dart
│   │

│   ├── home/                          # 🏠 Ana Sayfa Hub
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── home_screen.dart                # Hub + swipe ipuçları
│   │       ├── providers/
│   │       │   └── home_provider.dart
│   │       └── widgets/
│   │           ├── feature_card.dart               # Büyük animasyonlu kartlar
│   │           ├── emergency_button.dart            # Kırmızı pulsing buton
│   │           ├── recent_translations.dart         # Son çeviriler listesi
│   │           ├── word_of_day.dart                 # Günün kelimesi banner
│   │           └── swipe_hint.dart                  # Kaydırma ipuçları
│   │
│   ├── emergency/                     # 🆘 Acil Durum
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── emergency_screen.dart
│   │       └── widgets/
│   │           ├── emergency_phrase_button.dart
│   │           └── health_card_display.dart
│   │
│   ├── profile/                       # 👤 Profil & Hesap
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── user_model.dart
│   │   │   │   └── health_card_model.dart
│   │   │   └── repositories/
│   │   │       └── profile_repo_impl.dart
│   │   │
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── user_entity.dart
│   │   │   │   └── health_card.dart
│   │   │   ├── repositories/
│   │   │   │   └── i_profile_repo.dart
│   │   │   └── use_cases/
│   │   │       ├── login_use_case.dart
│   │   │       ├── register_use_case.dart
│   │   │       └── update_health_card_use_case.dart
│   │   │
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── profile_screen.dart
│   │       │   ├── login_screen.dart
│   │       │   ├── register_screen.dart
│   │       │   ├── health_card_screen.dart
│   │       │   └── translation_history_screen.dart
│   │       ├── providers/
│   │       │   ├── auth_provider.dart
│   │       │   └── profile_provider.dart
│   │       └── widgets/
│   │           ├── avatar_widget.dart
│   │           ├── stats_card.dart
│   │           └── guest_banner.dart
│   │
│   └── settings/                      # ⚙️ Ayarlar
│       └── presentation/
│           ├── screens/
│           │   └── settings_screen.dart
│           ├── providers/
│           │   └── settings_provider.dart
│           └── widgets/
│               ├── setting_tile.dart
│               ├── theme_selector.dart
│               └── landmark_color_picker.dart
│
├── shared/                            # 🔗 Ortak Bileşenler
│   ├── widgets/
│   │   ├── custom_button.dart
│   │   ├── loading_indicator.dart
│   │   ├── error_widget.dart
│   │   ├── glassmorphism_card.dart
│   │   ├── custom_app_bar.dart
│   │   └── animated_page_indicator.dart
│   │
│   └── services/
│       ├── tts_service.dart           # Text-to-Speech servisi
│       ├── stt_service.dart           # Speech-to-Text servisi
│       ├── haptic_service.dart        # Titreşim servisi
│       └── cache_service.dart         # Video cache yönetimi
│
├── navigation/
│   ├── app_router.dart                # Route tanımları
│   └── main_shell.dart                # Bottom nav + PageView shell
│
└── main.dart                          # ProviderScope + App Entry
```

---

## 4. Temel Widget Tree

```
MaterialApp (Riverpod ProviderScope)
└── MainShell (Scaffold + BottomNavigationBar)
    ├── BottomNav: [Sözlük, Kamera, ANA SAYFA(FAB), Çevirici, Profil]
    │
    ├── Tab: Sözlük → DictionaryScreen
    │   └── Kelimeler → GridView + SearchBar + Kategori filtresi
    │
    ├── Tab: PageView (2 sayfa — swipe ile geçiş)
    │   ├── Sayfa 0: CameraScreen (İşaret→Metin)
    │   │   ├── CameraPreview
    │   │   ├── LandmarkOverlay (CustomPainter)
    │   │   ├── PredictionText (yarı-şeffaf panel)
    │   │   ├── ConfidenceBar
    │   │   └── CameraControls (TTS, Kaydet, Kopyala)
    │   │
    │   └── Sayfa 1: TranslatorScreen (Metin→İşaret)
    │       ├── TextInputArea + MicButton
    │       ├── AutocompleteSuggestions
    │       └── VideoPlayerWidget
    │
    ├── FAB (Ortada, büyük) → HomeScreen
    │   └── (BottomNav orta butonu olarak "/home" route'una navige eder)
    │   ├── FeatureCards (2 animasyonlu kart)
    │   ├── EmergencyButton (kırmızı pulsing)
    │   ├── RecentTranslations
    │   └── WordOfDay
    │
    └── Tab: Profil → ProfileScreen
        ├── GuestBanner veya UserInfo
        ├── HealthCard
        ├── TranslationHistory
        ├── Favorites
        └── Stats
```

---

## 5. Paket Listesi (pubspec.yaml)

### Core
| Paket | Kullanım |
|-------|----------|
| `flutter_riverpod` | State management |
| `riverpod_annotation` + `riverpod_generator` | Code generation |
| `go_router` | Deklaratif routing |
| `dio` | HTTP istekleri |
| `freezed` + `json_serializable` | Immutable model sınıfları |

### AI & Kamera
| Paket | Kullanım |
|-------|----------|
| `camera` | Kamera erişimi ve stream |
| `tflite_flutter` | TFLite model inference |
| `google_mlkit_pose_detection` | MediaPipe landmark (veya `mediapipe_flutter`) |
| `image` | Görüntü format dönüşümleri |

### UI & Animasyon
| Paket | Kullanım |
|-------|----------|
| `lottie` | Splash, onboarding, loading animasyonları |
| `shimmer` | Skeleton loading efekti |
| `flutter_animate` | Micro-animasyonlar |
| `google_fonts` | Modern tipografi (Inter, Outfit vb.) |
| `flutter_svg` | SVG ikon desteği |
| `cached_network_image` | Ağ resimlerini cache'leme |

### Ses & Konuşma
| Paket | Kullanım |
|-------|----------|
| `flutter_tts` | Text-to-Speech |
| `speech_to_text` | Speech-to-Text (mikrofon) |

### Depolama
| Paket | Kullanım |
|-------|----------|
| `hive` + `hive_flutter` | Yerel key-value depolama |
| `shared_preferences` | Basit ayarlar (tema, onboarding durumu) |
| `flutter_cache_manager` | Video cache yönetimi |

### Video
| Paket | Kullanım |
|-------|----------|
| `video_player` | İşaret dili videoları oynatma |
| `chewie` | Video player UI wrapper |

### Utility
| Paket | Kullanım |
|-------|----------|
| `connectivity_plus` | İnternet bağlantı kontrolü |
| `vibration` | Haptic feedback |
| `share_plus` | Metin paylaşma (WhatsApp vb.) |
| `permission_handler` | Kamera/mikrofon izinleri |
| `flutter_local_notifications` | Bildirimler (günün kelimesi) |

---

## 6. Kamera → AI Pipeline Akışı

```
CameraController (ResolutionPreset.medium, YUV420)
        ↓ startImageStream
compute(processFrame) → ayrı Isolate (UI donmaz)
        ↓ MediaPipe → 53 landmark → 106 float
SlidingWindowBuffer (son 60 kare)
        ↓ buffer.isFull → her 5 karede bir
TFLite .run([1, 60, 106]) → argmax + confidence
        ↓ Riverpod state güncelleme → UI
```

---

## 7. Tema ve Tasarım Sistemi

> Renk paleti, tipografi ve UI stili için bkz: [brand.md](./brand.md)

---

## 8. Navigasyon Yapısı (go_router)

| Route | Ekran | İçerik |
|-------|-------|--------|
| `/splash` | SplashScreen | Model + veri ön yükleme |
| `/onboarding` | OnboardingScreen | 3 sayfa, ilk açılış |
| `/home` | HomeScreen | Hub (ShellRoute) |
| `/dictionary` | DictionaryScreen | Sözlük + Öğren tab |
| `/camera` | CameraScreen | İşaret → Metin |
| `/translator` | TranslatorScreen | Metin → İşaret |
| `/profile` | ProfileScreen | Profil, sağlık kartı |
| `/settings` | SettingsScreen | Ayarlar |
| `/emergency` | EmergencyScreen | Acil durum |
| `/word/:id` | WordDetailScreen | Kelime detayı |
