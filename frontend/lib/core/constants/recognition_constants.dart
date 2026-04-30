/// TFLite model ve ML pipeline için sabit değerler.
/// Bu değerler modeli ve eğitim verisini yansıtır —
/// model yeniden eğitilirse burası güncellenmeli.
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

  // ── Inference hız kontrolü ────────────────────────────────────────────────
  /// İki ardışık inference arasındaki minimum süre (ms).
  /// Frame sayısına değil zamana göre throttle — cihaz hızından bağımsız.
  /// 200ms = saniyede max 5 inference; stableFrames=5 ile onay ~1sn.
  static const int inferIntervalMs = 200;

  // ── Temporal smoothing ────────────────────────────────────────────────────
  /// Aynı sınıfın kaç ardışık inference'ta görülmesi gerektiği
  static const int stableFrames = 5;

  // ── Pose örnekleme ───────────────────────────────────────────────────────
  /// Pose detection her kaçıncı işlenen karede çalışır.
  /// Araya giren karelerde son bilinen pose değerleri taşınır.
  /// hand detection her frame çalışmaya devam eder (asıl darboğaz).
  /// Yavaş cihazlarda (latency > kLatencySlowMs) bu değer otomatik artar.
  static const int poseEvery = 1;

  /// Bu eşiğin (ms) üzerinde latency ölçülürse poseEvery bir adım artar.
  static const int kLatencySlowMs = 100;

  /// poseEvery'nin ulaşabileceği maksimum değer.
  static const int poseEveryMax = 6;

  // ── Hareket algılama ─────────────────────────────────────────────────────
  /// Normalize uzayında ortalama mutlak fark eşiği (0..1 arası).
  /// 0.008 = nefes/kamera titremesi yeterli (çok hassas).
  /// 0.025 = gerçek el hareketi gerektirir.
  static const double motionThreshold = 0.025;

  /// Son hareketten bu kadar ms sonra inference durur
  static const int motionWindowMs = 1000;
}
