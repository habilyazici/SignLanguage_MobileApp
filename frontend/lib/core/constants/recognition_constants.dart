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

  /// İlk inference için gereken minimum pencere süresi (ms)
  static const int minWindowMs = 800;

  // ── Inference hız kontrolü ────────────────────────────────────────────────
  /// Her kaçıncı işlenen karede inference yapılır
  static const int inferEvery = 5;

  // ── Temporal smoothing ────────────────────────────────────────────────────
  /// Aynı sınıfın kaç ardışık inference'ta görülmesi gerektiği
  static const int stableFrames = 5;

  // ── Hareket algılama ─────────────────────────────────────────────────────
  /// Normalize uzayında ortalama mutlak fark eşiği (0..1 arası).
  /// 0.008 = nefes/kamera titremesi yeterli (çok hassas).
  /// 0.025 = gerçek el hareketi gerektirir.
  static const double motionThreshold = 0.025;

  /// Son hareketten bu kadar ms sonra inference durur
  static const int motionWindowMs = 1000;
}
