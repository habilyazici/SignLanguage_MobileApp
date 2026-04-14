# 🗄️ HEAR ME OUT — Veritabanı Dokümantasyonu

## 1. Genel Bakış

| Alan | Bilgi |
|------|-------|
| **Veritabanı** | PostgreSQL 16 |
| **ORM** | Prisma |
| **Şema Dili** | Prisma Schema Language (.prisma) |
| **Migration** | Prisma Migrate |
| **Hosting** | Docker (local) / Render (production) |

---

## 2. ER Diyagramı (Entity-Relationship)

```
┌──────────────┐     1:1     ┌─────────────────┐
│    User      │────────────▶│   HealthCard     │
│              │             │                  │
│ id           │             │ id               │
│ email        │             │ userId (FK)      │
│ password     │             │ bloodType        │
│ name         │             │ allergies        │
│ avatar       │             │ chronicDiseases  │
│ role         │             │ emergencyContact │
│ createdAt    │             │ emergencyPhone   │
│ updatedAt    │             │ notes            │
└──────┬───────┘             └─────────────────┘
       │
       │ 1:N
       ▼
┌──────────────┐       N:M        ┌──────────────┐
│ Translation  │                  │    Sign       │
│              │                  │              │
│ id           │    ┌─────────┐   │ id           │
│ userId (FK)  │    │Favorite │   │ word         │
│ signId (FK)  │    │         │   │ category     │
│ direction    │    │ userId  │   │ videoUrl     │
│ confidence   │    │ signId  │   │ description  │
│ sentence     │    │ addedAt │   │ difficulty   │
│ createdAt    │    └─────────┘   │ createdAt    │
└──────────────┘                  └──────────────┘
       │
       │ N:1
       ▼
┌──────────────┐
│  Category    │
│              │
│ id           │
│ name         │
│ icon         │
│ color        │
│ order        │
└──────────────┘
```

---

## 3. Prisma Schema

```prisma
// prisma/schema.prisma

generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// ─── KULLANICI ─────────────────────────────────────────
model User {
  id        String   @id @default(uuid())
  email     String   @unique
  password  String   // bcrypt hashed
  name      String
  avatar    String?  // URL veya base64
  role      Role     @default(USER)
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  // Relations
  healthCard   HealthCard?
  translations Translation[]
  favorites    Favorite[]

  @@map("users")
}

enum Role {
  USER
  ADMIN
}

// ─── SAĞLIK KARTI ──────────────────────────────────────
model HealthCard {
  id               String   @id @default(uuid())
  userId           String   @unique
  bloodType        String?  // A+, A-, B+, B-, AB+, AB-, O+, O-
  allergies        String[] // ["Penisilin", "Fıstık"]
  chronicDiseases  String[] // ["Diyabet", "Astım"]
  medications      String[] // ["İnsülin", "Ventolin"]
  emergencyContact String?  // Acil durum kişisi adı
  emergencyPhone   String?  // Telefon numarası
  notes            String?  // Ek notlar
  createdAt        DateTime @default(now())
  updatedAt        DateTime @updatedAt

  // Relations
  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@map("health_cards")
}

// ─── İŞARET DİLİ KELİMELERİ ───────────────────────────
model Sign {
  id          String   @id @default(uuid())
  word        String   @unique // "ağrı", "yardım", "teşekkür"
  category    String   // "sağlık", "günlük", "acil", "duygular", "sayılar"
  videoUrl    String   // CDN video URL'si
  thumbnailUrl String? // Video önizleme resmi
  description String?  // Kelimenin açıklaması
  difficulty  Int      @default(1) // 1-5 zorluk seviyesi
  createdAt   DateTime @default(now())

  // Relations
  translations Translation[]
  favorites    Favorite[]

  @@map("signs")
}

// ─── ÇEVİRİ GEÇMİŞİ ──────────────────────────────────
model Translation {
  id         String    @id @default(uuid())
  userId     String
  signId     String?   // Null olabilir (bilinmeyen kelime)
  direction  Direction // SIGN_TO_TEXT veya TEXT_TO_SIGN
  inputText  String?   // Metin→İşaret'te girilen metin
  outputText String?   // İşaret→Metin'de çıkan metin
  confidence Float?    // AI güven skoru (0.0-1.0)
  sentence   String?   // Cümle modunda tam cümle
  createdAt  DateTime  @default(now())

  // Relations
  user User  @relation(fields: [userId], references: [id], onDelete: Cascade)
  sign Sign? @relation(fields: [signId], references: [id])

  @@map("translations")
}

enum Direction {
  SIGN_TO_TEXT // İşaret → Metin
  TEXT_TO_SIGN // Metin → İşaret
}

// ─── FAVORİ KELİMELER ─────────────────────────────────
model Favorite {
  id      String   @id @default(uuid())
  userId  String
  signId  String
  addedAt DateTime @default(now())

  // Relations
  user User @relation(fields: [userId], references: [id], onDelete: Cascade)
  sign Sign @relation(fields: [signId], references: [id])

  @@unique([userId, signId]) // Aynı kullanıcı aynı kelimeyi 2 kez favoriye ekleyemez
  @@map("favorites")
}
```

---

## 4. Seed Verisi (Başlangıç)

226 kelime uygulamanın ilk kurulumunda veritabanına yüklenir:

```typescript
// prisma/seed.ts
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const signs = [
  // Sağlık kategorisi
  { word: "ağrı",       category: "sağlık",   videoUrl: "https://cdn.../agri.mp4",       difficulty: 1 },
  { word: "yardım",     category: "acil",     videoUrl: "https://cdn.../yardim.mp4",     difficulty: 1 },
  { word: "hastane",    category: "sağlık",   videoUrl: "https://cdn.../hastane.mp4",    difficulty: 2 },
  { word: "ilaç",       category: "sağlık",   videoUrl: "https://cdn.../ilac.mp4",       difficulty: 1 },
  { word: "alerji",     category: "sağlık",   videoUrl: "https://cdn.../alerji.mp4",     difficulty: 2 },

  // Günlük kategorisi
  { word: "merhaba",    category: "günlük",   videoUrl: "https://cdn.../merhaba.mp4",    difficulty: 1 },
  { word: "teşekkür",   category: "günlük",   videoUrl: "https://cdn.../tesekkur.mp4",   difficulty: 1 },
  { word: "evet",       category: "günlük",   videoUrl: "https://cdn.../evet.mp4",       difficulty: 1 },
  { word: "hayır",      category: "günlük",   videoUrl: "https://cdn.../hayir.mp4",      difficulty: 1 },

  // ... toplam 226 kelime
];

async function main() {
  for (const sign of signs) {
    await prisma.sign.upsert({
      where: { word: sign.word },
      update: sign,
      create: sign,
    });
  }
  console.log(`${signs.length} kelime eklendi`);
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
```

---

## 5. Kritik Sorgular

| Sorgu | Amaç |
|-------|------|
| `Sign` + `Translation` JOIN, GROUP BY count | En sık çevrilen 10 kelime |
| `Translation WHERE userId`, COUNT + AVG(confidence) | Kullanıcı istatistikleri |
| Window fonksiyonu ile `DATE(createdAt)` farkı | Streak hesaplama |

---

## 6. İndeksler ve Performans

| Model | İndeks | Amaç |
|-------|---------|------|
| `Sign` | `category`, `word` | Kategori filtresi + kelime arama |
| `Translation` | `(userId, createdAt)`, `signId` | Geçmiş sorgusu + istatistik |
| `Favorite` | `userId` | Kullanıcının favorileri |
