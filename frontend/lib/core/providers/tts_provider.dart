import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/tts_service.dart';
import '../services/tts_service_impl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TTS Provider — uygulama boyunca tek bir TtsService örneği
// ─────────────────────────────────────────────────────────────────────────────

final _ttsServiceProvider = Provider<TtsService>((_) => TtsServiceImpl());

/// State: TTS'in şu an konuşup konuşmadığı (true = konuşuyor)
final ttsProvider =
    NotifierProvider<TtsNotifier, bool>(TtsNotifier.new);

class TtsNotifier extends Notifier<bool> {
  late final TtsService _service;

  @override
  bool build() {
    ref.keepAlive();
    _service = ref.read(_ttsServiceProvider);
    _service.initialize(onSpeakingChanged: (val) => state = val);
    ref.onDispose(_service.dispose);
    return false;
  }

  void speak(String word) => unawaited(_service.speak(word));
  void stop() => unawaited(_service.stop());
}
