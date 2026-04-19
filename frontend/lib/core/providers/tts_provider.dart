import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/tts_service.dart';
import '../services/tts_service_impl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TTS Provider — uygulama boyunca tek bir TtsService örneği
// ─────────────────────────────────────────────────────────────────────────────

final _ttsServiceProvider = Provider<TtsService>((_) => TtsServiceImpl());

final ttsProvider =
    NotifierProvider<TtsNotifier, void>(TtsNotifier.new);

class TtsNotifier extends Notifier<void> {
  late final TtsService _service;

  @override
  void build() {
    ref.keepAlive();
    _service = ref.read(_ttsServiceProvider);
    _service.initialize();
    ref.onDispose(_service.dispose);
  }

  /// Kelimeyi seslendir (önceki konuşmayı keser)
  void speak(String word) => _service.speak(word);

  /// Seslendirmeyi durdur
  void stop() => _service.stop();
}
