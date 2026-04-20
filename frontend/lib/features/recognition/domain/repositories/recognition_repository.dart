import 'package:camera/camera.dart';
import '../entities/inference_result.dart';
import '../entities/recognition_state.dart';

/// Recognition pipeline için domain repository arayüzü.
abstract interface class RecognitionRepository {
  /// Kamera controller'ı değiştiğinde (ilk açılış veya kamera geçişi) yayar.
  Stream<CameraController?> get cameraControllerStream;

  /// Ham inference sonuçlarını yayar; [InferenceResult.empty] → tespit yok.
  Stream<InferenceResult> get inferenceStream;

  /// Developer modu için per-frame landmark verisi.
  Stream<LandmarkDevData> get landmarkStream;

  Future<void> initialize();
  Future<void> pauseCamera();
  Future<void> resumeCamera();
  Future<void> switchCamera();

  /// Ayarlar değiştiğinde çağrılır — sol el modu frame işlemede kullanılır.
  void updateLeftHandMode(bool leftHand);

  /// FPS limitini günceller (ör. 15 veya 30).
  void updateFpsLimit(int targetFps);

  /// Hareket algılama eşiğini günceller (0.005–0.050).
  void updateMotionThreshold(double threshold);

  Future<void> dispose();
}
