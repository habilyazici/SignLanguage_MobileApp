/// TFLite model ve ML pipeline için sabit değerler.
///
/// TUNING GUIDE — Modeli veya tanıma davranışını değiştirmek istersen buraya bak:
///   Model mimarisi     → windowSize, featureSize, numClasses
///   Hız/gecikme        → inferIntervalMs, minInferenceFrames
///   Tanıma kalitesi    → streakNoiseFloor (en kritik: bkz. açıklama)
///   Hareket hassasiyeti→ motionThreshold, motionWindowMs
///   Performans (CPU)   → poseEvery, poseEveryMax, kLatencyRampUpMs/Down
///   UX zamanlamaları   → noDetectionGracePeriodMs, sentenceClearMs, sameWordCooldownMs
///
/// AppSettings'teki ayarlar (kullanıcı tarafından değiştirilebilir):
///   stableFramesThreshold, confidenceLevel, motionThreshold, fpsPreference
abstract final class RecognitionConstants {
  // ── Model mimarisi ────────────────────────────────────────────────────────
  /// Modelin giriş penceresi (kare sayısı)
  static const int windowSize = 60;

  /// Her kare için feature vektörü boyutu
  /// [0..41] sağ el · [42..83] sol el · [84..105] pose (11 nokta × 2)
  static const int featureSize = 106;

  /// Referans sınıf sayısı — sadece dokümantasyon amaçlı.
  /// Gerçek inference sınıf sayısı InferenceDatasource.numClasses'tan okunur
  /// (modelin çıkış tensor shape'i). Yeni model yüklendiğinde burayı
  /// güncellemeye gerek yok; model otomatik algılar.
  static const int numClasses = 226;

  // ── Zaman tabanlı pencere ─────────────────────────────────────────────────
  /// Kayan pencere süresi (ms) — son N ms'lik kareler pencereye alınır
  static const int windowMs = 2000;

  /// İlk inference için gereken minimum pencere süresi (ms).
  /// 600ms: yavaş cihazlarda (A32 ~130ms/frame) 4-5 gerçek frame → erken tepki.
  /// Hızlı cihazlarda (30fps) 600ms ≈ 18 frame → yeterli temporal bilgi.
  static const int minWindowMs = 600;

  /// Inference tetiklemek için gereken minimum gerçek frame sayısı.
  /// 4 frame ≈ 600ms sinyal (yavaş cihazlarda A32 ~130ms/frame).
  static const int minInferenceFrames = 4;

  // ── Inference hız kontrolü ────────────────────────────────────────────────
  /// İki ardışık inference arasındaki minimum süre (ms).
  /// Frame sayısına değil zamana göre throttle — cihaz hızından bağımsız.
  /// 250ms = saniyede max ~4 inference; stableFrames=2 ile onay ~500ms.
  /// (Eskiden 350ms idi; azaltıldı çünkü doğru kelimeler streak dolmadan
  ///  model başka sınıfa geçiyordu — daha sık inference streak birikimini hızlandırır.)
  static const int inferIntervalMs = 250;

  // ── Streak (kararlılık) gürültü eşiği ─────────────────────────────────────
  /// Ana tanıma bug'ı için kritik sabittir.
  ///
  /// SORUN: Model doğru kelimeyi tahmin ediyor (dev panelde görünüyor) ama
  /// ekrana yansımıyor. Neden? Confidence eşiği (örn. 0.75) altında kalan
  /// her inference, streak sayacını 1 azaltıyordu. Böylece streak hiç
  /// birikmeden sürekli sıfırlanıyordu.
  ///
  /// ÇÖZÜM: Streak yalnızca bu eşiğin ALTINDA net gürültü inference'larında
  /// azalır. Bu eşik ile güven eşiği (örn. 0.75) arasındaki "gri bölge" streak'i
  /// ne artırır ne azaltır — tarafsız kalır ve birikime izin verir.
  ///
  /// 0.40: Model bu skoru başka sınıfa veriyorsa gerçekten belirsiz → azalt.
  ///       0.40-0.75 arası: model doğruya yakın ama kesin değil → streak koru.
  static const double streakNoiseFloor = 0.40;

  // ── Pose örnekleme ───────────────────────────────────────────────────────
  /// Pose detection her kaçıncı işlenen karede çalışır.
  /// Araya giren karelerde son bilinen pose değerleri taşınır.
  /// hand detection her frame çalışmaya devam eder (asıl darboğaz).
  /// Yavaş cihazlarda (latency > kLatencyRampUpMs) bu değer otomatik artar.
  static const int poseEvery = 1;

  /// Bu eşiğin (ms) üzerinde latency ölçülürse poseEvery bir adım artar.
  /// Histerezis için rampDown < rampUp — tam eşikte sürekli salınım engellenir.
  static const int kLatencyRampUpMs = 120;

  /// Bu eşiğin (ms) altına düşerse poseEvery bir adım azalır.
  static const int kLatencyRampDownMs = 80;

  /// Geriye uyumluluk takma adı — kodu bozmadan dışarıdan referans alanlar için.
  static const int kLatencySlowMs = kLatencyRampUpMs;

  /// poseEvery'nin ulaşabileceği maksimum değer.
  static const int poseEveryMax = 6;

  // ── Hareket algılama ─────────────────────────────────────────────────────
  /// Normalize uzayında ortalama mutlak fark eşiği (0..1 arası).
  /// 0.008 = nefes/kamera titremesi yeterli (çok hassas).
  /// 0.025 = gerçek el hareketi gerektirir.
  static const double motionThreshold = 0.030;

  /// Son hareketten bu kadar ms sonra inference durur.
  /// 800ms: hareket bittikten sonra elde yeterli inference fırsatı (~5 inference)
  /// sağlanır. Çok düşük tutmak statik/yavaş işaretlerin kaçırılmasına yol açar.
  static const int motionWindowMs = 800;

  // ── Pipeline zamanlama sabitleri ──────────────────────────────────────────
  /// El tespit edilmediğinde buffer temizlenmeden önce beklenen süre (ms).
  /// 1-2 frame kayıplarında buffer bozulmasını önler.
  static const int noDetectionGracePeriodMs = 1000;

  /// Yeni kelime gelmezse cümlenin otomatik silineceği süre (ms).
  static const int sentenceClearMs = 4000;

  /// Aynı kelimenin tekrar kabul edilebilmesi için minimum süre (ms).
  /// Buffer clear + motion gate fiziksel minimumu ~1.15s — bu süre onun
  /// altında olduğundan kazara çift tetik mümkün değil.
  static const int sameWordCooldownMs = 1000;

  // ── Koordinat ayrımı ─────────────────────────────────────────────────────
  /// hand_detection kütüphanesinden gelen koordinatın normalize [0,1] mi
  /// yoksa piksel değeri mi olduğunu ayırt etmek için eşik.
  /// Bu değerin altı → normalize, üstü → piksel koordinatı.
  /// Tracking artifact'larında küçük taşmalar (1.01 gibi) hâlâ normalize
  /// sayılır; 1.05 üzerindeki değerler piksel koordinatı kabul edilir.
  static const double handCoordNormThreshold = 1.05;
}
