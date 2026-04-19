import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

/// Kamera donanımına erişim datasource'u.
/// Başlatma, duraklatma, kamera geçişi ve controller stream'ini yönetir.
class CameraDataSource {
  CameraController? _camera;
  List<CameraDescription> _allCameras = [];
  CameraLensDirection _currentLens = CameraLensDirection.back;

  final _controllerCtrl = StreamController<CameraController?>.broadcast();

  /// Kamera controller değiştiğinde (ilk açılış / geçiş) yeni değer yayar.
  Stream<CameraController?> get controllerStream => _controllerCtrl.stream;

  CameraController? get currentCamera => _camera;
  int get sensorOrientation => _camera?.description.sensorOrientation ?? 90;
  bool get isFlipped => _currentLens == CameraLensDirection.front;

  Future<void> initialize() => _startCamera();

  Future<void> _startCamera({CameraLensDirection? lens}) async {
    _allCameras = await availableCameras();
    if (_allCameras.isEmpty) throw Exception('Hiç kamera bulunamadı');

    final direction = lens ?? _currentLens;
    final selected = _allCameras.firstWhere(
      (c) => c.lensDirection == direction,
      orElse: () => _allCameras.first,
    );
    _currentLens = selected.lensDirection;

    final format = Platform.isIOS
        ? ImageFormatGroup.bgra8888
        : ImageFormatGroup.yuv420;

    try {
      await _camera?.stopImageStream();
    } catch (_) {}
    try {
      await _camera?.dispose();
    } catch (_) {}

    _camera = CameraController(
      selected,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: format,
    );
    await _camera!.initialize();
    debugPrint(
      '📷 Kamera hazır: ${selected.name} (sensör: ${_camera!.description.sensorOrientation}°)',
    );
    _controllerCtrl.add(_camera);
  }

  void startStream(void Function(CameraImage) onFrame) {
    try {
      _camera?.startImageStream(onFrame);
    } catch (_) {}
  }

  void stopStream() {
    try {
      _camera?.stopImageStream();
    } catch (_) {}
  }

  Future<void> switchCamera() async {
    final next = _currentLens == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    await _startCamera(lens: next);
  }

  /// Kamera donanımını serbest bırakır (yeşil nokta söner) ama stream açık
  /// kalır — resumeCamera() sonrasında yeniden initialize edilebilir.
  Future<void> release() async {
    try {
      await _camera?.stopImageStream();
    } catch (_) {}
    try {
      await _camera?.dispose();
    } catch (_) {}
    _camera = null;
    if (!_controllerCtrl.isClosed) _controllerCtrl.add(null);
  }

  /// Kalıcı temizlik — stream de kapatılır, artık kullanılamaz.
  Future<void> dispose() async {
    await release();
    if (!_controllerCtrl.isClosed) _controllerCtrl.close();
  }
}
