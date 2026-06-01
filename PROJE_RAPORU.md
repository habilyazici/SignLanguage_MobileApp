# Hear Me Out – Proje Raporu

---

## 1. Proje Tanımı

**Hear Me Out**, Türk İşaret Dili'ni (TİD) gerçek zamanlı olarak tanıma ve çevirme amacıyla geliştirilen bir mobil uygulamadır. Uygulamanın temel amacı, işitme engelli bireyler ile işaret dili bilmeyen kişiler arasındaki iletişimi kolaylaştırmak; aynı zamanda Türk İşaret Dili öğrenmek isteyen kullanıcılar, aile bireyleri, eğitimciler ve rehberler için destekleyici bir dijital araç sunmaktır.

Uygulama;

- Gerçek zamanlı işaret tanıma (226 kelime, çevrimdışı)
- Metinden işaret diline çeviri
- Türk İşaret Dili sözlüğü
- Kullanıcı geçmişi ve yer imleri
- Cihaz üzerinde çalışan yapay zekâ modeli (internet bağlantısı gerektirmez)
- Misafir/kayıtsız kullanım modu

gibi özellikleri bir araya getirmektedir.

Özellikle acil durum senaryolarında hızlı iletişim kurulabilmesi amacıyla uygulama, kayıt zorunluluğu olmadan kullanılabilen misafir erişimi desteği sunmaktadır.

---

## 2. Çözüm Sunulan Problem

Hear Me Out üç temel probleme çözüm sunmayı hedeflemektedir:

**1. İletişim Bariyeri**
İşaret dili bilen ve bilmeyen bireyler arasındaki iletişim zorluğunu azaltmak.

**2. Erişilebilirlik Problemleri**
Mevcut işaret dili uygulamalarında karşılaşılan karmaşık kullanım deneyimi ve erişilebilirlik sorunlarını iyileştirmek.

**3. Gerçek Zamanlı ve Çevrimdışı Kullanım İhtiyacı**
Mobil cihazlarda internet bağlantısına bağımlı olmadan çalışabilen, gerçek zamanlı işaret tanıma sistemine olan ihtiyacı karşılamak.

---

## 3. Hedef Kitle

Hear Me Out geniş bir kullanıcı kitlesine hitap edecek şekilde tasarlanmıştır.

Hedef kullanıcı grupları şunlardır:

- İşitme engelli bireyler
- İşaret dili öğrenen öğrenciler
- İşaret dili bilen öğretmenler ve çevirmenler
- Aile bireyleri ve bakım verenler
- İşitme engelli yakınlarıyla daha kolay iletişim kurmak isteyen kullanıcılar
- Acil durumlarda hızlı çeviri ihtiyacı duyan kişiler

Uygulama hem profesyonel kullanım hem de günlük yaşam senaryoları için uygun şekilde tasarlanmıştır.

---

## 4. Projenin Kullanım Alanları

Hear Me Out;

- Bireysel kullanım
- Eğitim ortamları
- Aile ve destek sistemleri
- Sağlık ve rehberlik hizmetleri
- Toplu taşıma ve kamu alanları

gibi farklı kullanım senaryoları düşünülerek geliştirilmiştir.

Misafir modu sayesinde kullanıcılar kayıt oluşturmadan da uygulamanın temel özelliklerine (kamera ile gerçek zamanlı işaret tanıma) erişebilmektedir.

---

## 5. Kullanılan Teknolojiler ve Tercih Sebepleri

### 5.1 Frontend Teknolojileri

**Flutter (SDK ^3.10.8)**
Tek kod tabanıyla hem iOS hem Android platform desteği sunması nedeniyle tercih edilmiştir.

**flutter_riverpod (^3.3.1)**
Bağımsız, ölçeklenebilir ve test edilebilir state yönetimi sağlamaktadır. Her modül kendi `NotifierProvider`'ına sahiptir. Platform nesneleri (örn. `CameraController`) `ValueNotifier` ile tutularak her kare için gereksiz rebuild engellenir.

**go_router (^17.2.1)**
Shell route yapısıyla 5 sekmeli alt navigasyon ve misafir/kayıtlı kullanıcı akışlarının net ayrışımını sağlar.

**camera (^0.12.0+1)**
Canlı görüntü akışı ve mobil kamera erişimi için kullanılmıştır.

**tflite_flutter (^0.12.1)**
TFLite modelinin `IsolateInterpreter` ile ana thread'i bloklamadan cihaz üzerinde çevrimdışı çalıştırılmasına olanak tanır.

**hand_detection (^2.0.8)**
MediaPipe Tasks API ile el landmark tespiti için kullanılmıştır. Python eğitim kodunda kullanılan model ile aynı `hand_landmark_full.tflite` dosyasını kullanarak eğitim-çıkarım tutarlılığı sağlanmıştır.

**google_mlkit_pose_detection (^0.14.1)**
Vücut iskelet (pose) landmark tespiti için kullanılmıştır; el tespiti ile `Future.wait` aracılığıyla paralel çalışır.

**opencv_dart (^2.2.1+4)**
hand_detection paketinin görüntü formatı gereksinimleri için kamera karelerini dönüştürür (Android: NV21, iOS: BGR).

**video_player (^2.9.3)**
Metinden işarete çeviri ve sözlük ekranlarında işaret videosu oynatma için kullanılmıştır.

**flutter_tts (^4.2.0)**
Tanınan işaret kelimesini Türkçe olarak seslendiren Text-to-Speech desteği sağlar.

**speech_to_text (^7.0.0)**
Çeviri ekranında sesle metin girişi için kullanılmıştır.

**flutter_secure_storage (^9.2.4)**
JWT token'ının şifreli olarak cihaz üzerinde saklanmasını sağlar.

### 5.2 Backend Teknolojileri

**Node.js + Express (^5.2.1)**
Hızlı ve ölçeklenebilir REST API geliştirme amacıyla tercih edilmiştir.

**TypeScript (6.0.2)**
Tip güvenliği ve geliştirici deneyimi için kullanılmıştır.

**Prisma (^7.7.0)**
Tip güvenli ve yapılandırılmış veritabanı erişimi sağlar; şema bazlı migration ve seed desteği sunar.

**PostgreSQL**
İlişkisel veri yönetimi için güçlü ve güvenilir bir veritabanı altyapısı sunar.

**jsonwebtoken (^9.0.3)**
7 günlük geçerlilik süresiyle güvenli JWT tabanlı kimlik doğrulama sağlar.

**bcrypt (^6.0.0)**
Şifreleri ve OTP kodlarını 10 tur hash'leyerek güvenli saklar.

**Nodemailer (^8.0.6)**
Gmail SMTP üzerinden 6 haneli OTP ile e-posta doğrulama ve şifre sıfırlama işlemleri için kullanılmıştır.

**Zod (^4.3.6)**
Tüm API isteklerinde veri doğrulama katmanı sağlar.

### 5.3 ML / Veri Bilimi Teknolojileri

**Python (Google Colab)**
Veri hazırlama ve model eğitimi süreçlerinde kullanılmıştır.

**MediaPipe Tasks API**
El (HandLandmarker) ve vücut (PoseLandmarker) landmark çıkarımının hem Python eğitim kodunda hem Flutter çıkarım kodunda aynı modelle yapılmasını sağlayarak eğitim-çıkarım uyumunu garantiler.

**BiLSTM + Self-Attention**
El ve vücut hareketlerini zaman serisi olarak iki yönlü analiz ederek ve dikkat mekanizmasıyla kritik karelere ağırlık vererek yüksek doğruluk sağlamaktadır.

**TensorFlow Lite (INT8 Kuantizasyon)**
637 KB boyutundaki model, internet bağlantısı gerektirmeksizin mobil cihazlarda performanslı çalışmaktadır.

**AUTSL Veri Seti**
Ankara Üniversitesi Türk İşaret Dili veri seti; ~28.000 etiketli video, 226 kelime sınıfı.

---

## 6. Teknoloji Seçimlerinin Gerekçesi

Seçilen teknolojiler aşağıdaki avantajlar nedeniyle tercih edilmiştir:

- **Flutter** ile hızlı prototipleme ve çapraz platform desteği (iOS + Android tek kod tabanı)
- **Riverpod** ile güvenli, reaktif ve test edilebilir state yönetimi; `ValueNotifier` kullanımıyla her kare için gereksiz rebuild engellenmesi
- **GoRouter** ile shell route yapısı sayesinde misafir ve kayıtlı kullanıcı akışlarının net ayrışımı
- **Node.js + Express + TypeScript** ile tip güvenli ve sürdürülebilir backend geliştirme
- **Prisma + PostgreSQL** ile şema bazlı, tip güvenli ilişkisel veri yönetimi
- **TFLite (INT8)** ile internet bağlantısı gerektirmeyen, 637 KB boyutunda çevrimdışı yapay zekâ modeli
- **Aynı MediaPipe dedektörü** hem Python eğitim kodunda hem Flutter'da kullanılarak eğitim-çıkarım tutarsızlığından kaynaklanan hataların önüne geçilmesi

---

## 7. Proje Geliştirme Süreci

### 7.1 Araştırma ve Planlama

Proje başlangıcında;

- Gerçek zamanlı ve çevrimdışı işaret tanıma
- Metinden işarete video çevirisi
- 226 kelimelik Türkçe işaret sözlüğü
- Kullanıcı kayıt ve oturum sistemi
- Misafir erişimi

gibi temel gereksinimler belirlenmiştir.

Acil durum, öğrenme deneyimi ve profil yönetimi gibi kullanıcı senaryoları analiz edilmiş; görevler **Frontend**, **Backend**, **ML** ve **UI/UX** başlıkları altında organize edilmiştir.

### 7.2 Veritabanı Tasarımı

Veritabanı modeli Prisma kullanılarak tasarlanmıştır.

**User** tablosu; kullanıcı kimlik, e-posta (benzersiz), isim, bcrypt ile hash'lenmiş şifre ve opsiyonel avatar URL'sini saklar.

**Word** tablosu; 226 kelimelik işaret sözlüğüdür. AUTSL orijinal kimliği, Türkçe kelime, harf filtresi alanı, CDN video URL'si, alternatif video dizisi ve İngilizce anlam alanlarını içerir.

**History** tablosu; kullanıcı geçmişini `HistoryType` enum'uyla üç kategoride tutar: `RECOGNITION` (kamera tanıma), `DICTIONARY` (sözlük görüntüleme), `TRANSLATION` (metin çeviri). Sayfalı sorgular için `[userId, createdAt]` bileşik indeksi mevcuttur.

**Bookmark** tablosu; kullanıcı yer imlerini saklar. `[userId, wordId]` çifti benzersiz kısıtlamasıyla aynı kelime iki kez eklenemez.

**PasswordResetToken** tablosu; 6 haneli OTP'nin bcrypt hash'ini, 15 dakikalık son geçerlilik tarihini ve kullanım durumunu saklar. Süresi dolmuş token'lar saatlik zamanlanmış görevle otomatik temizlenir.

Tüm history ve bookmark kayıtları, kullanıcı hesabı silindiğinde cascade ile otomatik temizlenir.

### 7.3 Backend Geliştirme

Express tabanlı REST API ile şu işlemler desteklenmiştir:

**Kimlik Doğrulama (`/api/auth`):**
Kayıt, giriş, profil güncelleme, profil fotoğrafı yükleme (multer ile max 5 MB), e-posta ile OTP gönderme, 6 haneli kodla şifre sıfırlama ve hesap silme (tüm verilerle birlikte cascade).

**Sözlük (`/api/words`):**
Harf ve metin filtreli sayfalı listeleme, kelime detayı ve tüm 226 kelimeyi tek istekte dönen manifest endpoint (5 dakika önbellek).

**Geçmiş (`/api/history`):**
Tür bazlı filtreleme (RECOGNITION / DICTIONARY / TRANSLATION), sayfalı listeleme, tekil ve toplu silme. Kimlik doğrulama zorunludur.

**Yer İmleri (`/api/bookmarks`):**
Ekleme (upsert), listeleme, silme. Kimlik doğrulama zorunludur.

Güvenlik katmanları:

- JWT doğrulama (7 günlük token, HS256)
- Helmet.js HTTP güvenlik başlıkları
- CORS (production: beyaz liste, development: açık)
- Rate limiting: Genel 200 istek/dk, auth endpoint 20 istek/15 dk
- Bcrypt şifre hash'leme (10 tur)
- Zod ile tüm istek gövdelerinde veri doğrulama

### 7.4 Frontend Geliştirme

Uygulama Clean Architecture prensiplerine göre modüler yapıda geliştirilmiştir. Her modül `domain` (entity ve repository arayüzleri), `data` (API çağrıları ve repository implementasyonları) ve `presentation` (Riverpod provider'ları, ekranlar, widget'lar) olmak üzere üç katmana ayrılmıştır.

**Uygulanan modüller:**

| Modül | Açıklama |
|-------|---------|
| **Auth** | Welcome, Login, Register, Forgot Password ekranları |
| **Recognition** | Gerçek zamanlı kamera + TFLite çıkarım ekranı |
| **Text-to-Sign** | Metin / ses girişi ile sıralı video oynatma |
| **Dictionary** | 226 kelimelik sözlük, harf filtresi, arama, video detay |
| **History** | Tür bazlı geçmiş listesi, tekil ve toplu silme |
| **Bookmarks** | Kayıtlı yer imleri listesi |
| **Home** | Günün öne çıkan kelimesi ve TTS okuma |
| **Profile** | Kullanıcı bilgileri, avatar, profil düzenleme |
| **Settings** | Tema, yazı boyutu, tanıma parametreleri, erişilebilirlik |
| **Onboarding** | İlk açılış adım adım tanıtım akışı |

### 7.5 ML Modeli Geliştirme

**Veri Seti — AUTSL:**
Ankara Üniversitesi Türk İşaret Dili veri seti; ~28.000 etiketli video, 226 kelime sınıfı, 512×512 MP4 format, stüdyo ortamı (beyaz arka plan, sabit kamera açısı), eğitim/doğrulama/test bölümleri.

**Özellik Çıkarımı (`feature_extraction_v2.py`):**

Her video karesi için 106 boyutlu vektör hesaplanır:

| Segment | Landmark | Boyut | İndeks |
|---------|----------|-------|--------|
| Sağ el | 21 nokta × (x, y) | 42 | [0..41] |
| Sol el | 21 nokta × (x, y) | 42 | [42..83] |
| Vücut | 11 nokta × (x, y) | 22 | [84..105] |

Vücut segmentinde burun, gözler, kulaklar, omuzlar, dirsekler ve bilekler (toplam 11 landmark) kullanılmıştır. Z koordinatı, MediaPipe'ın 2D görüntüden çıkardığı değerin güvenilmez olması nedeniyle kasıtlı olarak dışarıda bırakılmıştır. Her video 60 kareye yeniden örneklenerek model girişi sabit boyuta getirilmiştir.

**Normalizasyon:**
Her segment için bilek / burun noktasına göre merkezleme, ardından maksimum mutlak değere göre ölçekleme uygulanmıştır. Tespit edilemeyen el segmentleri sıfır olarak bırakılır. Aynı normalizasyon formülü Python eğitim kodunda ve Flutter `LandmarkNormalizer` sınıfında birebir eşdeğer biçimde uygulanmaktadır.

**Model Mimarisi (`model_training_v2.py`):**

```
Giriş: (1, 60, 106)
  → LayerNormalization
  → Bidirectional LSTM(128) + BatchNorm + Dropout(0.4)
  → Bidirectional LSTM(64) + BatchNorm + Dropout(0.4)
  → Self-Attention katmanı
  → Dense(256, relu) + BatchNorm + Dropout(0.3)
  → Dense(128, relu) + BatchNorm
  → Dense(226, softmax)
Çıkış: (1, 226)
```

Adam optimizer (lr=1e-3), SparseCategoricalCrossentropy kaybı, ReduceLROnPlateau öğrenme hızı planlayıcısı ve EarlyStopping(patience=15) ile eğitim yapılmıştır.

**Veri Artırma (Augmentation):**
Gaussian gürültü (σ=0.002), ölçek değişimi (±%10), zaman kaydırma (±3 kare) ve kare maskeleme (1-3 rastgele kare sıfırlama) uygulanmıştır. Orijinal ve artırılmış veri birleştirilmiş, eğitim verisi iki katına çıkarılmıştır.

**TFLite Dönüşümü:**
Model INT8 kuantizasyonuyla TFLite formatına dönüştürülmüştür. Sabit giriş boyutu (1, 60, 106) ile batch_size=1 mobil gereksinimi karşılanmıştır. Çıktı dosyası `sign_language_model_v2.tflite` 637 KB boyutundadır ve `frontend/assets/models/` klasörüne yerleştirilmiştir.

**v1 → v2 Geçişinin Önemi:**
v1 modelinde Python eğitim kodunda MediaPipe Holistic, Flutter'da ise hand_detection paketi kullanılıyordu. Bu uyumsuzluk çıkarım hatalarına yol açıyordu. v2'de her iki ortamda da aynı `hand_landmark_full.tflite` modeli kullanılarak eğitim-çıkarım tutarlılığı sağlanmıştır.

### 7.6 Flutter Çıkarım Pipeline'ı

Gerçek zamanlı tanıma şu adımlarla çalışır:

**1. Koordinat Tespiti (her kare):**
El (hand_detection) ve vücut (mlkit_pose) landmark tespiti `Future.wait` ile paralel çalıştırılır. Toplam gecikme `max(el_ms, poz_ms)` olur. Android'de YUV_420_888 → NV21, iOS'te BGRA8888 → BGR dönüşümü uygulanır.

**2. Kayan Pencere Tamponu:**
Son 2000 ms'lik kareler zaman damgasıyla tutulur. El tespiti edilemeyen durumlarda 1 saniyelik grace period uygulanır; 1-2 kare kaybolduğunda tampon bozulmaz. Minimum 600 ms dolmadan çıkarım başlamaz.

**3. Hareket Kapısı:**
El koordinatlarında L2 mesafesi ≥ 0.025 olmadığı sürece çıkarım tetiklenmez. Son hareketten sonra 500 ms boyunca çıkarım devam eder.

**4. 60 Kareye Yeniden Örnekleme:**
`src_idx = i × (n-1) / 59` formülüyle Python `np.linspace` ile eşdeğer örnekleme yapılır; pencere 60'tan kısaysa son kare tekrarlanır.

**5. Normalizasyon:**
Her segment Python'daki ile özdeş merkezleme ve ölçekleme (`LandmarkNormalizer`) uygulanır.

**6. TFLite Çıkarımı:**
`IsolateInterpreter` ile ayrı bir isolate üzerinde çalışır; ana thread'i bloklamaz. En fazla 200 ms'de bir tetiklenir.

**7. Zamansal Düzleştirme:**
Arka arkaya `stableFrames` (varsayılan 5) kez aynı kelime tespit edilirse ve güven skoru eşiği aşılırsa kelime ekranda gösterilir. Yanlış sınıf görüldüğünde streak sıfıra düşmez, yavaşça azalır (soft decay); tek gürültülü kare sonucu bozmaz.

### 7.7 UI/UX Tasarımı

Tasarım yaklaşımında sadelik, temizlik, erişilebilirlik ve akıcı kullanıcı deneyimi ön planda tutulmuştur. Büyük dokunma alanları, net ikonlar ve okunabilir tipografi kullanılmıştır.

Uygulanan erişilebilirlik özellikleri:
- Açık, koyu ve sistem teması desteği
- Yazı boyutu ölçeklendirme (Küçük / Standart / Büyük / Çok Büyük)
- Türkçe TTS (Text-to-Speech) desteği; açma/kapama toggle'ı
- Haptic feedback desteği; açma/kapama toggle'ı
- Sol el modu (landmark aynalama)

### 7.8 Test ve İyileştirme

Her modül geliştirme sürecinde ayrı ayrı test edilmiştir. Değerlendirme kriterleri:

- Kullanıcı akışı ve navigasyon tutarlılığı (misafir / kayıtlı kullanıcı)
- Arayüz kullanılabilirliği ve erişilebilirlik
- Tanıma performansı farklı cihaz sınıflarında (entry-level'dan flagship'e)
- Beklenmeyen hareketlere ve kenar durumlara tepki
- Eğitim-çıkarım koordinat uyumu

---

## 8. UI/UX Detayları

### Tasarım Yaklaşımı

Hear Me Out'un tasarım dili; **sade**, **hızlı**, **anlaşılır** ve **erişilebilir** olacak şekilde oluşturulmuştur. İşitme engelli kullanıcılar ve işaret diliyle ilk kez karşılaşan bireyler için kafa karışıklığını azaltan bir yapı hedeflenmiştir.

### Kullanıcı Akışı

Uygulama açıldığında:

1. **Welcome ekranı** — Uygulamanın tanıtımı, giriş yap / kayıt ol seçenekleri ve misafir kamera erişimi
2. **Onboarding** — İlk açılışta adım adım özellik tanıtımı
3. **Giriş / Kayıt** — E-posta ve şifre ile kimlik doğrulama
4. **Ana ekran** — 5 sekmeli alt navigasyon: Anasayfa, Sözlük, Tanıma/Çeviri, Geçmiş, Profil

Tanıma ve çeviri ekranları arasında swipe geçişi desteklenmektedir.

### Kayıt Olmaya Teşvik

Kayıtlı kullanıcı avantajları şu şekilde sunulmuştur:

- Tanınan her işaretin otomatik geçmiş kaydı (RECOGNITION / DICTIONARY / TRANSLATION ayrımıyla)
- Yer imleri ve favoriler
- Profil yönetimi ve avatar yükleme
- Bulut senkronizasyonu (opsiyonel; "zero data mode" ile tamamen devre dışı bırakılabilir)

Bu yapı kullanıcıyı zorlamadan kayıt olmaya teşvik etmektedir.

### Acil Kullanım Senaryosu

Misafir kamera modu; kayıt gerektirmeden, tam ekran ve dikkat dağıtmayan sade bir arayüzle anlık işaret tanıma erişimi sunmaktadır. Bu sayede acil durumlarda iletişim süreci hızlandırılmaktadır.

---

## 9. Veri Analizi ve Modelleme

### Veri Kaynağı

**AUTSL (Ankara University Turkish Sign Language Dataset)**

- ~28.000 etiketli video
- 226 farklı TİD kelimesi (sınıf)
- 512×512 çözünürlük, MP4 format, stüdyo ortamı (beyaz arka plan, sabit kamera açısı)
- Eğitim, doğrulama ve test bölümleri ile etiket CSV dosyaları

### Özellik Çıkarımı

Model girdisi, 106 boyutlu vektörlerden oluşan 60 karelik bir zaman dizisidir:

- **Sağ el:** 21 landmark × (x, y) = 42 boyut
- **Sol el:** 21 landmark × (x, y) = 42 boyut
- **Vücut:** 11 seçilmiş landmark × (x, y) = 22 boyut (burun, gözler, kulaklar, omuzlar, dirsekler, bilekler)

Koordinatlar per-segment normalizasyonla standartlaştırılır: bilek / burun noktasına göre merkezleme, ardından maksimum mutlak değere göre ölçekleme.

### Model Mimarisi

**BiLSTM + Self-Attention** mimarisi, hareketlerin zaman içindeki bağlamını her iki yönde (ileri-geri) analiz ederek birbirine benzer işaretlerin daha doğru ayırt edilmesini sağlamaktadır. Self-Attention katmanı, 60 kare içindeki en bilgilendirici zaman adımlarına otomatik olarak ağırlık verir.

### Mobilde Çalıştırma

Eğitim tamamlandıktan sonra model INT8 kuantizasyonuyla TensorFlow Lite formatına dönüştürülmüştür.

Bu sayede:

- İnternet bağımlılığı ortadan kalkmıştır
- Gecikme azaltılmıştır
- Kullanıcı görüntüsü sunucuya gönderilmediğinden gizlilik korunmaktadır
- 637 KB boyutuyla mobil kullanıma uygundur

---

## 10. Teknik Kısıtlamalar

| Kısıtlama | Açıklama |
|-----------|----------|
| **Stüdyo ortamı eğitimi** | AUTSL beyaz arka plan ve sabit kamera açısıyla çekilmiştir; gerçek dünya performansı daha düşük olabilir |
| **Sabit kamera açısı** | Model yalnızca önden çekim için optimize edilmiştir; farklı açılar dağılım dışı kalır |
| **Z koordinatı kullanılmamıştır** | MediaPipe'ın 2D görüntüden çıkardığı Z değeri güvenilmez olduğundan 106 boyutlu vektöre dahil edilmemiştir |
| **Sabit kelime dağarcığı** | 226 kelime; yeni kelime eklenmesi için modelin yeniden eğitilmesi gerekmektedir |
| **Minimum Android SDK 24** | MLKit ve TFLite gereksinimleri nedeniyle Android 7.0 ve üzeri cihazlar desteklenmektedir |
| **Desteklenen mimariler** | arm64-v8a ve armeabi-v7a; opencv_dart bağımlılığı nedeniyle x86/x86_64 desteklenmemektedir |

---

## 11. Proje Yönetimi ve Ekip İşleyişi

Proje yönetimi sprint tabanlı bir yaklaşımla planlanmıştır.

**Örnek Sprint Yapısı:**

| Sprint | Kapsam |
|--------|--------|
| Sprint 1 | Temel mimari, veritabanı şeması, Prisma kurulumu |
| Sprint 2 | Backend API (auth, sözlük, geçmiş, yer imi), JWT entegrasyonu |
| Sprint 3 | Flutter navigasyon, auth ekranları, sözlük modülü |
| Sprint 4 | ML pipeline, TFLite entegrasyonu, tanıma ekranı |
| Sprint 5 | Çeviri ekranı, geçmiş, yer imleri, profil modülü |
| Sprint 6 | UI/UX iyileştirmeleri, erişilebilirlik, test ve sunum hazırlığı |

**Önerilen Ekip Rolleri:**

- Proje yöneticisi / Scrum Master
- Flutter geliştirici (frontend)
- Node.js geliştirici (backend)
- ML mühendisi (model eğitimi ve Flutter entegrasyonu)
- UI/UX tasarımcısı

---

## 12. Canlı Demo Planı

Önerilen demo akışı:

1. Uygulamanın amacı ve hedef kitlesi
2. Misafir erişimi ve acil kullanım senaryosu
3. Kayıt / giriş ve kayıtlı kullanıcı deneyimi
4. Gerçek zamanlı işaret tanıma (kamera ile canlı demo)
5. Metinden işaret diline çeviri (metin girişi → video oynatma)
6. Sözlük araması ve kelime detayı
7. UI/UX tasarım vurgusu (tema, erişilebilirlik ayarları)
8. ML modeli ve backend altyapısına teknik bakış

---

## 13. Sonuç

**Hear Me Out**, Türk İşaret Dili iletişimini desteklemek amacıyla geliştirilen; erişilebilirlik, hız ve çevrimdışı kullanım odağında tasarlanmış bir mobil uygulamadır.

BiLSTM + Self-Attention mimarisine dayalı, 637 KB boyutundaki TFLite modeli sayesinde internet bağlantısı gerektirmeksizin 226 Türk İşaret Dili kelimesini gerçek zamanlı olarak tanıyabilen uygulama; misafir erişimi, metin çevirisi, kapsamlı sözlük ve kullanıcı hesabı özellikleriyle bütünleşik bir deneyim sunmaktadır.

Eğitim ve çıkarım ortamında aynı MediaPipe landmark dedektörünün kullanılması, modelin mobil performansını doğrudan iyileştiren kritik bir tasarım kararıdır. Sade ve erişilebilir kullanıcı arayüzüyle uygulama, işitme engelli bireyler ile toplum arasındaki iletişim bariyerini azaltmayı hedeflemektedir.
