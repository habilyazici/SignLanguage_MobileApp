/// TFLite modelinin tek bir inference'tan döndürdüğü ham sonuç.
class InferenceResult {
  final int classIndex;
  final double confidence;

  const InferenceResult({
    required this.classIndex,
    required this.confidence,
  });

  /// Sentinel değer: tespit yok / buffer temizlendi.
  /// Notifier bunu alınca ekranı sıfırlar.
  static const InferenceResult empty =
      InferenceResult(classIndex: -1, confidence: 0.0);
}
