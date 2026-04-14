# 🗄️ HEAR ME OUT — Database Schema Referansı

## PostgreSQL 16 + Prisma ORM

## Şema Tanımı
Aşağıda veritabanının model schema'sı yer almaktadır:

```prisma
model User {
  id        String   @id @default(uuid())
  email     String   @unique
  password  String   
  name      String
  avatar    String?  
  role      String   @default("USER")
  createdAt DateTime @default(now())

  healthCard   HealthCard?
  translations Translation[]
  favorites    Favorite[]
}

model HealthCard {
  id               String   @id @default(uuid())
  userId           String   @unique
  bloodType        String?  
  allergies        String[] 
  chronicDiseases  String[] 
  medications      String[] 
  emergencyContact String?  
  emergencyPhone   String?  
  notes            String?  

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)
}

model Sign {
  id           String   @id @default(uuid())
  word         String   @unique 
  categoryId   String              
  videoUrl     String              
  thumbnailUrl String?             
  difficulty   Int      @default(1) 
  
  category     Category     @relation(fields: [categoryId], references: [id])
  translations Translation[]
  favorites    Favorite[]
}

model Translation {
  id         String    @id @default(uuid())
  userId     String
  signId     String?   
  direction  String    // SIGN_TO_TEXT veya TEXT_TO_SIGN
  inputText  String?   
  outputText String?   
  confidence Float?    
  sentence   String?   
  createdAt  DateTime  @default(now())

  user User  @relation(fields: [userId], references: [id], onDelete: Cascade)
  sign Sign? @relation(fields: [signId], references: [id])
}

model Favorite {
  id      String   @id @default(uuid())
  userId  String
  signId  String
  
  user User @relation(fields: [userId], references: [id], onDelete: Cascade)
  sign Sign @relation(fields: [signId], references: [id])
  @@unique([userId, signId]) 
}

model Category {
  id    String @id @default(uuid())
  name  String @unique // "sağlık", "günlük", vb.
  icon  String?        
  color String?        
  order Int    @default(0) 

  signs Sign[]
}
```

## Performans & Indexing
- `Sign`: categoryId ve word search indexing (B-Tree).
- `Translation`: userId, createdAt compound indexing.
