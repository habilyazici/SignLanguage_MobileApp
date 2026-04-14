# 🛠️ HEAR ME OUT — Teknoloji Yığını

## Tam Teknoloji Haritası

```text
┌─────────────────────────────────────────────────────┐
│                    FRONTEND                         │
│  Flutter (Dart) + Riverpod + Material 3 + Go Router │
│  tflite_flutter + MediaPipe + Camera                │
│  Hive + SharedPreferences + Dio + flutter_tts       │
├─────────────────────────────────────────────────────┤
│                    BACKEND                          │
│  Node.js + Express + TypeScript + Prisma ORM        │
│  JWT + bcrypt + Zod + Helmet                        │
├─────────────────────────────────────────────────────┤
│                   DATABASE                          │
│  PostgreSQL 16 + Prisma Migrate                     │
├─────────────────────────────────────────────────────┤
│                    AI / ML                          │
│  Python 3.12 + TensorFlow/Keras + MediaPipe         │
│  TFLite (Deployment) + Google Colab (Training)      │
├─────────────────────────────────────────────────────┤
│                 INFRASTRUCTURE                      │
│  Docker + Render/Railway (Deploy) + Cloud Storage   │
└─────────────────────────────────────────────────────┘
```

## Temel Teknolojiler (Direct Use-Case)

### 1. Frontend (Flutter)
- **Framework:** Flutter 3.x (Platform: iOS, Android)
- **State Management:** Riverpod 2.x
- **Routing:** Go Router
- **Local DB:** Hive 2.x
- **Network / API:** Dio
- **Native Bridges:** `tflite_flutter`, `camera`, `flutter_tts`, `speech_to_text`.

### 2. AI & Makine Öğrenmesi
- **Ekstraksiyon:** MediaPipe (Holistic landmark tespiti)
- **Model:** TensorFlow / Keras (LSTM + Attention mimarisi)
- **Mobil Deploy:** TFLite (On-device çevrimdışı tahminler için)
- **Veri İşleme:** OpenCV, NumPy, Pandas, Scikit-learn
- **Eğitim Ortamı:** Google Colab Pro

### 3. Backend & DB (Opsiyonel / Cloud Modulü)
- **API:** Node.js (20 LTS) + Express + TypeScript (5.x)
- **Validation:** Zod
- **Auth:** JWT tabanlı auth, bcrypt payload.
- **ORM:** Prisma 5.x
- **Database:** PostgreSQL 16

## Versiyon Ortamı Hedefleri

| Platform     | Min | Hedef |
|--------------|-----|-------|
| Android SDK  | API 24 (Android 7.0) | API 34+ |
| iOS          | 13.0 | 17.0+ |
| Dart / Fl.   | 3.3+ / 3.19+ | Latest Stable |
| Node.js / PG | 18 LTS / 14 | 20 LTS / 16 |
