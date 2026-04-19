/// TFLite modelinin tek bir inference'tan döndürdüğü ham sonuç.
class InferenceResult {
  final int classIndex;
  final double confidence;

  /// Modelin en yüksek olasılıklı ilk 3 tahmini (dev modu için).
  final List<({int classIndex, double confidence})> topPredictions;

  const InferenceResult({
    required this.classIndex,
    required this.confidence,
    this.topPredictions = const [],
  });

  /// Sentinel değer: tespit yok / buffer temizlendi.
  static const InferenceResult empty =
      InferenceResult(classIndex: -1, confidence: 0.0);
}
