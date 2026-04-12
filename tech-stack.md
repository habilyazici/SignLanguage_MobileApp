# 🛠️ HEAR ME OUT — Teknoloji Yığını (Tech Stack)

## Tam Teknoloji Haritası

```
┌─────────────────────────────────────────────────────┐
│                    FRONTEND                          │
│  Flutter (Dart) + Riverpod + Material 3 + Go Router │
│  tflite_flutter + MediaPipe + Camera + Lottie       │
│  Hive + SharedPreferences + Dio + flutter_tts       │
├─────────────────────────────────────────────────────┤
│                    BACKEND                           │
│  Node.js + Express + TypeScript + Prisma ORM        │
│  JWT (jsonwebtoken) + bcrypt + Zod + Helmet         │
├─────────────────────────────────────────────────────┤
│                   DATABASE                           │
│  PostgreSQL 16 + Prisma Migrate                     │
├─────────────────────────────────────────────────────┤
│                    AI / ML                           │
│  Python 3.12 + TensorFlow/Keras + MediaPipe         │
│  OpenCV + NumPy + Pandas + Scikit-learn             │
│  TFLite (Deployment) + Google Colab (Training)      │
├─────────────────────────────────────────────────────┤
│                 INFRASTRUCTURE                       │
│  Docker + Docker Compose + Render/Railway (Deploy)  │
│  Google Drive (Dataset) + CDN (Videos)              │
└─────────────────────────────────────────────────────┘
```

---

## Teknoloji Detayları ve Seçim Gerekçeleri

### 1. Mobil Uygulama (Frontend)

| Teknoloji | Versiyon | Neden Seçildi? | Alternatif |
|-----------|----------|----------------|------------|
| **Flutter** | 3.x | Tek kod tabanıyla Android + iOS. Performans, widget zenginliği, topluluk. | React Native, Kotlin/Swift (ayrı geliştirme) |
| **Dart** | 3.x | Flutter'ın dili. Tip güvenli, hızlı derleme, async/await desteği. | — |
| **Riverpod** | 2.x | Compile-time safety, reactive streams, test edilebilirlik. Kamera+AI pipeline için ideal. | Bloc (daha fazla boilerplate), Provider (kısıtlı) |
| **Go Router** | Latest | Deklaratif routing, deep linking, ShellRoute (bottom nav) desteği. | auto_route, Navigator 2.0 (karmaşık) |
| **Dio** | Latest | İnterceptor desteği, JWT otomatik ekleme, timeout kontrolü, retry. | http paketi (daha basit ama yetersiz) |
| **Hive** | 2.x | Hızlı key-value NoSQL, şifreli box, Flutter optimized. | sqflite (SQL gerektiren durumlarda), Isar |
| **Material 3** | Flutter built-in | Google'ın güncel tasarım dili, erişilebilirlik, dynamic color. | Cupertino (sadece iOS görünümü) |

### 2. AI ve Makine Öğrenmesi

| Teknoloji | Versiyon | Neden Seçildi? | Alternatif |
|-----------|----------|----------------|------------|
| **TensorFlow** | 2.x | Model eğitimi için endüstri standardı. TFLite dönüşümü doğal. | PyTorch (TFLite dönüşümü zor) |
| **Keras** | TF içinde | Yüksek seviye API, hızlı prototipleme, LSTM ve Attention desteği. | — |
| **MediaPipe** | Latest | Google'ın gerçek zamanlı landmark algılama çözümü. On-device, hızlı. | OpenPose (daha ağır), custom CNN (çok iş) |
| **TFLite** | TF içinde | On-device inference, quantization, GPU delegate. Tam offline çalışma. | ONNX Runtime (Flutter desteği sınırlı) |
| **tflite_flutter** | Latest | Flutter ↔ TFLite köprüsü. Model yükleme ve inference. | — |
| **OpenCV** | 4.x | Video okuma, kare çıkarma, renk uzayı dönüşümleri. | scikit-image (daha yavaş) |
| **NumPy** | Latest | Yüksek performanslı matris işlemleri, .npy format. | — |
| **Google Colab** | Pro | Ücretsiz/ucuz GPU (A100/L4), Google Drive entegrasyonu. | Kaggle (sınırlı), AWS SageMaker (pahalı) |

#### Neden Flutter + TFLite (On-Device)?
1. **Gecikme**: Sunucuya görüntü gönderip cevap beklemek >500ms. On-device <50ms.
2. **Gizlilik**: Kullanıcının kamera görüntüsü hiçbir sunucuya gitmez.
3. **Offline**: İnternetsiz çalışır — acil durumda hayat kurtarıcı.

#### Neden LSTM + Attention (Model Mimarisi)?
1. **LSTM**: İşaret dili bir zaman serisi — elin hareketi önemli, sadece pozisyonu değil.
2. **Attention**: 60 kare içinde "en kritik" anlara odaklanır, gürültüyü filtreler.
3. **Kanıtlanmış**: Literatürde işaret dili tanımada %94+ başarı.

### 3. Backend

| Teknoloji | Versiyon | Neden Seçildi? | Alternatif |
|-----------|----------|----------------|------------|
| **Node.js** | 20 LTS | JavaScript/TypeScript ekosistemi, hızlı I/O, npm. | Python/FastAPI, Go (daha az ekosistem) |
| **Express** | 4.x | Minimalist, esnek, middleware sistemi, dev community. | Fastify (daha hızlı ama daha az eko), NestJS (over-engineering) |
| **TypeScript** | 5.x | Tip güvenliği, refactoring kolaylığı, IDE desteği. | JavaScript (tip güvenliği yok) |
| **Prisma** | 5.x | Tip güvenli ORM, otomatik migration, şema tabanlı. | TypeORM (daha karmaşık), Sequelize (eski) |
| **PostgreSQL** | 16 | İlişkisel veri, ACID uyumluluk, JSON desteği, performans. | MySQL (daha basit), MongoDB (ilişkisel veri için uygun değil) |
| **JWT** | — | Stateless auth, ölçeklenebilir, mobil uyumlu. | Session-based (stateful, ölçeklenmez) |
| **bcrypt** | — | Şifre hashleme standardı, salt + key stretching. | argon2 (daha güçlü ama daha yavaş) |
| **Zod** | 3.x | TypeScript-first validasyon, schema inference. | Joi (JavaScript odaklı), class-validator |

### 4. Depolama ve Altyapı

| Teknoloji | Kullanım | Neden? |
|-----------|----------|--------|
| **Docker** | Backend konteynerizasyonu | Tutarlı ortam, kolay dağıtım |
| **Docker Compose** | PostgreSQL + API birlikte | Tek komutla çalıştır |
| **Render / Railway** | Backend deploy | Ücretsiz tier, GitHub entegrasyonu, kolay |
| **Google Drive** | Veri seti + model depolama | Colab ile doğal entegrasyon |
| **CDN** | İşaret dili videoları | Hızlı video streaming, edge caching |

### 5. UI Yardımcı Paketler

| Teknoloji | Kullanım | Neden? |
|-----------|----------|--------|
| **Lottie** | Animasyonlar (splash, onboarding, loading) | Hafif, vektör tabanlı, designer-friendly |
| **Shimmer** | Skeleton loading efekti | Profesyonel yükleme deneyimi |
| **flutter_animate** | Micro-animasyonlar | Zincirlenebilir, deklaratif API |
| **Google Fonts** | Modern tipografi (Inter) | 1000+ font, CDN ile yükleme |
| **flutter_tts** | Text-to-Speech | Çevrilen metni sesli okuma |
| **speech_to_text** | Speech-to-Text | Mikrofon → metin (Çevirici) |
| **camera** | Kamera erişimi | Real-time image stream |
| **video_player** + **chewie** | Video oynatma | İşaret dili videoları |
| **vibration** | Haptic feedback | Sağır kullanıcılar için kritik |
| **share_plus** | Metin paylaşma | WhatsApp, SMS vb. |
| **connectivity_plus** | İnternet kontrolü | Offline/online durum yönetimi |
| **permission_handler** | İzin yönetimi | Kamera, mikrofon izinleri |

---

## Versiyon Uyumluluk Tablosu

| Platform | Minimum | Hedef |
|----------|---------|-------|
| Android | API 24 (Android 7.0) | API 34 (Android 14) |
| iOS | 13.0 | 17.0 |
| Flutter SDK | 3.19+ | Latest Stable |
| Dart SDK | 3.3+ | Latest Stable |
| Node.js | 18 LTS | 20 LTS |
| PostgreSQL | 14 | 16 |
