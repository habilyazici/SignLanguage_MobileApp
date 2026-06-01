import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Kamera yaşam döngüsü — navigasyon katmanı ile recognition arasındaki köprü
//
// ScaffoldWithNav bu provider'a yazar (true = kamera ekranı aktif).
// RecognitionNotifier bu provider'ı dinleyerek image stream'i başlatır/durdurur.
// Böylece navigation katmanı recognition feature'ını doğrudan import etmez.
// ─────────────────────────────────────────────────────────────────────────────

final cameraActiveProvider =
    NotifierProvider<CameraActiveNotifier, bool>(CameraActiveNotifier.new);

class CameraActiveNotifier extends Notifier<bool> {
  /// Kamera donanımı tamamen serbest bırakıldığında tamamlanan Completer.
  /// STT gibi ses donanımı kullanan modüller bunu await edebilir.
  Completer<void>? _releaseCompleter;

  /// Mevcut pause isteğinin donanımı tamamen serbest bırakması gerekip gerekmediği.
  /// false → sadece stream durdurulur, controller canlı kalır (hızlı resume için).
  /// true  → donanım tamamen serbest bırakılır (iOS STT / AVAudioSession için).
  bool _releaseHardware = false;
  bool get releaseHardware => _releaseHardware;

  @override
  bool build() => false;

  void setActive({required bool active, bool releaseHardware = false}) {
    _releaseHardware = releaseHardware;
    if (!active && state) {
      // Kamera kapatılıyor — release sinyali hazırla
      _releaseCompleter = Completer<void>();
    }
    state = active;
  }

  /// Kamera donanımı tamamen serbest kaldığında çağrılır.
  /// (RecognitionNotifier → pauseCamera() tamamlandıktan sonra)
  void markReleased() {
    if (_releaseCompleter != null && !_releaseCompleter!.isCompleted) {
      _releaseCompleter!.complete();
    }
  }

  /// Kamera donanımının serbest kalmasını bekler.
  /// Kamera zaten kapalıysa anında döner.
  Future<void> waitForRelease() async {
    if (!state && (_releaseCompleter == null || _releaseCompleter!.isCompleted)) {
      return; // Zaten kapalı
    }
    // Max 3 saniye bekle — timeout ile sonsuz askıda kalmayı önle
    await _releaseCompleter?.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () {},
    );
  }
}
