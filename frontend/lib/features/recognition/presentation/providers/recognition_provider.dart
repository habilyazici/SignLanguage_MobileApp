import 'dart:async';
import 'dart:io';
import 'dart:math' show min;
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart'
    as mlkit;
import 'package:hand_detection/hand_detection.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:tflite_flutter/tflite_flutter.dart' as tflite;

import '../../../../../core/providers/camera_lifecycle_provider.dart';
import '../../../../../core/providers/tts_provider.dart';
import '../../../../../core/utils/landmark_normalizer.dart';
import '../../../../../core/utils/label_mapper.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Developer modu için landmark verisi (ValueNotifier ile taşınır)
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
// Durum sınıfı
// ─────────────────────────────────────────────────────────────────────────────

class RecognitionState {
  final bool isReady;
  final bool isError;
  final CameraController? cameraController;
  // Anlık tahmin (smoothing sonrası)
  final String predictedWord;
  final double confidenceScore;
  // Altyazı biriktirme listesi
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
  }) {
    return RecognitionState(
      isReady: isReady ?? this.isReady,
      isError: isError ?? this.isError,
      cameraController: cameraController ?? this.cameraController,
      predictedWord: predictedWord ?? this.predictedWord,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      sentence: sentence ?? this.sentence,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider  (Riverpod 3.x — NotifierProvider)
// ─────────────────────────────────────────────────────────────────────────────

final recognitionProvider =
    NotifierProvider<RecognitionNotifier, RecognitionState>(
      RecognitionNotifier.new,
    );

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class RecognitionNotifier extends Notifier<RecognitionState> {
  // ── Algılayıcılar ──────────────────────────────────────────────────────────
  mlkit.PoseDetector? _poseDetector;
  HandDetector? _handDetector;
  tflite.Interpreter? _interpreter;
  tflite.IsolateInterpreter? _isolateInterpreter;
  CameraController? _camera;
  List<CameraDescription> _allCameras = [];
  CameraLensDirection _currentLens = CameraLensDirection.back;

  // ── Sliding-window tamponu ─────────────────────────────────────────────────
  // [0..41] Sol el · [42..83] Sağ el · [84..105] Pose (11 nokta)
  static const int _windowSize = 60;
  static const int _featureSize = 106;
  static const int _numClasses = 226;
  static const List<int> _poseIndices = [0, 2, 5, 7, 8, 11, 12, 13, 14, 15, 16];

  // ZAMAN TABANLI PENCERE
  // AUTSL eğitim klipleri 1-4 saniye (30fps → 30-120 kare → 60'a resample).
  // Uygulama ~4-6 fps'de çalışır → 60 kare = ~12 sn = eğitimle uyumsuz.
  // Çözüm: son 2.5 saniyeyi al → 60'a resample et.
  // Böylece model her zaman doğru temporal ölçekte hareket görür.
  static const int _windowMs =
      2500; // 2.5 saniyelik kayan pencere — 5fps'de ~12 gerçek kare
  static const int _minWindowMs = 800; // ilk inference için min süre (~0.8 sn)
  static const int _inferEvery = 5; // her 5 işlenen karede inference
  static const int _stride = 1; // her kare işlenir

  // (timestamp_ms, feature_vector) çiftleri
  final List<(int, List<double>)> _timedBuffer = [];
  int _frameCounter = 0;
  bool _isProcessing = false;  // ML tespiti kilidi (pose + el)
  bool _isInferring = false;   // TFLite inference kilidi (isolate'te çalışır)

  // ── Temporal smoothing ────────────────────────────────────────────────────
  // Aynı sınıf 2 ardışık inference → göster.
  // ~5fps'de inference ~1 sn'de bir gelir → 2 = ~2 sn bekleme (kullanılabilir).
  static const int _stableFrames = 2;
  int _lastIdx = -1;
  int _streak = 0;

  // ── Altyazı / cümle biriktirme ────────────────────────────────────────────
  String _lastShownWord = '';
  Timer? _clearTimer;

  // ── Buffer temizleme grace period ─────────────────────────────────────────
  // El bir kare kaybolunca buffer hemen silinmez; 1 sn boyunca hiç tespit
  // yoksa silinir. Bu sayede kısa okluzyonlarda tanıma sıfırlanmaz.
  Timer? _noDetectionTimer;

  // ── Hareket algılama ───────────────────────────────────────────────────────
  // Eller sabitken (dinlenme pozisyonu) model çalıştırılmaz; bu sayede
  // "haklı" gibi boşta el pozisyonunun yanlış tetiklenmesi engellenir.
  //
  // Yöntem: ardışık iki frame'deki el landmark koordinatları (0..83) arasındaki
  // ortalama mutlak fark hesaplanır. Eşiğin altındaysa eller sabit sayılır.
  //
  // [0,1] normalize uzayında ~0.8% ortalama yerinden → hareket var.
  static const double _motionThreshold = 0.008;
  // Son hareketten bu kadar ms sonra inference tamamen durur.
  static const int _motionWindowMs = 1500;

  List<double>? _prevFrame;   // Bir önceki frame'in landmark vektörü
  int _lastMotionMs = 0;      // Son hareket algılanan zaman damgası

  // Cihaz sensör açısı (90, 270 vb.)
  int _sensorOrientation = 90;

  // NV21 dönüşüm buffer'ı — her kare yeni tahsis yerine bir kere oluşturulur,
  // GC baskısını önemli ölçüde azaltır.
  Uint8List? _nv21Buffer;

  // ── Developer modu — per-frame Riverpod rebuild tetiklememek için ─────────
  final devNotifier = ValueNotifier<LandmarkDevData>(
    LandmarkDevData(
      posePoints: [],
      rightHand: [],
      leftHand: [],
      bufferFill: 0,
      poseCount: 0,
      handCount: 0,
    ),
  );

  // ── Riverpod 3.x: build() başlangıç durumunu döndürür ────────────────────

  @override
  RecognitionState build() {
    ref.keepAlive();
    ref.onDispose(_cleanup);

    // Kamera aktif provider'ını dinle — navigasyon katmanından gelen sinyal
    ref.listen<bool>(cameraActiveProvider, (_, isActive) {
      if (isActive) {
        resumeCamera();
      } else {
        pauseCamera();
      }
    });

    _init();
    return const RecognitionState();
  }

  // ── Başlatma ───────────────────────────────────────────────────────────────

  Future<void> _init() async {
    try {
      _poseDetector = mlkit.PoseDetector(
        options: mlkit.PoseDetectorOptions(
          mode: mlkit.PoseDetectionMode.stream,
          model: mlkit.PoseDetectionModel.base,
        ),
      );

      _handDetector = HandDetector();
      await _handDetector!.initialize();

      final opts = tflite.InterpreterOptions()..threads = 4;
      _interpreter = await tflite.Interpreter.fromAsset(
        'assets/models/sign_language_model.tflite',
        options: opts,
      );
      _isolateInterpreter = await tflite.IsolateInterpreter.create(
        address: _interpreter!.address,
      );

      await _startCamera();
    } catch (e) {
      debugPrint('❌ Başlatma hatası: $e');
      state = state.copyWith(isError: true);
    }
  }

  Future<void> _startCamera({CameraLensDirection? lens}) async {
    // Kamera değişince önceki tespit durumunu sıfırla
    _noDetectionTimer?.cancel();
    _noDetectionTimer = null;
    _clearTimer?.cancel();
    _clearTimer = null;
    _lastIdx = -1;
    _streak = 0;
    _lastShownWord = '';

    _allCameras = await availableCameras();
    if (_allCameras.isEmpty) {
      state = state.copyWith(isError: true);
      return;
    }

    final direction = lens ?? _currentLens;
    final selected = _allCameras.firstWhere(
      (c) => c.lensDirection == direction,
      orElse: () => _allCameras.first,
    );
    _currentLens = selected.lensDirection;

    final format = Platform.isIOS
        ? ImageFormatGroup.bgra8888
        : ImageFormatGroup.nv21;

    await _camera?.stopImageStream();
    await _camera?.dispose();

    _camera = CameraController(
      selected,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: format,
    );
    await _camera!.initialize();
    _sensorOrientation = _camera!.description.sensorOrientation;
    _timedBuffer.clear();

    state = state.copyWith(
      isReady: true,
      cameraController: _camera,
      predictedWord: '',
      confidenceScore: 0.0,
    );

    // Stream'i yalnızca kamera ekranı aktifse başlat
    if (ref.read(cameraActiveProvider)) {
      _camera!.startImageStream(_onFrame);
    }
  }

  // ── Kare işleme ────────────────────────────────────────────────────────────

  void _onFrame(CameraImage image) async {
    _frameCounter++;
    if (_frameCounter % _stride != 0) return;
    if (_isProcessing) return;
    if (_poseDetector == null || _handDetector == null) return;
    _isProcessing = true;

    final bool doLog = (_frameCounter % 150 == 0); // ~15 sn'de bir log

    // ── Merkezi kare kırpma bölgesi ────────────────────────────────────────
    final int cropSide = min(image.width, image.height);
    final int cropXOff = (image.width - cropSide) ~/ 2;
    final int cropYOff = (image.height - cropSide) ~/ 2;

    if (doLog) {
      debugPrint(
        '📷 Kare=$_frameCounter '
        'sensör=${image.width}x${image.height} '
        'crop=${cropSide}x$cropSide off=($cropXOff,$cropYOff) '
        'buf=${_timedBuffer.length} (~${_windowMs}ms pencere)',
      );
    }

    bool shouldInfer = false;

    try {
      final frame = List<double>.filled(_featureSize, 0.0);
      bool anyDetected = false;

      // NV21 yalnızca Android'de bir kere inşa edilir; hem ML Kit hem
      // OpenCV/hand_detection aynı bayt dizisini kullanır (önceden 2x build ediliyordu).
      final Uint8List? nv21 = Platform.isAndroid ? _buildNV21(image) : null;

      final inputImage = _buildInputImage(image, nv21);
      final mat = _toMat(image, nv21);

      final poseFuture = (inputImage != null)
          ? _poseDetector!.processImage(inputImage)
          : Future.value(<mlkit.Pose>[]);

      final handFuture = (mat != null)
          ? _handDetector!.detectOnMat(mat).catchError((_) => <Hand>[])
          : Future<List<Hand>>.value([]);

      final results =
          await (Future.wait([poseFuture, handFuture])
              as Future<List<dynamic>>);
      mat?.dispose();

      // 1. Pose sonuçları — indeksler 84..105
      final poses = results[0] as List<mlkit.Pose>;
      final posePoints = (poses.isNotEmpty)
          ? _fillPose(
              poses.first,
              frame,
              cropSide: cropSide,
              cropXOff: cropXOff,
            )
          : <Offset>[];
      if (poses.isNotEmpty) anyDetected = true;

      // 2. El sonuçları — indeksler 0..83
      final hands = results[1] as List<Hand>;
      final handsData = (hands.isNotEmpty)
          ? _fillHands(
              hands,
              frame,
              cropSide: cropSide,
              cropXOff: cropXOff,
              leftHandMode: ref.read(settingsProvider).leftHandMode,
            )
          : (left: <Offset>[], right: <Offset>[]);
      if (hands.isNotEmpty) anyDetected = true;

      devNotifier.value = LandmarkDevData(
        posePoints: posePoints,
        rightHand: handsData.right,
        leftHand: handsData.left,
        bufferFill: _timedBuffer.length,
        poseCount: poses.length,
        handCount: hands.length,
      );

      if (anyDetected) {
        // Tespit geldi → grace period timer'ı iptal et
        _noDetectionTimer?.cancel();
        _noDetectionTimer = null;

        // ── Hareket algılama ──────────────────────────────────────────────
        // El landmark koordinatlarının (0..83) önceki frame'e göre ortalama
        // mutlak değişimi hesaplanır. Eşiğin üzerindeyse hareket var demektir.
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        final motion = _computeMotion(frame);
        _prevFrame = List<double>.from(frame); // bir sonraki frame için sakla

        if (motion >= _motionThreshold) {
          _lastMotionMs = nowMs; // hareket zamanını güncelle
        }

        // Zaman damgalı buffer'a ekle
        _timedBuffer.add((nowMs, frame));

        // _windowMs'den eski kareleri çıkar (kayan pencere)
        _timedBuffer.removeWhere((e) => nowMs - e.$1 > _windowMs);

        // Yeterli veri biriktiğinde inference çalıştır —
        // ANCAK yalnızca son 1.5 sn içinde hareket algılandıysa.
        final timeSinceMotion = nowMs - _lastMotionMs;
        final windowAge = _timedBuffer.length >= 2
            ? nowMs - _timedBuffer.first.$1
            : 0;
        if (timeSinceMotion <= _motionWindowMs &&
            (windowAge >= _minWindowMs || _timedBuffer.length >= 3) &&
            _frameCounter % _inferEvery == 0) {
          shouldInfer = true;
        }
      } else {
        // Tespit yok → hemen silme, 1 saniyelik grace period başlat
        _noDetectionTimer ??= Timer(const Duration(seconds: 1), () {
          _timedBuffer.clear();
          _noDetectionTimer = null;
          state = state.copyWith(predictedWord: '', confidenceScore: 0.0);
        });
      }
    } catch (e, st) {
      debugPrint('❌ Frame hatası: $e\n$st');
    } finally {
      // ML kilidi burada bırakılır — bir sonraki kare artık beklemez.
      // TFLite inference bağımsız olarak arka planda devam eder.
      _isProcessing = false;
    }

    if (shouldInfer) _runInference();
  }

  // ── Hareket skoru hesaplama ────────────────────────────────────────────────
  // El landmark koordinatları (indeks 0..83): sağ el [0..41] + sol el [42..83].
  // Pose koordinatları (84..105) kasıtlı hariç tutulur — vücut çok az hareket
  // ettiğinden işaret hareketi için anlamlı sinyal vermez.
  double _computeMotion(List<double> current) {
    if (_prevFrame == null) return double.infinity; // ilk kare → her zaman hareket var
    double sum = 0.0;
    for (int i = 0; i < 84; i++) {
      sum += (current[i] - _prevFrame![i]).abs();
    }
    return sum / 84.0; // ortalama mutlak yerinden oynama (0..1 normalize uzayında)
  }

  // ── Landmark doldurma ──────────────────────────────────────────────────────

  // Ön kamera (selfie) kullanırken ham CameraImage X ekseni mirror'lıdır.
  // Model AUTSL verisiyle (kamera karşısındaki kişi, mirror'sız) eğitildiği için
  // ön kamerada X koordinatları 1.0 - nx şeklinde çevrilmelidir.
  double _maybeFlipX(double nx) =>
      _currentLens == CameraLensDirection.front ? 1.0 - nx : nx;

  // ── Sensör → model koordinat dönüşümü ────────────────────────────────────
  //
  // Kamera sensörü landscape görüntü üretir (örn. 640x480).
  // Model AUTSL portré 512×512 videolarıyla eğitildi; koordinatlar portré uzayında.
  // Dinamik olarak sensorOrientation değerine göre dönüşüm yapılır.

  double _sensorXToModelX(
    double sx,
    double sy,
    int sw,
    int sh,
    int cropSide,
    int cropXOff,
    int cropYOff,
  ) {
    // Portre modunda sw < sh, ancak CameraImage sw > sh (landscape) gelir.
    switch (_sensorOrientation) {
      case 90:
        // Saat yönünde 90: x' = h - y, y' = x
        return (1.0 - sy / cropSide).clamp(0.0, 1.0);
      case 270:
        // Saat yönünde 270: x' = y, y' = w - x
        return (sy / cropSide).clamp(0.0, 1.0);
      case 0:
        return ((sx - cropXOff) / cropSide).clamp(0.0, 1.0);
      default:
        return (1.0 - sy / cropSide).clamp(0.0, 1.0);
    }
  }

  double _sensorYToModelY(
    double sx,
    double sy,
    int sw,
    int sh,
    int cropSide,
    int cropXOff,
    int cropYOff,
  ) {
    switch (_sensorOrientation) {
      case 90:
        return ((sx - cropXOff) / cropSide).clamp(0.0, 1.0);
      case 270:
        return (1.0 - (sx - cropXOff) / cropSide).clamp(0.0, 1.0);
      case 0:
        return ((sy - cropYOff) / cropSide).clamp(0.0, 1.0);
      default:
        return ((sx - cropXOff) / cropSide).clamp(0.0, 1.0);
    }
  }

  List<Offset> _fillPose(
    mlkit.Pose pose,
    List<double> frame, {
    required int cropSide,
    required int cropXOff,
  }) {
    final displayPoints = <Offset>[];

    for (int i = 0; i < _poseIndices.length; i++) {
      final lm = pose.landmarks[mlkit.PoseLandmarkType.values[_poseIndices[i]]];
      if (lm == null) continue;

      // 1. MODEL KOORDİNATLARI (Crop-Relative [0,1])
      // 240x320 portrait space'de crop orta kısımdır.
      double mx_model = (lm.x / cropSide).clamp(0.0, 1.0);
      double my_model = ((lm.y - cropXOff) / cropSide).clamp(0.0, 1.0);

      // 2. GÖRSEL KOORDİNATLAR (Preview-Relative [0,1])
      // Painter tüm preview alanına [0..240, 0..320] çizim yapacağı için bu oranda normalize edilir.
      double mx_display = lm.x / 240.0;
      double my_display = lm.y / 320.0;

      // Selfie ayna kontrolü (MODEL için)
      mx_model = _maybeFlipX(mx_model);

      frame[84 + i * 2] = mx_model;
      frame[84 + i * 2 + 1] = my_model;
      displayPoints.add(Offset(mx_display, my_display));
    }
    return displayPoints;
  }

  ({List<Offset> right, List<Offset> left}) _fillHands(
    List<dynamic> hands,
    List<double> frame, {
    required int cropSide,
    required int cropXOff,
    required bool leftHandMode,
  }) {
    final displayRight = <Offset>[];
    final displayLeft = <Offset>[];

    // Arka kamerada sw=320, sh=240. Portrait (90) modunda sensorW=240, sensorH=320.
    const double sw = 320.0;
    const double sh = 240.0;

    for (final hand in hands) {
      // Slot 0: Right (Dökümantasyona göre)
      bool isAnatomicalRight = (hand.handedness == Handedness.right);
      // Sol el modunda slotları ters çevir — sol baskın kullanıcılar için
      final bool useRightSlot = leftHandMode ? !isAnatomicalRight : isAnatomicalRight;

      final offset = useRightSlot ? 0 : 42;
      final displayTarget = useRightSlot ? displayRight : displayLeft;

      final landmarksRaw = hand.landmarks;
      if (landmarksRaw == null) continue;
      final landmarks = landmarksRaw as List;

      for (int i = 0; i < landmarks.length && i < 21; i++) {
        final lm = landmarks[i];
        double sx = (lm.x as num).toDouble();
        double sy = (lm.y as num).toDouble();

        if (sx <= 1.05 && sy <= 1.05) {
          sx *= sw;
          sy *= sh;
        }

        // 1. MODEL KOORDİNATLARI (Crop-Relative [0,1])
        double mx_model = _sensorXToModelX(
          sx,
          sy,
          320,
          240,
          cropSide,
          cropXOff,
          0,
        );
        double my_model = _sensorYToModelY(
          sx,
          sy,
          320,
          240,
          cropSide,
          cropXOff,
          0,
        );
        mx_model = _maybeFlipX(mx_model);

        // 2. GÖRSEL KOORDİNATLAR (Preview-Relative [0,1])
        // Portrait moda (240x320) uygun doğrudan dönüşüm
        double mx_display = (240.0 - sy) / 240.0;
        double my_display = sx / 320.0;

        frame[offset + i * 2] = mx_model;
        frame[offset + i * 2 + 1] = my_model;
        displayTarget.add(
          Offset(mx_display.clamp(0.0, 1.0), my_display.clamp(0.0, 1.0)),
        );
      }
    }
    return (right: displayRight, left: displayLeft);
  }

  // ── Buffer resampling ──────────────────────────────────────────────────────
  // Eğitim (feature_extraction.py / process_video) ile birebir aynı mantık:
  //
  //   N < 60  → son kare padding   (kısa videolarda last_frame tekrarlandı)
  //   N = 60  → olduğu gibi        (değişiklik yok)
  //   N > 60  → np.linspace ile    (uzun videolarda uniform downsample)
  //
  // Zaman tabanlı pencereyle (2.5 sn, ~5fps → ~12 kare):
  //   12 gerçek kare + 48 son kare padding → model son poz statik görür
  //   Bu eğitimle uyumlu: kısa kliplerde de aynı şekilde padding yapıldı.
  List<List<double>> _resampleBuffer(List<List<double>> buffer) {
    if (buffer.isEmpty) {
      return List.generate(
        _windowSize,
        (_) => List<double>.filled(_featureSize, 0.0),
      );
    }
    if (buffer.length == _windowSize) return buffer;

    if (buffer.length < _windowSize) {
      // Kısa → son kare padding (eğitimle aynı)
      final result = List<List<double>>.from(buffer);
      final lastFrame = buffer.last;
      while (result.length < _windowSize) {
        result.add(lastFrame);
      }
      return result;
    } else {
      // Uzun → uniform downsample (eğitimde np.linspace(0, N-1, 60, dtype=int))
      return List.generate(_windowSize, (i) {
        final src = (i * (buffer.length - 1) / (_windowSize - 1)).round().clamp(
          0,
          buffer.length - 1,
        );
        return buffer[src];
      });
    }
  }

  // ── TFLite çıkarımı ────────────────────────────────────────────────────────

  Future<void> _runInference() async {
    if (_isolateInterpreter == null || _timedBuffer.isEmpty) return;
    if (_isInferring) return;

    // KARARLILIK GUARD'I: ~5fps'de 2.5 saniyelik pencere = ~12 gerçek kare.
    // 8 kare yeterli — resampling ile 60'a tamamlanır (eğitimle aynı padding mantığı).
    if (_timedBuffer.length < 8) {
      if (_frameCounter % 50 == 0) {
        debugPrint(
          '⏳ Tampon henüz boş (${_timedBuffer.length}/60), çıkarım atlanıyor.',
        );
      }
      return;
    }

    _isInferring = true;
    try {
      // Buffer snapshot'ı al — inference arka plandayken ana thread buffer'a yazmaya devam edebilir.
      final frames = _timedBuffer.map((e) => e.$2).toList();
      final window = _resampleBuffer(frames);
      final normalized = LandmarkNormalizer.normalizeWindow(window);

      final input = [
        List.generate(_windowSize, (j) => List<double>.from(normalized[j])),
      ];
      final output = List<double>.filled(
        _numClasses,
        0.0,
      ).reshape([1, _numClasses]);

      // TFLite inference arka plan isolate'inde çalışır — ana thread bloklanmaz.
      await _isolateInterpreter!.run(input, output);

      final scores = List<double>.from(output[0] as List);
      var maxScore = 0.0;
      var maxIdx = -1;

      for (int i = 0; i < scores.length; i++) {
        if (scores[i] > maxScore) {
          maxScore = scores[i];
          maxIdx = i;
        }
      }

      final topWord = maxIdx >= 0 ? LabelMapper.getTrWord(maxIdx) : '?';
      debugPrint(
        '🧠 Inference → idx:$maxIdx  skor:${(maxScore * 100).toStringAsFixed(1)}%  kelime:$topWord',
      );

      // ── Threshold settings'ten okunur (Düşük=%70 / Orta=%80 / Yüksek=%90) ──
      final currentSettings = ref.read(settingsProvider);
      final smoothingOn = currentSettings.temporalSmoothingEnabled;
      final scoreThreshold = currentSettings.confidenceThreshold;

      if (maxIdx >= 0 && maxScore >= scoreThreshold) {
        if (maxIdx == _lastIdx) {
          _streak++;
        } else {
          // Yeni sınıf → streak'i sıfırla AMA sadece belirgin fark varsa
          // (önceki sınıftan çok düşük skorla ayrılıyorsa geçiş sayılmaz)
          _lastIdx = maxIdx;
          _streak = 1;
        }

        // Smoothing kapalıysa ilk inference'da anında göster (streak=1 yeterli)
        final threshold = smoothingOn ? _stableFrames : 1;
        if (_streak >= threshold) {
          final word = LabelMapper.getTrWord(maxIdx);

          if (word != _lastShownWord) {
            _lastShownWord = word;
            final updated = [...state.sentence, word];
            final trimmed = updated.length > 6
                ? updated.sublist(updated.length - 6)
                : updated;

            state = state.copyWith(
              predictedWord: word,
              confidenceScore: maxScore,
              sentence: trimmed,
            );

            // TTS: ttsEnabled ise yeni kelimeyi seslendir
            if (ref.read(settingsProvider).ttsEnabled) {
              ref.read(ttsProvider.notifier).speak(word);
            }

            // Haptic: ≥90% güven → orta titreşim (spec)
            if (maxScore >= 0.90) {
              HapticFeedback.mediumImpact();
            }

            _clearTimer?.cancel();
            _clearTimer = Timer(const Duration(seconds: 4), () {
              state = state.copyWith(
                predictedWord: '',
                confidenceScore: 0.0,
                sentence: [],
              );
              // _lastShownWord BURADA sıfırlanmıyor — sıfırlama sadece skor
              // eşiğin altına düşünce yapılır (aşağıdaki else bloğu).
              // Bu sayede aynı işaret sürekli tutulurken TTS tekrar tetiklenmez;
              // ancak el indirilip tekrar kaldırılınca (yeni bir imza başlarken)
              // yeniden tetiklenebilir.
            });
          } else {
            state = state.copyWith(confidenceScore: maxScore);
          }
        }
      } else {
        // Skor düşük — eller boşta ya da farklı bir işaret başlıyor.
        // Streak ve son sınıfı sıfırla; artık aynı kelime tekrar tetiklenebilir.
        _streak = 0;
        _lastIdx = -1;
        _lastShownWord = '';
      }
    } catch (e, st) {
      debugPrint('❌ Çıkarım hatası: $e\n$st');
    } finally {
      _isInferring = false;
    }
  }

  // ── Yardımcılar ────────────────────────────────────────────────────────────

  mlkit.InputImage? _buildInputImage(CameraImage image, Uint8List? nv21) {
    try {
      final rotation =
          mlkit.InputImageRotationValue.fromRawValue(
            _camera!.description.sensorOrientation,
          ) ??
          mlkit.InputImageRotation.rotation90deg;

      if (Platform.isIOS) {
        return mlkit.InputImage.fromBytes(
          bytes: image.planes[0].bytes,
          metadata: mlkit.InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: rotation,
            format: mlkit.InputImageFormat.bgra8888,
            bytesPerRow: image.planes[0].bytesPerRow,
          ),
        );
      } else {
        final bytes = nv21 ?? _buildNV21(image);
        return mlkit.InputImage.fromBytes(
          bytes: bytes,
          metadata: mlkit.InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: rotation,
            format: mlkit.InputImageFormat.nv21,
            bytesPerRow: image.width,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ _buildInputImage hatası: $e');
      return null;
    }
  }

  Uint8List _buildNV21(CameraImage image) {
    final int w = image.width;
    final int h = image.height;
    final int size = w * h * 3 ~/ 2;

    // Buffer yoksa veya boyut değiştiyse (kamera geçişi) yeniden tahsis et.
    // Aynı boyut için mevcut buffer yeniden kullanılır → GC baskısı azalır.
    if (_nv21Buffer == null || _nv21Buffer!.length != size) {
      _nv21Buffer = Uint8List(size);
    }

    if (image.planes.length == 1) {
      final int stride = image.planes[0].bytesPerRow;
      if (stride == w) return image.planes[0].bytes;
      final out = _nv21Buffer!;
      final src = image.planes[0].bytes; // Y plane - Hızlı kopyalama
      for (int r = 0; r < h; r++) {
        out.setRange(r * w, (r + 1) * w, src, r * stride);
      }

      // UV planes (NV21: V U V U...)
      // Not: Bu kısım FPS'i en çok düşüren yerdir. Sadece gerekli ise yapılmalı.
      // Drone/Daha hızlı cihazlarda sorun olmaz.
      final uPlane = image.planes[1];
      final vPlane = image.planes[2];
      final uvOffset = w * h;
      final uBytes = uPlane.bytes;
      final vBytes = vPlane.bytes;

      // Çoğu Android cihazda UV planları son iki plandadır ve stride=2'dir.
      // Flutter camera paketinde Plane sınıfında pixelStride yoktur.
      // Genelde [1] U, [2] V'dir ama bazen çaprazlanmış olabilirler.
      int outIdx = uvOffset;
      final int uvH = h ~/ 2;
      final int uvW = w ~/ 2;
      final int uRowStride = uPlane.bytesPerRow;

      for (int r = 0; r < uvH; r++) {
        for (int c = 0; c < uvW; c++) {
          // pixelStride=2 varsayımı (YUV_420_888 standartı)
          final int idx = r * uRowStride + c * 2;
          if (idx < vBytes.length) out[outIdx++] = vBytes[idx];
          if (idx < uBytes.length) out[outIdx++] = uBytes[idx];
        }
      }
      return out;
    }

    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final out = _nv21Buffer!;
    for (int r = 0; r < h; r++) {
      out.setRange(r * w, (r + 1) * w, yPlane.bytes, r * yPlane.bytesPerRow);
    }
    int uvOffset = w * h;
    final int uvRows = h ~/ 2;
    final int uvCols = w ~/ 2;
    for (int r = 0; r < uvRows; r++) {
      for (int c = 0; c < uvCols; c++) {
        final srcU = r * uPlane.bytesPerRow + c * (uPlane.bytesPerPixel ?? 1);
        final srcV = r * vPlane.bytesPerRow + c * (vPlane.bytesPerPixel ?? 1);
        out[uvOffset++] = vPlane.bytes[srcV];
        out[uvOffset++] = uPlane.bytes[srcU];
      }
    }
    return out;
  }

  cv.Mat? _toMat(CameraImage image, Uint8List? nv21) {
    try {
      if (Platform.isIOS) {
        final bgra = cv.Mat.fromList(
          image.height,
          image.width,
          cv.MatType.CV_8UC4,
          image.planes[0].bytes,
        );
        final bgr = cv.cvtColor(bgra, cv.COLOR_BGRA2BGR);
        bgra.dispose();
        return bgr;
      } else {
        final bytes = nv21 ?? _buildNV21(image);
        final yuv = cv.Mat.fromList(
          image.height + image.height ~/ 2,
          image.width,
          cv.MatType.CV_8UC1,
          bytes,
        );
        final bgr = cv.cvtColor(yuv, cv.COLOR_YUV2BGR_NV21);
        yuv.dispose();
        return bgr;
      }
    } catch (_) {
      return null;
    }
  }

  // ── Temizlik ───────────────────────────────────────────────────────────────

  void _cleanup() {
    try {
      _clearTimer?.cancel();
    } catch (_) {}
    try {
      _noDetectionTimer?.cancel();
    } catch (_) {}
    try {
      _poseDetector?.close();
    } catch (_) {}
    try {
      _handDetector?.dispose();
    } catch (_) {}
    try {
      _isolateInterpreter?.close();
    } catch (_) {}
    try {
      _interpreter?.close();
    } catch (_) {}
    try {
      _camera?.stopImageStream();
    } catch (_) {}
    try {
      _camera?.dispose();
    } catch (_) {}
    try {
      devNotifier.dispose();
    } catch (_) {}
  }

  // ── Kamera kontrolü ───────────────────────────────────────────────────────

  void pauseCamera() {
    try {
      _camera?.stopImageStream();
    } catch (_) {}
  }

  void resumeCamera() {
    try {
      if (_camera != null &&
          _camera!.value.isInitialized &&
          !_camera!.value.isStreamingImages) {
        _camera!.startImageStream(_onFrame);
      }
    } catch (_) {}
  }

  /// Çift tıkla ön/arka kamera geçişi
  Future<void> switchCamera() async {
    final next = _currentLens == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    await _startCamera(lens: next);
  }
}
