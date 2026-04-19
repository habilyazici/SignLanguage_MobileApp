<!--
  UYGULAMA DURUMU (2026-04-17)
  ⬜ Backend henüz implement edilmedi — sadece klasör iskelet + spec mevcut
  ⬜ Tüm endpoint'ler (auth, profil, signs, favorites) stub/boş
  ⬜ PostgreSQL/Prisma kurulmadı
  ⬜ Flutter tarafında Dio instance var ama herhangi bir API çağrısı yapılmıyor
  Not: Mobil uygulama şu an tamamen offline-first çalışıyor (model + csv local)
-->

# 💻 HEAR ME OUT — Backend Servisleri

## 1. Stack Özeti
- **Tech:** Node.js, Express.js, TypeScript.
- **Güvenlik & Validasyon:** JWT, bcrypt, Zod, Helmet.
- **Database:** PostgreSQL (Prisma ORM ile).
- **Görev:** İsteğe bağlı cloud data (Kullanıcı hesapları, translation history, CDN referans url'leri).

## 2. API Endpoints Map

### Auth (`/api/auth`)
- `POST /register` `({email, password, name})` -> `{user, token}`
- `POST /login` `({email, password})` -> `{user, token}`
- `POST /refresh` `({refreshToken})` -> `{token}`
- `POST /logout` -> Auth required
- `GET /me` -> Auth required

### Profil (`/api/profile`) - Auth Required
- `GET /` -> Profil + Stats
- `PUT /` `({name, avatar})`

### İşaret Kelime Verileri (`/api/signs`) - Guest Access
- `GET /` -> Tüm sözlük indexi 
- `GET /:word` -> Tekil kelime video manifestosu
- `GET /category/:cat` -> Kategoriye göre liste
- `GET /search?q=` -> Query parametreli

### Geçmiş & Favoriler (`/api/translations`, `/api/favorites`)
- `POST /translations` `({word, direction, confidence})`
- `GET /translations/history`
- `GET /favorites`
- `POST /favorites/:signId`
- `DELETE /favorites/:signId`

## 3. Klasör Şeması
```text
backend/src/
 ├─ api/          (Controllers, Routes, Middlewares)
 ├─ services/     (Business Logic: auth, sign, profile, translation)
 ├─ repositories/ (Prisma Repository pattern implementasyonları)
 ├─ prisma/       (schema.prisma ve seed dosyaları)
 └─ config/       (.env mapperleri, cors, database instances)
```

## 4. Geliştirme (Development) Notları
- **Yerel API Testi (Mobil Cihazlar):** Backend yerel (localhost) ortamda çalışırken, Flutter uygulamasının (gerçek cihaz veya emülatör) ağ kısıtlamalarına takılmadan backend'e erişebilmesi için **Ngrok** kullanılacaktır. Ngrok tüneli üzerinden alınacak URL, mobil uygulamanın API Base URL'si olarak ayarlanmalıdır.
