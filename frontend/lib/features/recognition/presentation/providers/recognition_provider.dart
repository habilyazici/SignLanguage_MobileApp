import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/data_sources/tflite_service.dart';
import '../../../../core/utils/label_mapper.dart';

// State (Durum) Sınıfı: Arayüze Güvenlik Skoru, Kamera Durumu ve Bulunan Kelimeyi anlık taşıyacak
class RecognitionState {
  final bool isReady;
  final CameraController? cameraController;
  final String predictedWord;
  final double confidenceScore; // 0.0 ile 1.0 arası yüzdelik
  final bool isError;

  RecognitionState({
    this.isReady = false,
    this.cameraController,
    this.predictedWord = 'Bekleniyor...',
    this.confidenceScore = 0.0,
    this.isError = false,
  });

  RecognitionState copyWith({
    bool? isReady,
    CameraController? cameraController,
    String? predictedWord,
    double? confidenceScore,
    bool? isError,
  }) {
    return RecognitionState(
      isReady: isReady ?? this.isReady,
      cameraController: cameraController ?? this.cameraController,
      predictedWord: predictedWord ?? this.predictedWord,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      isError: isError ?? this.isError,
    );
  }
}

// Riverpod Provider (NotifierProvider yerine AutoDispose kullanıyoruz ki sayfadan çıkınca kamera kapansın!)
final recognitionProvider =
    AutoDisposeNotifierProvider<RecognitionNotifier, RecognitionState>(
      RecognitionNotifier.new,
    );

class RecognitionNotifier extends AutoDisposeNotifier<RecognitionState> {
  final TFLiteService _tfLiteService = TFLiteService();
  int _frameCount = 0;
  bool _isProcessing = false;

  // 3. Sliding Window (Zaman Çizelgesi) Mekanizması: Sınır 60 kare
  final List<List<double>> _pointsBuffer = [];

  @override
  RecognitionState build() {
    ref.onDispose(() {
      state.cameraController?.stopImageStream();
      state.cameraController?.dispose();
      _tfLiteService.close();
    });
    Future.microtask(_initSystem);
    return RecognitionState();
  }

  Future<void> _initSystem() async {
    try {
      // 0. Uygulamanın en başında kamera izni iste (Çökmeyi / Siyah Ekranı Engeller)
      final status = await Permission.camera.request();
      if (!status.isGranted)
        throw Exception('Kullanıcı kamera iznini reddetti.');

      // 1. TFLite Modelini ilk saniyede güvenlice Yükle
      await _tfLiteService.initModel();

      // 2. Cihazdaki kameraları bul
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw Exception('Kamera bulunamadı!');

      // Zero-Knowledge KVKK Uyumu: İşaret dili için ön kamerayı alıyoruz
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false, // Ses dinleme iptal. Asla ses kaydedilmez!
      );

      await controller.initialize();

      // Arayüze (UI) kameranın hazır olduğunu iletiyoruz
      state = state.copyWith(isReady: true, cameraController: controller);

      // 3. Frame (Kare / Video Akışı) dinleme mekanizmasını başlat
      controller.startImageStream((CameraImage image) {
        _processFrame(image);
      });
    } catch (e) {
      print('Kamera / AI Başlatma hatası: $e');
      state = state.copyWith(isError: true);
    }
  }

  Future<void> _processFrame(CameraImage image) async {
    // İşlem devam ediyorsa veya cihaz (Thermal Throttling) sıkışıyorsa bu frame'i bilerek atla
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      _frameCount++;

      // TODO (MediaPipe Mimarisi): Burada Google MLKit / MediaPipe çalıştırılarak
      // CameraImage üzerinden x,y değerleri çekilecek ve o normalizasyon matrisi kurulacak.
      // Şimdilik TFLite testi amaçlı, rastgele (fake) koordiant matrisi yerleştiriyoruz.
      List<double> frameLandmarks = List.generate(
        106,
        (_) => Random().nextDouble(),
      );
      _pointsBuffer.add(frameLandmarks);

      // FIFO (İlk giren ilk çıkar) Prensibi: Bellekte daima sadece en sonki 60 kare (2 Saniye) kalır.
      if (_pointsBuffer.length > 60) {
        _pointsBuffer.removeAt(0); // En eskisini sil
      }

      // Stride Mantığı: Her 5 frame'de bir modelden tahmin çıkarım (Inference) yap
      if (_pointsBuffer.length == 60 && _frameCount % 5 == 0) {
        // TFLite içerisine [1 Batch, 60 Kare, 106 Koordinat] paketini sokuyoruz
        final inputSequence = [_pointsBuffer.toList()];

        final resultProbabilities = _tfLiteService.predict(inputSequence);

        if (resultProbabilities != null) {
          // En yüksek ihtimalli olan sınıfı (argmax) bul
          double maxScore = 0.0;
          int maxIndex = -1;
          for (int i = 0; i < resultProbabilities.length; i++) {
            if (resultProbabilities[i] > maxScore) {
              maxScore = resultProbabilities[i];
              maxIndex = i;
            }
          }

          // Confidence Threshold Kuralı (>= %70 Kırmızı/Sarı/Yeşil eşiği)
          if (maxIndex != -1 && maxScore >= 0.70) {
            // TFLite etiket idsini (LabelMapper) üzerinden asıl kelimeye çeviriyoruz
            String rawWord = LabelMapper.getTrWord(maxIndex);

            // Haptic Feedback / Titreşim kodu bu kısımdan tetiklenebilir

            // State'i GÜNCELLE: Ekrandaki o cam/glass panelde saniyesinde değişecek kısım!
            state = state.copyWith(
              predictedWord: rawWord,
              confidenceScore: maxScore,
            );
          }
        }
      }
    } finally {
      // Bir sonraki çerçevenin akışına kapıyı yeniden açıyoruz
      _isProcessing = false;
    }
  }
}
