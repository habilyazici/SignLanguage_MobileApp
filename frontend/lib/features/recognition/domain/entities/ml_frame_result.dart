import 'dart:ui' show Offset;

/// ML pipeline'ının tek bir kare için ürettiği ham sonuç.
/// [0..41] sol el · [42..83] sağ el · [84..105] pose (11 nokta × 2)
class MlFrameResult {
  final List<double> features;
  final List<Offset> posePoints;
  final List<Offset> rightHandPoints;
  final List<Offset> leftHandPoints;
  final bool anyDetected;
  final int poseCount;
  final int handCount;

  const MlFrameResult({
    required this.features,
    required this.posePoints,
    required this.rightHandPoints,
    required this.leftHandPoints,
    required this.anyDetected,
    required this.poseCount,
    required this.handCount,
  });
}
