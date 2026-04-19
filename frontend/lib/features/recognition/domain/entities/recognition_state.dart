import 'dart:ui' show Offset;

// ─────────────────────────────────────────────────────────────────────────────
// Developer modu için landmark görselleştirme verisi
// ─────────────────────────────────────────────────────────────────────────────

class LandmarkDevData {
  final List<Offset> posePoints;
  final List<Offset> rightHand;
  final List<Offset> leftHand;
  final int bufferFill;
  final int poseCount;
  final int handCount;

  /// Modelin en yüksek olasılıklı ilk 3 tahmini (Türkçe etiket + güven skoru).
  final List<({String word, double confidence})> topPredictions;

  LandmarkDevData({
    required this.posePoints,
    required this.rightHand,
    required this.leftHand,
    required this.bufferFill,
    required this.poseCount,
    required this.handCount,
    this.topPredictions = const [],
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Recognition durum entity'si — platform bağımlılığı yok
// CameraController presentation katmanında tutulur (cameraControllerProvider)
// ─────────────────────────────────────────────────────────────────────────────

class RecognitionState {
  final bool isReady;
  final bool isError;
  final String predictedWord;
  final double confidenceScore;
  final List<String> sentence;

  const RecognitionState({
    this.isReady = false,
    this.isError = false,
    this.predictedWord = '',
    this.confidenceScore = 0.0,
    this.sentence = const [],
  });

  RecognitionState copyWith({
    bool? isReady,
    bool? isError,
    String? predictedWord,
    double? confidenceScore,
    List<String>? sentence,
  }) => RecognitionState(
    isReady: isReady ?? this.isReady,
    isError: isError ?? this.isError,
    predictedWord: predictedWord ?? this.predictedWord,
    confidenceScore: confidenceScore ?? this.confidenceScore,
    sentence: sentence ?? this.sentence,
  );
}
