import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tflite;

import '../../../../../core/constants/recognition_constants.dart';
import '../../../../../core/utils/landmark_normalizer.dart';
import '../../domain/entities/inference_result.dart';

/// TFLite model yükleme ve inference datasource'u.
/// Buffer resampling + normalizasyon burada yapılır.
///
/// Sınıf sayısı modelin çıkış tensor shape'inden okunur — hardcode değil.
/// Yeni kelimeler eklenip model güncellendiğinde bu sınıf otomatik uyum sağlar.
class InferenceDatasource {
  tflite.Interpreter? _interpreter;
  tflite.IsolateInterpreter? _isolateInterpreter;

  /// Modelin çıkış tensor'undan okunan gerçek sınıf sayısı.
  int _numClasses = 0;

  /// Yüklü modelin tanıdığı sınıf sayısı (labels.csv ile eşleşmeli).
  int get numClasses => _numClasses;

  Future<void> initialize() async {
    final opts = tflite.InterpreterOptions()..threads = 4;

    _interpreter = await tflite.Interpreter.fromAsset(
      'assets/models/sign_language_model_v2.tflite',
      options: opts,
    );

    // Sınıf sayısını modelden oku — [1, N] → N
    final outputShape = _interpreter!.getOutputTensor(0).shape;
    _numClasses = outputShape.length >= 2 ? outputShape[1] : outputShape[0];

    _isolateInterpreter = await tflite.IsolateInterpreter.create(
      address: _interpreter!.address,
    );
    if (kDebugMode) {
      debugPrint('✅ TFLite modeli yüklendi — $_numClasses sınıf');
    }
  }

  /// [frames]: zaman damgasız ham feature vektörleri listesi.
  /// Returns null if interpreter not ready or scores all zero.
  Future<InferenceResult?> run(List<List<double>> frames) async {
    if (_isolateInterpreter == null || _numClasses == 0) return null;

    final window = _resampleBuffer(frames);
    final normalized = LandmarkNormalizer.normalizeWindow(window);

    final input = [
      List.generate(
        RecognitionConstants.windowSize,
        (j) => List<double>.from(normalized[j]),
      ),
    ];
    final output = List<double>.filled(
      _numClasses,
      0.0,
    ).reshape([1, _numClasses]);

    await _isolateInterpreter!.run(input, output);

    final rawOutput = output[0];
    if (rawOutput is! List) return null;
    final scores = List<double>.from(rawOutput);
    var maxScore = 0.0;
    var maxIdx = -1;
    for (int i = 0; i < scores.length; i++) {
      if (scores[i] > maxScore) {
        maxScore = scores[i];
        maxIdx = i;
      }
    }

    if (maxIdx < 0) return null;

    // Top-3 tahmin (dev modu görselleştirme için)
    final indexed = List.generate(scores.length, (i) => (i, scores[i]));
    indexed.sort((a, b) => b.$2.compareTo(a.$2));
    final top3 = indexed
        .take(3)
        .map((e) => (classIndex: e.$1, confidence: e.$2))
        .toList();

    return InferenceResult(
      classIndex: maxIdx,
      confidence: maxScore,
      topPredictions: top3,
    );
  }

  // ── Buffer resampling ──────────────────────────────────────────────────────
  // Eğitim (feature_extraction.py) ile birebir:
  //   N < 60 → son kare padding (kısa kliplerde last_frame tekrarlandı)
  //   N = 60 → değişiklik yok
  //   N > 60 → np.linspace ile uniform downsample
  List<List<double>> _resampleBuffer(List<List<double>> buffer) {
    if (buffer.isEmpty) {
      return List.generate(
        RecognitionConstants.windowSize,
        (_) => List<double>.filled(RecognitionConstants.featureSize, 0.0),
      );
    }
    if (buffer.length == RecognitionConstants.windowSize) return buffer;

    if (buffer.length < RecognitionConstants.windowSize) {
      final result = List<List<double>>.from(buffer);
      final lastFrame = buffer.last;
      // Aynı lastFrame referansı birden fazla ekleniyor.
      // LandmarkNormalizer.normalizeWindow her frame için kopya ürettiğinden güvenli.
      while (result.length < RecognitionConstants.windowSize) {
        result.add(lastFrame);
      }
      return result;
    } else {
      return List.generate(RecognitionConstants.windowSize, (i) {
        final src =
            (i * (buffer.length - 1) / (RecognitionConstants.windowSize - 1))
                .floor() // Python dtype=int truncates (floor), .round() değil
                .clamp(0, buffer.length - 1);
        return buffer[src];
      });
    }
  }

  void dispose() {
    try {
      _isolateInterpreter?.close();
    } catch (_) {}
    try {
      _interpreter?.close();
    } catch (_) {}
  }
}
