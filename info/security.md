# 🔒 HEAR ME OUT — Güvenlik ve KVKK Dokümantasyonu

## 1. Genel Bakış

| Alan | Politika |
|------|----------|
| **Veri İşleme** | On-device (kamera verisi hiçbir sunucuya gitmez) |
| **Kimlik Doğrulama** | JWT (Access + Refresh Token) |
| **Şifreleme** | bcrypt (password), HTTPS (transit), AES-256 (planlanan) |
| **KVKK Uyumluluğu** | Açık rıza, veri minimizasyonu, silme hakkı |
| **Yerel Depolama** | Hive (şifreli box desteği) |

---

## 2. On-Device Gizlilik (En Kritik)

### Kamera Verisi Akışı
```
Kamera → RAM (geçici) → MediaPipe → Koordinatlar → Model → Tahmin
                ↓
        Piksel verisi ASLA:
        ❌ Diske yazılmaz
        ❌ Sunucuya gönderilmez
        ❌ Cache'lenmez
        ❌ Log'lanmaz
```

> **Bu, projenin en güçlü gizlilik özelliğidir.** Kullanıcının yüzü, elleri ve vücudu hiçbir zaman cihazdan çıkmaz. Sadece 106 sayısal koordinat işlenir — bu koordinatlardan kişi tanınamaz.

---

## 3. Kimlik Doğrulama (JWT)

### Token Yapısı
```
Access Token (Kısa ömürlü - 15 dakika)
├── userId
├── email
├── role
└── exp (expiration)

Refresh Token (Uzun ömürlü - 7 gün)
├── userId
└── exp
```

### Token Akışı
```
1. Kullanıcı giriş yapar (email + password)
        ↓
2. Backend şifreyi bcrypt ile kontrol eder
        ↓
3. Access Token + Refresh Token üretilir
        ↓
4. Flutter: Access Token → Dio interceptor'dan her isteğe eklenir
        ↓
5. Token süresi dolunca? → Refresh Token ile yeni Access Token al
        ↓
6. Refresh Token da dolduysa? → Kullanıcı yeniden giriş yapar
```

**Şifre güvenliği:** bcrypt (12 salt round) — plaintext şifre hiçbir zaman saklanmaz.

> [!IMPORTANT]
> **Refresh Token İptal Mekanizması (TODO):** Refresh token'lar şu an stateless — logout sonrası
> geçerli kalmaya devam eder. KVKK "hesap silme" hakkıyla çelişiyor.
> **Planı:** `refresh_tokens` tablosu oluştur, logout'ta token'ı tablodan sil, her kullanımda kontrol et.
> ```prisma
> model RefreshToken {
>   id        String   @id @default(uuid())
>   token     String   @unique
>   userId    String
>   expiresAt DateTime
>   user      User     @relation(...)
>   @@map("refresh_tokens")
> }
> ```

---

## 4. KVKK (Kişisel Verilerin Korunması Kanunu)

### 4.1. Toplanan Veriler ve Hukuki Dayanak

| Veri Türü | Veri | Hukuki Dayanak | Saklama Süresi |
|-----------|------|----------------|---------------|
| **Kimlik** | Ad, e-posta | Açık rıza | Hesap silinene kadar |
| **Sağlık** | Kan grubu, alerji, hastalıklar | Açık rıza (hassas veri) | Hesap silinene kadar |
| **Kullanım** | Çeviri geçmişi, istatistikler | Meşru menfaat | 1 yıl |
| **Teknik** | Cihaz tipi, OS versiyonu | Meşru menfaat | 6 ay |
| **Kamera** | ❌ TOPLANMAZ | — | — |

### 4.2. Kullanıcı Hakları (KVKK Madde 11)

| Hak | Uygulama İçi Karşılık |
|-----|----------------------|
| **Bilgilendirilme** | İlk açılışta gizlilik politikası gösterimi |
| **Erişim** | Profil → "Verilerimi Gör" butonu |
| **Düzeltme** | Profil → Bilgileri düzenleme |
| **Silme** | Ayarlar → "Hesabımı Sil" (cascade delete) |
| **Veri taşıma** | Ayarlar → "Verilerimi Dışa Aktar" (JSON export) |
| **İtiraz** | Geri bildirim formu |

### 4.3. Sağlık Verisi (Hassas Veri — Özel Kategori)

Sağlık kartı bilgileri **hassas kişisel veri** kategorisindedir. Ek önlemler:

1. **Açık rıza**: Sağlık kartı oluşturulurken ayrı bir onay checkbox'ı
2. **Şifreleme**: Backend'de AES-256 ile şifrelenmiş saklanır (planlanan)
3. **Minimizasyon**: Sadece acil durumda kullanılacak minimum veri toplanır
4. **Yerel tercih**: Kullanıcı isterse sağlık kartını sadece telefonunda tutabilir (Hive, sunucuya göndermeden)

---

## 5. API Güvenliği

| Önlem | Detay |
|-------|-------|
| **Rate Limiting** | Genel: 100 istek/15dk · Auth: 5 giriş/15dk (brute-force koruması) |
| **Helmet** | HTTP güvenlik headerları — XSS, clickjacking, sniffing koruması |
| **Input Validasyonu** | Zod şeması — email, şifre (min 8 + büyük/küçük/rakam), isim (2-50 karakter) |

---

## 6. Yerel Depolama Güvenliği (Flutter)

| Depolama | Kullanım |
|----------|----------|
| **Hive şifreli box** | Token, hassas kullanıcı verisi — AES cipher ile şifreli |
| **SharedPreferences** | Hassas olmayan ayarlar (tema, onboarding durumu) |

---

## 7. Güvenlik Kontrol Listesi

| Alan | Durum | Detay |
|------|-------|-------|
| Kamera verisi sunucuya gitmiyor | ✅ | Tamamen on-device |
| Şifreler bcrypt ile hash'lenmiş | ✅ | 12 salt round |
| JWT token süresi sınırlı | ✅ | Access: 15 dk, Refresh: 7 gün |
| HTTPS zorunlu (production) | ⏳ | Deploy aşamasında |
| Rate limiting aktif | ⏳ | Backend kurulumunda |
| Input validasyonu (Zod) | ⏳ | Backend kurulumunda |
| Sağlık verisi AES-256 şifrelemesi | ⏳ | İleri aşamada |
| KVKK aydınlatma metni | ⏳ | Hukuk danışmanlığı gerekebilir |
| Veri dışa aktarma (JSON) | ⏳ | Profil ekranında |
| Hesap silme (cascade delete) | ⏳ | Backend + Flutter |
