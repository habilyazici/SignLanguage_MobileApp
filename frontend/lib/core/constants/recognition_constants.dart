/// Tanıma pipeline'ının tüm ayarlanabilir parametreleri.
///
/// Kullanıcı arayüzünden değiştirilebilen ayarlar (güven seviyesi, FPS,
/// kararlılık eşiği, hareket hassasiyeti) AppSettings'tedir.
/// Buradakiler geliştirici/ML tarafı — doğrudan bu dosyadan değiştir.
abstract final class RecognitionConstants {

  // ════════════════════════════════════════════════════════════════
  // MODEL
  // Model yeniden eğitilirse bu bölümdeki değerleri kontrol et.
  // ════════════════════════════════════════════════════════════════

  /// Modelin beklediği giriş kare sayısı. Değiştirme.
  static const int windowSize = 60;

  /// Her kare için özellik vektörü boyutu. Değiştirme.
  /// [0..41] sağ el (21 nokta × xy) · [42..83] sol el · [84..105] pose (11 nokta × xy)
  static const int featureSize = 106;

  /// Sadece dokümantasyon için — gerçek değer modelden otomatik okunur.
  static const int numClasses = 226;

  // ════════════════════════════════════════════════════════════════
  // TANIMA KALİTESİ
  // Doğru kelimeler çıkmıyorsa veya yanlışlar çok geliyorsa buraya bak.
  // ════════════════════════════════════════════════════════════════

  /// Model güven skoru bu değerin altındaysa streak azalır (net gürültü).
  /// Bu değer ile AppSettings.confidenceThreshold arasındaki skor streak'i
  /// ne artırır ne azaltır — model doğruya yakın ama emin değil demektir.
  ///
  /// 0.40 iyi başlangıç. Model çok yanlış sınıf veriyorsa artır (0.45–0.50).
  /// Çok azaltırsan doğru kelimeler daha kolay çıkar ama yanlışlar da artar.
  static const double streakNoiseFloor = 0.40;

  // ════════════════════════════════════════════════════════════════
  // ZAMANLAMA
  // İnference hızı ve buffer davranışı.
  // ════════════════════════════════════════════════════════════════

  /// Buffer'da tutulan maksimum süre (ms). Değiştirme — modelle bağlantılı.
  static const int windowMs = 2000;

  /// İlk inference'ın tetiklenmesi için gereken minimum buffer yaşı (ms).
  /// Çok düşürürsen az frame ile inference çalışır, doğruluk düşer.
  static const int minWindowMs = 600;

  /// İnference tetiklenmesi için gereken minimum gerçek frame sayısı.
  static const int minInferenceFrames = 4;

  /// İki ardışık inference arasındaki minimum bekleme süresi (ms).
  ///
  /// Azalt (örn. 200) → daha hızlı tepki, CPU kullanımı artar.
  /// Artır (örn. 350) → daha yavaş ama pil dostu.
  /// defaultStableFrames=3 ile: onay süresi ≈ inferIntervalMs × 3 = ~600ms
  static const int inferIntervalMs = 200;

  // ════════════════════════════════════════════════════════════════
  // HAREKET ALGILAMA
  // El duruyorken inference tetiklenmesin diye.
  // ════════════════════════════════════════════════════════════════

  /// Normalize uzayında ortalama landmark hareketi eşiği (0.0–1.0).
  /// Varsayılan: AppSettings.motionThreshold üzerinden ezilir.
  ///
  /// 0.010 → çok hassas, nefes/kamera titremesi bile tetikler.
  /// 0.035 → dengeli — mikro-hareketleri filtreler, işaret hareketlerini kaçırmaz.
  /// 0.050 → yalnızca belirgin hareketler tetikler.
  static const double motionThreshold = 0.035;

  /// Son hareketten kaç ms sonra inference duracak (ms).
  /// Çok düşürürsen durağan (static) işaretler kaçabilir.
  /// Çok artırırsan el durduktan sonra gereksiz inference çalışır.
  static const int motionWindowMs = 1000;

  // ════════════════════════════════════════════════════════════════
  // PERFORMANS
  // Yavaş cihazlarda CPU'yu korumak için pose örnekleme ayarları.
  // ════════════════════════════════════════════════════════════════

  /// Pose detection her kaçıncı karede çalışsın (1 = her kare).
  /// El detection her kare çalışmaya devam eder.
  static const int poseEvery = 1;

  /// Yavaş cihazda poseEvery'nin ulaşabileceği maksimum değer.
  static const int poseEveryMax = 6;

  /// Frame latency bu değeri aşarsa poseEvery bir adım artar.
  static const int kLatencyRampUpMs = 120;

  /// Frame latency bu değerin altına düşerse poseEvery bir adım azalır.
  /// rampDown < rampUp olduğu için eşik değerinde salınım olmaz.
  static const int kLatencyRampDownMs = 80;

  /// TFLite interpreter'ın kullanacağı thread sayısı.
  /// Artırırsan inference hızlanır ama pil tüketimi artar.
  static const int tfliteThreads = 4;

  // ════════════════════════════════════════════════════════════════
  // EKRAN & UX
  // Kelime/cümle gösterim davranışı.
  // ════════════════════════════════════════════════════════════════

  /// Ekranda aynı anda gösterilecek maksimum kelime sayısı.
  static const int sentenceMaxWords = 6;

  /// Yeni kelime gelmezse cümle kaç ms sonra silinsin.
  static const int sentenceClearMs = 5000;

  /// Aynı kelime tekrar kabul edilebilmesi için gereken bekleme süresi (ms).
  static const int sameWordCooldownMs = 1000;

  /// El kaybolunca buffer kaç ms sonra temizlensin.
  /// Kısa el kayboluşlarında (1–2 frame) buffer bozulmasın diye.
  static const int noDetectionGracePeriodMs = 1000;

  /// Dev modunda gösterilecek top-N tahmin sayısı.
  static const int topPredictionsCount = 3;

  // ════════════════════════════════════════════════════════════════
  // TEKNİK — Değiştirme
  // ════════════════════════════════════════════════════════════════

  /// hand_detection koordinatının normalize [0,1] mi, piksel mi olduğunu ayırt eder.
  /// Kütüphane davranışına bağlı — değiştirme.
  static const double handCoordNormThreshold = 1.05;

  // ════════════════════════════════════════════════════════════════
  // KULLANICI AYARLARI DEFAULTLARI
  // AppSettings constructor'ı bu değerleri kullanır.
  // Değiştirince AppSettings'in varsayılanı da değişir — rebuild gerekir.
  // Runtime'da kullanıcı Ayarlar → İleri Seviye'den ezebilir.
  // ════════════════════════════════════════════════════════════════

  /// Kaç ardışık inference aynı sınıfı verirse kelime kabul edilir.
  /// Düşür (1) → hızlı tepki, yanlış pozitif riski artar.
  /// Artır (3–4) → daha kararlı, minimum kabul süresi = değer × inferIntervalMs.
  static const int defaultStableFrames = 3;

  // motionThreshold: yukarıdaki motionThreshold sabiti aynı zamanda AppSettings defaultu.
  // stableFramesThreshold için defaultStableFrames'i kullan.

  // ── Enum tabanlı ayarlar (doğrudan bağlanamaz, app_settings.dart'ta değiştir) ──
  // confidenceThreshold: low=0.65 · medium=0.75 (varsayılan) · high=0.85
  //   → AppSettings.confidenceLevel = ConfidenceLevel.medium
  // targetFps: powerSaver=15 · balanced=20 · performance=30 (varsayılan) · unlimited=0
  //   → AppSettings.fpsPreference = FpsPreference.performance
}
