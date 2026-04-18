import 'dart:ui' show Offset;
import 'package:camera/camera.dart';

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

  LandmarkDevData({
    required this.posePoints,
    required this.rightHand,
    required this.leftHand,
    required this.bufferFill,
    required this.poseCount,
    required this.handCount,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Recognition durum entity'si
// ─────────────────────────────────────────────────────────────────────────────

class RecognitionState {
  final bool isReady;
  final bool isError;
  final CameraController? cameraController;
  final String predictedWord;
  final double confidenceScore;
  final List<String> sentence;

  const RecognitionState({
    this.isReady = false,
    this.isError = false,
    this.cameraController,
    this.predictedWord = '',
    this.confidenceScore = 0.0,
    this.sentence = const [],
  });

  RecognitionState copyWith({
    bool? isReady,
    bool? isError,
    CameraController? cameraController,
    String? predictedWord,
    double? confidenceScore,
    List<String>? sentence,
  }) => RecognitionState(
    isReady: isReady ?? this.isReady,
    isError: isError ?? this.isError,
    cameraController: cameraController ?? this.cameraController,
    predictedWord: predictedWord ?? this.predictedWord,
    confidenceScore: confidenceScore ?? this.confidenceScore,
    sentence: sentence ?? this.sentence,
  );
}
