import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tflite;

import '../../../../../core/constants/recognition_constants.dart';
import '../../../../../core/utils/landmark_normalizer.dart';
import '../../domain/entities/inference_result.dart';

/// TFLite model yükleme ve inference datasource'u.
/// Buffer resampling + normalizasyon burada yapılır.
class InferenceDatasource {
  tflite.Interpreter? _interpreter;
  tflite.IsolateInterpreter? _isolateInterpreter;

  Future<void> initialize() async {
    final opts = tflite.InterpreterOptions()..threads = 4;
    _interpreter = await tflite.Interpreter.fromAsset(
      'assets/models/sign_language_model.tflite',
      options: opts,
    );
    _isolateInterpreter = await tflite.IsolateInterpreter.create(
      address: _interpreter!.address,
    );
    debugPrint('✅ TFLite modeli yüklendi');
  }

  /// [frames]: zaman damgasız ham feature vektörleri listesi.
  /// Returns null if interpreter not ready or scores all zero.
  Future<InferenceResult?> run(List<List<double>> frames) async {
    if (_isolateInterpreter == null) return null;

    final window = _resampleBuffer(frames);
    final normalized = LandmarkNormalizer.normalizeWindow(window);

    final input = [
      List.generate(
        RecognitionConstants.windowSize,
        (j) => List<double>.from(normalized[j]),
      ),
    ];
    final output = List<double>.filled(RecognitionConstants.numClasses, 0.0)
        .reshape([1, RecognitionConstants.numClasses]);

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

    if (maxIdx < 0) return null;
    return InferenceResult(classIndex: maxIdx, confidence: maxScore);
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
      while (result.length < RecognitionConstants.windowSize) {
        result.add(lastFrame);
      }
      return result;
    } else {
      return List.generate(RecognitionConstants.windowSize, (i) {
        final src = (i * (buffer.length - 1) / (RecognitionConstants.windowSize - 1))
            .round()
            .clamp(0, buffer.length - 1);
        return buffer[src];
      });
    }
  }

  void dispose() {
    try { _isolateInterpreter?.close(); } catch (_) {}
    try { _interpreter?.close(); } catch (_) {}
  }
}
