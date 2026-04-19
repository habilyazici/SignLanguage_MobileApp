import 'dart:io';
import 'dart:math' show min;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Offset, Size;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart'
    as mlkit;
import 'package:hand_detection/hand_detection.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

import '../../domain/entities/ml_frame_result.dart';

/// Pose tespiti, el tespiti ve koordinat dönüşümlerini kapsayan datasource.
/// Her [process] çağrısı bir kare için [MlFrameResult] döndürür.
class MlPipelineDatasource {
  mlkit.PoseDetector? _poseDetector;
  HandDetector? _handDetector;
  Uint8List? _nv21Buffer;

  static const List<int> _poseIndices = [0, 2, 5, 7, 8, 11, 12, 13, 14, 15, 16];

  // ── Başlatma ────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    _poseDetector = mlkit.PoseDetector(
      options: mlkit.PoseDetectorOptions(
        mode: mlkit.PoseDetectionMode.stream,
        model: mlkit.PoseDetectionModel.base,
      ),
    );
    _handDetector = HandDetector();
    await _handDetector!.initialize();
  }

  bool get isReady => _poseDetector != null && _handDetector != null;

  // ── Ana işlem ────────────────────────────────────────────────────────────────

  Future<MlFrameResult> process(
    CameraImage image, {
    required int sensorOrientation,
    required bool isFlipped,
    required bool leftHandMode,
  }) async {
    final frame = List<double>.filled(106, 0.0); // featureSize = 106

    final int cropSide = min(image.width, image.height);
    final int cropXOff = (image.width - cropSide) ~/ 2;

    final Uint8List? nv21 = Platform.isAndroid ? _buildNV21(image) : null;
    final inputImage = _buildInputImage(image, nv21, sensorOrientation);
    final mat = _toMat(image, nv21);

    final poseFuture = (inputImage != null)
        ? _poseDetector!.processImage(inputImage)
        : Future.value(<mlkit.Pose>[]);
    final handFuture = (mat != null)
        ? _handDetector!.detectOnMat(mat).catchError((_) => <Hand>[])
        : Future<List<Hand>>.value([]);

    final results =
        await (Future.wait([poseFuture, handFuture]) as Future<List<dynamic>>);
    mat?.dispose();

    // ML Kit koordinatları rotation metadata'ya göre zaten portrait uzayında;
    // crop offset'leri portrait boyutlarından hesaplanmalı.
    final bool isRotated90or270 =
        sensorOrientation == 90 || sensorOrientation == 270;
    final int poseW = isRotated90or270 ? image.height : image.width;
    final int poseH = isRotated90or270 ? image.width : image.height;
    final int poseCropSide = min(poseW, poseH);
    final int poseCropXOff = (poseW - poseCropSide) ~/ 2;
    final int poseCropYOff = (poseH - poseCropSide) ~/ 2;

    final poses = results[0] as List<mlkit.Pose>;
    final posePoints = poses.isNotEmpty
        ? _fillPose(
            poses.first,
            frame,
            cropSide: poseCropSide,
            cropXOff: poseCropXOff,
            cropYOff: poseCropYOff,
            isFlipped: isFlipped,
          )
        : <Offset>[];

    final hands = results[1] as List<Hand>;
    final handsData = hands.isNotEmpty
        ? _fillHands(
            hands,
            frame,
            cropSide: cropSide,
            cropXOff: cropXOff,
            sensorOrientation: sensorOrientation,
            isFlipped: isFlipped,
            leftHandMode: leftHandMode,
          )
        : (left: <Offset>[], right: <Offset>[]);

    return MlFrameResult(
      features: frame,
      posePoints: posePoints,
      rightHandPoints: handsData.right,
      leftHandPoints: handsData.left,
      anyDetected: poses.isNotEmpty || hands.isNotEmpty,
      poseCount: poses.length,
      handCount: hands.length,
    );
  }

  // ── Pose doldurma ─────────────────────────────────────────────────────────

  List<Offset> _fillPose(
    mlkit.Pose pose,
    List<double> frame, {
    required int cropSide,
    required int cropXOff,
    required int cropYOff,
    required bool isFlipped,
  }) {
    final displayPoints = <Offset>[];
    for (int i = 0; i < _poseIndices.length; i++) {
      final lm = pose.landmarks[mlkit.PoseLandmarkType.values[_poseIndices[i]]];
      if (lm == null) continue;

      double mx = ((lm.x - cropXOff) / cropSide).clamp(0.0, 1.0);
      double my = ((lm.y - cropYOff) / cropSide).clamp(0.0, 1.0);
      if (isFlipped) mx = 1.0 - mx;

      frame[84 + i * 2] = mx;
      frame[84 + i * 2 + 1] = my;
      displayPoints.add(Offset(lm.x / 240.0, lm.y / 320.0));
    }
    return displayPoints;
  }

  // ── El doldurma ───────────────────────────────────────────────────────────

  ({List<Offset> right, List<Offset> left}) _fillHands(
    List<dynamic> hands,
    List<double> frame, {
    required int cropSide,
    required int cropXOff,
    required int sensorOrientation,
    required bool isFlipped,
    required bool leftHandMode,
  }) {
    final displayRight = <Offset>[];
    final displayLeft = <Offset>[];

    // ResolutionPreset.low Android: 320×240
    const double sw = 320.0;
    const double sh = 240.0;

    for (final hand in hands) {
      final bool isAnatomicalRight = (hand.handedness == Handedness.right);
      final bool useRightSlot = leftHandMode
          ? !isAnatomicalRight
          : isAnatomicalRight;

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

        double mx = _sensorXToModelX(
          sx,
          sy,
          cropSide,
          cropXOff,
          sensorOrientation,
        );
        double my = _sensorYToModelY(
          sx,
          sy,
          cropSide,
          cropXOff,
          sensorOrientation,
        );
        if (isFlipped) mx = 1.0 - mx;

        // Portrait önizleme koordinatları (240×320)
        final double dx = (240.0 - sy) / 240.0;
        final double dy = sx / 320.0;

        frame[offset + i * 2] = mx;
        frame[offset + i * 2 + 1] = my;
        displayTarget.add(Offset(dx.clamp(0.0, 1.0), dy.clamp(0.0, 1.0)));
      }
    }
    return (right: displayRight, left: displayLeft);
  }

  // ── Sensör → model koordinat dönüşümleri ─────────────────────────────────
  //
  // Kamera sensörü landscape üretir (ör. 640×480).
  // Model AUTSL portré 512×512 ile eğitildi; koordinatlar portré uzayında.

  double _sensorXToModelX(
    double sx,
    double sy,
    int cropSide,
    int cropXOff,
    int sensorOrientation,
  ) {
    switch (sensorOrientation) {
      case 90:
        return (1.0 - sy / cropSide).clamp(0.0, 1.0);
      case 270:
        return (sy / cropSide).clamp(0.0, 1.0);
      case 180:
        return (1.0 - (sx - cropXOff) / cropSide).clamp(0.0, 1.0);
      case 0:
        return ((sx - cropXOff) / cropSide).clamp(0.0, 1.0);
      default:
        return (1.0 - sy / cropSide).clamp(0.0, 1.0); // 90° varsayım
    }
  }

  double _sensorYToModelY(
    double sx,
    double sy,
    int cropSide,
    int cropXOff,
    int sensorOrientation,
  ) {
    switch (sensorOrientation) {
      case 90:
        return ((sx - cropXOff) / cropSide).clamp(0.0, 1.0);
      case 270:
        return (1.0 - (sx - cropXOff) / cropSide).clamp(0.0, 1.0);
      case 180:
        return (1.0 - (sy / cropSide)).clamp(0.0, 1.0);
      case 0:
        return (sy / cropSide).clamp(0.0, 1.0);
      default:
        return ((sx - cropXOff) / cropSide).clamp(0.0, 1.0); // 90° varsayım
    }
  }

  // ── NV21 yapımı ───────────────────────────────────────────────────────────
  // Döküm: NV21 = Y düzlemi (parlaklık) + V-U ikili renk düzlemi.
  // Eğer kamera 3 düzlem sağlamazsa null döndür — çağıranlar bu frame'i atlar.

  Uint8List? _buildNV21(CameraImage image) {
    if (image.planes.length < 3) {
      if (kDebugMode) {
        debugPrint(
          '⚠️ _buildNV21: ${image.planes.length} plane alındı, UV eksik — frame atlandı.',
        );
      }
      return null; // Bozuk NV21 üretmek yerine frame'i atla
    }

    final int w = image.width;
    final int h = image.height;
    final int size = w * h * 3 ~/ 2;

    if (_nv21Buffer == null || _nv21Buffer!.length != size) {
      _nv21Buffer = Uint8List(size);
    }

    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];
    final int uPixelStride = uPlane.bytesPerPixel ?? 2;
    final int vPixelStride = vPlane.bytesPerPixel ?? 2;

    final out = _nv21Buffer!;
    for (int r = 0; r < h; r++) {
      out.setRange(r * w, (r + 1) * w, yPlane.bytes, r * yPlane.bytesPerRow);
    }
    int uvOffset = w * h;
    final int uvRows = h ~/ 2;
    final int uvCols = w ~/ 2;
    for (int r = 0; r < uvRows; r++) {
      for (int c = 0; c < uvCols; c++) {
        final srcU = r * uPlane.bytesPerRow + c * uPixelStride;
        final srcV = r * vPlane.bytesPerRow + c * vPixelStride;
        out[uvOffset++] = vPlane.bytes[srcV];
        out[uvOffset++] = uPlane.bytes[srcU];
      }
    }
    return out;
  }

  // ── InputImage yapımı ─────────────────────────────────────────────────────

  mlkit.InputImage? _buildInputImage(
    CameraImage image,
    Uint8List? nv21,
    int sensorOrientation,
  ) {
    try {
      final rotation =
          mlkit.InputImageRotationValue.fromRawValue(sensorOrientation) ??
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
        if (bytes == null) return null; // UV plane eksik — frame atla
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

  // ── Mat yapımı ────────────────────────────────────────────────────────────

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
        if (bytes == null) return null; // UV plane eksik — frame atla
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

  // ── Temizlik ──────────────────────────────────────────────────────────────

  void dispose() {
    try {
      _poseDetector?.close();
    } catch (_) {}
    try {
      _handDetector?.dispose();
    } catch (_) {}
  }
}
