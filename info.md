📑 PROJE MASTER RAPORU: HEAR ME OUT
Konu: Sağlık Teknolojileri & Engelli Erişilebilirliği
Mimar: Habil Yazıcı
Hedef: İşitme/Konuşma Engelli Bireyler İçin Çift Yönlü İletişim Köprüsü

1. PROJE VİZYONU VE PROBLEM TANIMI
Geleneksel iletişim araçları, işaret dili bilmeyen bireylerle işitme/konuşma engelliler arasında büyük bir bariyer oluşturur. Hear Me Out, bu bariyeri aşmak için mobil cihazın kamerasını ve mikrofonunu birer "tercümana" dönüştürür.
Sağlık Odak Noktası: Acil durumlar, hastane randevuları ve temel sağlık ihtiyaçlarının anlık olarak işaret dilinden metne (ve tersi) çevrilmesi.

2. TEKNİK MİMARİ STRATEJİSİ (SENIOR LEVEL)
Proje, modülerliği ve ölçeklenebilirliği en üst düzeye çıkarmak için Clean Architecture (Temiz Mimari) ve Feature-First (Özellik Odaklı) yaklaşımlarını birleştirir.
📱 2.1. Frontend: Flutter (Dart)
State Management: Riverpod (Tip güvenliği ve test edilebilirlik için).
💻 2.2. Backend: Node.js & Express
Veritabanı Katmanı (ORM): Prisma. SQL sorgularını tip güvenli ve modern bir şema yapısıyla yönetir.
Veritabanı: PostgreSQL. İlişkisel veriler, kullanıcı geçmişi ve sözlük yapısı için.

3. YAPAY ZEKA VE GÖRÜNTÜ İŞLEME MODELİ
Projenin "kalbi" olan işaret dili tanıma sistemi, düşük gecikme (latency) için cihaz üzerinde (On-device) çalışır.
Teknoloji: Google MediaPipe + TensorFlow Lite.
Yöntem: Kameradan gelen görüntü doğrudan işlenmez. MediaPipe eldeki 21 ana noktayı (landmark) çıkarır.
Model Girdisi: Bu koordinatlar ($x, y, z$) bir sayı dizisi olarak senin eğiteceğin LSTM (Long Short-Term Memory) yapay sinir ağına sokulur.
Sonuç: Video akışı saniyede 30 kare (FPS) hızında, internete ihtiyaç duymadan anlık olarak metne çevrilir.

4. VERİ VE VİDEO YÖNETİMİ
Uygulama boyutunu düşük tutmak ve performansı artırmak için hibrit bir yol izlenir:
Cloud-Based Videos: İşaret dili videoları backend tarafından yönetilen bir bulut depolama (CDN) üzerinde tutulur.
Smart Caching: flutter_cache_manager kullanılarak izlenen videolar telefona kaydedilir; böylece ikinci kullanımda internet harcanmaz ve gecikme yaşanmaz.
REST API: Flutter ve Node.js arasındaki iletişim JSON formatında, standart RESTful prensipleriyle gerçekleşir.

5. KULLANICI DENEYİMİ (UX) VE EKRANLAR
Uygulama "Guest-First" (Önce Misafir) felsefesini benimser:
Giriş Yapmadan Kullanım: Acil durumlarda vakit kaybetmemek için tüm çeviri özellikleri açıktır.
Hesap Yönetimi (Opsiyonel): Kullanıcı kayıt olduğunda geçmiş çevirileri, favori işaretleri ve "Kişisel Sağlık Kartı" (kan grubu, kronik hastalıklar vb.) PostgreSQL üzerinde saklanır.
Hata Yönetimi: Yapay zeka tahmin skoru (Confidence Score) düşükse kullanıcıya görsel uyarı verilir ve manuel düzeltme imkanı sunulur.

6. GÜVENLİK VE KVKK (YBS ODAĞI)
Veri Güvenliği: Sağlık verileri profil sayfasında ele alınırken KVKK standartlarına uygunluk gözetilir.
Encryption: Backend tarafında kullanıcı şifreleri bcrypt ile, hassas veriler ise projenin ilerleyen safhalarında AES-256 ile şifrelenecektir.

7. TEKNOLOJİ STACK ÖZETİ ()
Mobile: Flutter (Riverpod, Dio, Camera, Video Player)
Backend: Node.js, Express.js, Prisma ORM
Database: PostgreSQL
AI/ML: Python (Training - Colab), MediaPipe & TFLite (Deployment)
Infrastructure: Docker, Render/Railway (Deployment)

Frontend:
lib/
├── core/                        # Uygulamanın "Kalbi" (Hiç değişmez)
│   ├── constants/               # api_constants.dart, app_strings.dart
│   ├── theme/                   # app_theme.dart (Renkler, fontlar)
│   ├── error/                   # failure.dart (Hata yönetimi sınıfları)
│   └── network/                 # dio_client.dart (İnternet istekleri merkezi)
│
├── features/                    # Uygulamanın "Kasları" (Özellikler)
│   ├── recognition/             # İşaret Dili Tanıma Özelliği
│   │   ├── data/                # Veri: repository_impl.dart, model.dart, source.dart
│   │   ├── domain/              # İş: repository_interface.dart, use_case.dart
│   │   └── presentation/        # UI: screen.dart, provider.dart, widget/
│   │
│   ├── translator/              # Ses -> İşaret (Video) Özelliği
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   └── profile/                 # Hesap ve Sağlık Kartı Özelliği
│       ├── data/
│       ├── domain/
│       └── presentation/
│
├── shared/                      # Ortak kullanılan widgetlar (CustomButton vb.)
└── main.dart                    # Uygulama başlangıcı ve Riverpod ProviderScope


Beckend:
src/
├── api/                         # Dışarıya açılan kapı
│   ├── controllers/             # Gelen HTTP isteklerini parse eder
│   ├── routes/                  # URL yollarını tanımlar (/auth, /translate)
│   └── middlewares/             # auth_middleware.js, error_handler.js
│
├── services/                    # İş Mantığı (Logic)
│   # Örn: translator.service.js (Burada videoyu bulup mantıksal kontrol yapar)
│
├── repositories/                # Veritabanı Erişim (Prisma burada kullanılır)
│   # Örn: user.repository.js (Sadece DB'ye gider, mantıkla uğraşmaz)
│
├── prisma/                      # Veri Tabanı Şeması
│   └── schema.prisma            # Tablolarının ve ilişkilerinin kalbi
│
├── config/                      # env_vars.js, db_config.js
└── app.js                       # Express ve Socket.io konfigürasyonu


