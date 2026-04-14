# 💻 HEAR ME OUT — Backend Dokümantasyonu

## 1. Genel Bakış

| Alan | Bilgi |
|------|-------|
| **Runtime** | Node.js |
| **Framework** | Express.js |
| **Dil** | TypeScript |
| **ORM** | Prisma |
| **Veritabanı** | PostgreSQL |
| **Auth** | JWT (JSON Web Token) |
| **Deploy** | Docker + Render/Railway |
| **Rol** | Hafif/opsiyonel — çekirdek AI on-device çalışır |

> **Önemli Not**: Backend, uygulamanın çalışması için **zorunlu değildir**. Çekirdek AI (İşaret→Metin) tamamen cihaz üzerinde çalışır. Backend, kullanıcı hesapları, geçmiş kayıtları ve sözlük videoları gibi "güzel olsa ama olmasa da olur" verileri yönetir.

---

## 2. Mimari: Katmanlı Yapı

```
HTTP İsteği (Flutter → Dio)
        ↓
┌─────────────────────────────────────┐
│        ROUTES (Yönlendirme)         │
│   auth.routes.ts, sign.routes.ts    │
└────────────────┬────────────────────┘
                 ↓
┌─────────────────────────────────────┐
│      MIDDLEWARES (Ara Katman)        │
│   auth.middleware.ts (JWT check)    │
│   error.middleware.ts (hata yakala) │
│   validation.middleware.ts          │
└────────────────┬────────────────────┘
                 ↓
┌─────────────────────────────────────┐
│      CONTROLLERS (İstek İşleme)     │
│   İsteği parse et, response döndür │
│   auth.controller.ts               │
│   sign.controller.ts               │
│   profile.controller.ts            │
└────────────────┬────────────────────┘
                 ↓
┌─────────────────────────────────────┐
│       SERVICES (İş Mantığı)         │
│   Kuralları uygula, karar ver      │
│   auth.service.ts                  │
│   sign.service.ts                  │
│   profile.service.ts               │
└────────────────┬────────────────────┘
                 ↓
┌─────────────────────────────────────┐
│     REPOSITORIES (Veri Erişim)      │
│   Sadece DB'ye git, mantık yapma   │
│   user.repository.ts               │
│   sign.repository.ts               │
│   health.repository.ts             │
│   (Prisma Client kullanır)         │
└────────────────┬────────────────────┘
                 ↓
┌─────────────────────────────────────┐
│     PRISMA + PostgreSQL             │
│   schema.prisma → tablolar         │
└─────────────────────────────────────┘
```

---

## 3. Klasör Yapısı

```
backend/
├── src/
│   ├── api/                           # Dışarıya açılan kapı
│   │   ├── controllers/
│   │   │   ├── auth.controller.ts     # Kayıt, giriş, token yenile
│   │   │   ├── sign.controller.ts     # Sözlük sorguları, video URL'leri
│   │   │   ├── profile.controller.ts  # Profil CRUD, sağlık kartı
│   │   │   └── translation.controller.ts  # Çeviri geçmişi kaydet/getir
│   │   │
│   │   ├── routes/
│   │   │   ├── index.ts               # Tüm route'ları birleştir
│   │   │   ├── auth.routes.ts         # POST /auth/register, /auth/login
│   │   │   ├── sign.routes.ts         # GET /signs, /signs/:word, /signs/category/:cat
│   │   │   ├── profile.routes.ts      # GET/PUT /profile, /profile/health-card
│   │   │   └── translation.routes.ts  # POST /translations, GET /translations/history
│   │   │
│   │   └── middlewares/
│   │       ├── auth.middleware.ts      # JWT token doğrulama
│   │       ├── error.middleware.ts     # Global hata yakalayıcı
│   │       ├── validation.middleware.ts # Request body doğrulama (Zod)
│   │       └── rate-limit.middleware.ts # Rate limiting
│   │
│   ├── services/                      # İş mantığı katmanı
│   │   ├── auth.service.ts            # Şifre hash, JWT üret, doğrula
│   │   ├── sign.service.ts            # Kelime ara, video URL döndür, cache
│   │   ├── profile.service.ts         # Profil güncelle, sağlık kartı yönet
│   │   └── translation.service.ts     # Çeviri kaydet, geçmiş getir
│   │
│   ├── repositories/                  # Veri erişim katmanı (Prisma)
│   │   ├── user.repository.ts         # User CRUD
│   │   ├── sign.repository.ts         # Sign kelime sorguları
│   │   ├── health.repository.ts       # HealthCard CRUD
│   │   └── translation.repository.ts  # Translation geçmiş sorguları
│   │
│   ├── prisma/
│   │   ├── schema.prisma              # Veritabanı şeması
│   │   ├── seed.ts                    # Başlangıç verisi (226 kelime)
│   │   └── migrations/               # Prisma migration dosyaları
│   │
│   ├── config/
│   │   ├── env.ts                     # Environment variables wrapper
│   │   ├── database.ts                # Prisma client singleton
│   │   └── cors.ts                    # CORS ayarları
│   │
│   ├── types/
│   │   ├── express.d.ts               # Express tip genişletmeleri
│   │   └── index.ts                   # Paylaşılan tipler
│   │
│   └── app.ts                         # Express konfigürasyonu ve başlatma
│
├── .env                               # Ortam değişkenleri
├── .env.example                       # Örnek env dosyası
├── tsconfig.json                      # TypeScript konfigürasyonu
├── package.json                       # Bağımlılıklar
├── Dockerfile                         # Docker image tanımı
├── docker-compose.yml                 # PostgreSQL + App
└── README.md                          # Backend kurulum kılavuzu
```

---

## 4. API Endpoint'leri

### 4.1. Auth (Kimlik Doğrulama)

| Method | Endpoint | Body | Response | Auth |
|--------|----------|------|----------|------|
| POST | `/api/auth/register` | `{email, password, name}` | `{user, token}` | ❌ |
| POST | `/api/auth/login` | `{email, password}` | `{user, token}` | ❌ |
| POST | `/api/auth/refresh` | `{refreshToken}` | `{token}` | ❌ |
| POST | `/api/auth/logout` | — | `{message}` | ✅ |
| GET | `/api/auth/me` | — | `{user}` | ✅ |

### 4.2. Signs (İşaret Dili Sözlüğü)

| Method | Endpoint | Response | Auth |
|--------|----------|----------|------|
| GET | `/api/signs` | Tüm kelimeler (226) `[{word, category, videoUrl}]` | ❌ |
| GET | `/api/signs/:word` | Tek kelime detayı `{word, videoUrl, description}` | ❌ |
| GET | `/api/signs/category/:cat` | Kategoriye göre filtre | ❌ |
| GET | `/api/signs/search?q=ağrı` | Kelime arama | ❌ |

> **Not**: Sözlük endpoint'leri auth gerektirmez — Guest-First prensibi.

### 4.3. Profile (Kullanıcı Profili)

| Method | Endpoint | Body | Response | Auth |
|--------|----------|------|----------|------|
| GET | `/api/profile` | — | `{user, healthCard, stats}` | ✅ |
| PUT | `/api/profile` | `{name, avatar}` | `{user}` | ✅ |
| GET | `/api/profile/health-card` | — | `{healthCard}` | ✅ |
| PUT | `/api/profile/health-card` | `{bloodType, allergies, ...}` | `{healthCard}` | ✅ |
| DELETE | `/api/profile` | — | `{message}` | ✅ |

### 4.4. Translations (Çeviri Geçmişi)

| Method | Endpoint | Body | Response | Auth |
|--------|----------|------|----------|------|
| POST | `/api/translations` | `{word, direction, confidence}` | `{translation}` | ✅ |
| GET | `/api/translations/history` | — | `[{translations}]` | ✅ |
| GET | `/api/translations/stats` | — | `{totalCount, streak, ...}` | ✅ |

### 4.5. Favorites (Favori Kelimeler)

| Method | Endpoint | Body | Response | Auth |
|--------|----------|------|----------|------|
| GET | `/api/favorites` | — | `[{signs}]` | ✅ |
| POST | `/api/favorites/:signId` | — | `{message}` | ✅ |
| DELETE | `/api/favorites/:signId` | — | `{message}` | ✅ |

---

## 5. Paket Listesi (package.json)

### Core
| Paket | Kullanım |
|-------|----------|
| `express` | Web framework |
| `typescript` | Tip güvenliği |
| `@prisma/client` | Veritabanı ORM |
| `prisma` | Schema yönetimi ve migration |

### Auth & Güvenlik
| Paket | Kullanım |
|-------|----------|
| `bcryptjs` | Şifre hashleme |
| `jsonwebtoken` | JWT token üretme/doğrulama |
| `helmet` | HTTP güvenlik headerları |
| `cors` | Cross-origin ayarları |
| `express-rate-limit` | API rate limiting |

### Validasyon & Utility
| Paket | Kullanım |
|-------|----------|
| `zod` | Request body validasyonu (tip-güvenli) |
| `dotenv` | Environment variables |
| `winston` | Loglama |
| `morgan` | HTTP request loglama |

### Dev
| Paket | Kullanım |
|-------|----------|
| `ts-node-dev` | Hot reload (geliştirme) |
| `jest` + `ts-jest` | Unit test |
| `supertest` | API integration test |

---

## 6. Environment Variables (.env)

```env
# Server
PORT=3000
NODE_ENV=development

# Database
DATABASE_URL="postgresql://user:password@localhost:5432/hearmeout?schema=public"

# JWT
JWT_SECRET="your-super-secret-jwt-key-change-in-production"
JWT_EXPIRES_IN="7d"
JWT_REFRESH_SECRET="your-refresh-secret-key"
JWT_REFRESH_EXPIRES_IN="30d"

# CORS
CORS_ORIGIN="*"

# CDN (İşaret dili videoları)
CDN_BASE_URL="https://cdn.hearmeout.app/videos"
```

---

## 7. Docker Kurulumu

| Servis | Image | Port |
|--------|-------|------|
| **PostgreSQL** | `postgres:16-alpine` | 5432 |
| **API** | Multistage Node build | 3000 |

```bash
# Geliştirme ortamını başlat
docker compose up -d

# Migration çalıştır
npx prisma migrate deploy
```
