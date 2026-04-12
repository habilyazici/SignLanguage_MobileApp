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
Access Token (Kısa ömürlü - 7 gün)
├── userId
├── email
├── role
└── exp (expiration)

Refresh Token (Uzun ömürlü - 30 gün)
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

### Şifre Güvenliği
```typescript
import bcrypt from 'bcryptjs';

// Kayıt sırasında
const salt = await bcrypt.genSalt(12); // 12 round
const hashedPassword = await bcrypt.hash(plainPassword, salt);
// DB'ye hashedPassword kaydedilir

// Giriş sırasında
const isMatch = await bcrypt.compare(inputPassword, hashedPassword);
```

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

### Rate Limiting
```typescript
import rateLimit from 'express-rate-limit';

// Genel API limiti
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 dakika
  max: 100,                  // 15 dk'da max 100 istek
  message: 'Çok fazla istek gönderildi, lütfen bekleyin'
});

// Auth limiti (brute force koruması)
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,                    // 15 dk'da max 5 giriş denemesi
  message: 'Çok fazla giriş denemesi'
});
```

### HTTP Güvenlik Header'ları (Helmet)
```typescript
import helmet from 'helmet';
app.use(helmet()); // XSS, clickjacking, sniffing koruması
```

### Input Validasyonu (Zod)
```typescript
import { z } from 'zod';

const registerSchema = z.object({
  email: z.string().email('Geçerli bir e-posta girin'),
  password: z.string().min(8, 'En az 8 karakter').regex(
    /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/,
    'En az 1 büyük harf, 1 küçük harf, 1 rakam'
  ),
  name: z.string().min(2).max(50),
});
```

---

## 6. Yerel Depolama Güvenliği (Flutter)

### Hive Şifreli Box
```dart
// Hassas veriler şifreli Hive box'ta saklanır
final encryptionKey = await SecureStorage.read(key: 'hive_key')
  ?? Hive.generateSecureKey();

final secureBox = await Hive.openBox(
  'secure_data',
  encryptionCipher: HiveAesCipher(encryptionKey),
);

// Token saklama
await secureBox.put('access_token', token);
```

### SharedPreferences (Hassas olmayan veriler)
```dart
// Sadece hassas OLMAYAN ayarlar
final prefs = await SharedPreferences.getInstance();
await prefs.setBool('onboarding_complete', true);
await prefs.setString('theme_mode', 'dark');
await prefs.setBool('landmark_overlay', true);
```

---

## 7. Güvenlik Kontrol Listesi

| Alan | Durum | Detay |
|------|-------|-------|
| Kamera verisi sunucuya gitmiyor | ✅ | Tamamen on-device |
| Şifreler bcrypt ile hash'lenmiş | ✅ | 12 salt round |
| JWT token süresi sınırlı | ✅ | Access: 7 gün, Refresh: 30 gün |
| HTTPS zorunlu (production) | ⏳ | Deploy aşamasında |
| Rate limiting aktif | ⏳ | Backend kurulumunda |
| Input validasyonu (Zod) | ⏳ | Backend kurulumunda |
| Sağlık verisi AES-256 şifrelemesi | ⏳ | İleri aşamada |
| KVKK aydınlatma metni | ⏳ | Hukuk danışmanlığı gerekebilir |
| Veri dışa aktarma (JSON) | ⏳ | Profil ekranında |
| Hesap silme (cascade delete) | ⏳ | Backend + Flutter |
