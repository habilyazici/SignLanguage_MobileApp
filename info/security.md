# 🔒 HEAR ME OUT — Güvenlik & KVKK

## 1. Zero-Knowledge Kamera Prensibi
İşaret dili tanıması için kullanılan kamera stream'i asla sunucuya iletilmez, cachelenmez ve diske yazılmaz. Anlık memory üzerinde MediaPipe'a Frame olarak pushlanır, sadece nümerik Landmark x,y karşılıkları inference modeline gönderilir.

## 2. Kimlik Doğrulama / Yetkilendirme
- **Strateji:** JWT (JSON Web Token).
- **Access Token:** Kısa ömürlü (15 dk). Payload içerisinde id, email ve role tutulur.
- **Refresh Token:** Uzun ömürlü (7 gün), veritabanına session iptali yapılabilmesi için kaydedilmelidir (TODO planı: `refresh_tokens` tablosunda token invalidate imkanına olanak sağlanması lazım).
- **Şifre Saklama:** bcrypt 12 salt round.

## 3. KVKK Veri Haritası
- **Kamera Görüntüleri:** (YOK/TOPLANMIYOR)
- **Email, Ad Soyad:** (Meşru menfaat / Açık Rıza, hesap silimi durumunda anonimize edilir veya veritabanından tamamen drop atılır).
## 4. API Düzeyi Güvenlikleri
- **Helmet:** XSS ve sniffing'e karşı express middleware korumaları.
- **Zod:** Tüm POST payload string ve regex format checkleri backend düzeyinde reddedilir.

## 5. Uygulama Düzeyi Güvelik (Flutter)
- **Local Cache (Hive):** Hassas credential bilgiler Encryption key ile saklanır.
- Offline işlenen veriler cleartext'tir. 
