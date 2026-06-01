import 'package:camera/camera.dart';
import '../entities/inference_result.dart';
import '../entities/recognition_state.dart';

abstract interface class RecognitionRepository {
  Stream<CameraController?> get cameraControllerStream;
  Stream<InferenceResult> get inferenceStream;

  /// Developer modu için per-frame landmark verisi.
  Stream<LandmarkDevData> get landmarkStream;

  Future<void> initialize();
  Future<void> pauseCamera();
  Future<void> resumeCamera();
  Future<void> switchCamera();

  void updateLeftHandMode(bool leftHand);
  void updateFpsLimit(int targetFps);
  void updateMotionThreshold(double threshold);

  Future<void> dispose();
}
