library;

/// HEAR ME OUT — Landmark Normalization
///
/// Python'daki [model_training.py] `normalize_landmarks_pro` fonksiyonunun
/// birebir Dart karşılığıdır. TFLite modelinin doğru çalışabilmesi için
/// kamera karelerinin, eğitim verisindeki normalizasyonla TAM AYNI
/// matematiksel forma sokulması zorunludur.
///
/// Model girdi formatı: 60 kare × 106 koordinat
///   `[0..41]`   → Sağ el  (21 nokta × x,y)
///   `[42..83]`  → Sol el  (21 nokta × x,y)
///   `[84..105]` → Pose üst vücut (11 nokta × x,y — seçili MediaPipe indeksleri: 0,2,5,7,8,11,12,13,14,15,16)

class LandmarkNormalizer {
  // Sıfıra bölme hatasını engellemek için küçük sabit (Python'daki 1e-6 ile aynı)
  static const double _eps = 1e-6;

  /// Tek bir kareyi (106 koordinat) normalize eder.
  ///
  /// Her segment (sağ el, sol el, pose) için:
  ///   1. Referans noktaya göre merkezleme (el → bilek, pose → burun)
  ///   2. Max-abs ölçeklendirme (boyut bağımsız hale getirme)
  ///
  /// Eğer bir segment tamamen sıfırsa (o an tespit edilmedi) atlanır.
  static List<double> normalizeFrame(List<double> frame) {
    assert(
      frame.length == 106,
      'Frame uzunluğu 106 olmalıdır, gelen: ${frame.length}',
    );

    final f = List<double>.from(frame);

    // ── SAĞ EL (0..41) ─────────────────────────────────────────────────────
    if (!_isAllZero(f, 0, 42)) {
      // Bilek (nokta 0) → merkez
      final wx = f[0], wy = f[1];
      for (int i = 0; i < 42; i += 2) {
        f[i] -= wx;
        f[i + 1] -= wy;
      }
      // Max-abs ölçeklendirme
      final scale = _maxAbs(f, 0, 42) + _eps;
      for (int i = 0; i < 42; i++) {
        f[i] /= scale;
      }
    }

    // ── SOL EL (42..83) ────────────────────────────────────────────────────
    if (!_isAllZero(f, 42, 42)) {
      // Bilek (nokta 0 → indeks 42) → merkez
      final wx = f[42], wy = f[43];
      for (int i = 0; i < 42; i += 2) {
        f[42 + i] -= wx;
        f[43 + i] -= wy;
      }
      final scale = _maxAbs(f, 42, 42) + _eps;
      for (int i = 0; i < 42; i++) {
        f[42 + i] /= scale;
      }
    }

    // ── POSE (84..105) ─────────────────────────────────────────────────────
    if (!_isAllZero(f, 84, 22)) {
      // Burun (nokta 0 → indeks 84) → merkez
      final nx = f[84], ny = f[85];
      for (int i = 0; i < 22; i += 2) {
        f[84 + i] -= nx;
        f[85 + i] -= ny;
      }
      final scale = _maxAbs(f, 84, 22) + _eps;
      for (int i = 0; i < 22; i++) {
        f[84 + i] /= scale;
      }
    }

    return f;
  }

  /// 60 karelik sliding-window tamponunu topluca normalize eder.
  ///
  /// Giriş:  60 adet `List<double>` (her biri 106 koordinat)
  /// Çıkış:  Normalize edilmiş kopyası — orijinal liste değişmez
  static List<List<double>> normalizeWindow(List<List<double>> window) {
    assert(
      window.length == 60,
      'Window boyutu 60 olmalıdır, gelen: ${window.length}',
    );
    return window.map(normalizeFrame).toList();
  }

  // ── Yardımcılar ──────────────────────────────────────────────────────────

  /// [start] indeksinden başlayarak [length] kadar elemanın tamamı 0.0 mı?
  /// Python: `np.all(arr == 0)` karşılığı
  static bool _isAllZero(List<double> list, int start, int length) {
    for (int i = 0; i < length; i++) {
      if (list[start + i] != 0.0) return false;
    }
    return true;
  }

  /// [start] indeksinden başlayarak [length] elemanın en büyük mutlak değeri
  /// Python: `np.max(np.abs(arr))` karşılığı
  static double _maxAbs(List<double> list, int start, int length) {
    double max = 0.0;
    for (int i = 0; i < length; i++) {
      final v = list[start + i].abs();
      if (v > max) max = v;
    }
    return max;
  }
}
