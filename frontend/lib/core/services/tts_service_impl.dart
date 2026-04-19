import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'tts_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TTS Servisi — Türkçe kelime seslendirme
//
// Kullanım: Her yeni onaylanan işaret kelimesi anında okunur (kelime kelime).
// Ayarlar ekranından ttsEnabled toggle edilebilir.
// ─────────────────────────────────────────────────────────────────────────────

class TtsServiceImpl implements TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  // TTS hazır olmadan speak() çağrılırsa kelimeyi beklet; hazır olunca çal.
  String? _pendingWord;

  @override
  Future<void> initialize() async {
    try {
      // Android için sistem TTS motoru ayarları
      if (Platform.isAndroid) {
        await _tts.setQueueMode(1); // FLUSH — yeni kelime eskiyi keser
      }

      await _tts.setLanguage('tr-TR');
      await _tts.setSpeechRate(0.45);  // Biraz yavaş — net anlaşılsın
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      // Türkçe ses motoru yoksa İngilizce geri dön
      final languages = await _tts.getLanguages as List?;
      if (languages != null && !languages.contains('tr-TR')) {
        await _tts.setLanguage('tr');
      }

      _ready = true;
      debugPrint('✅ TTS hazır (tr-TR)');

      // Başlatma sırasında gelen kelime varsa şimdi seslendir
      if (_pendingWord != null) {
        final word = _pendingWord!;
        _pendingWord = null;
        await _tts.speak(word);
      }
    } catch (e) {
      debugPrint('❌ TTS başlatma hatası: $e');
    }
  }

  /// Yeni kelime geldiğinde çağrılır — önceki konuşmayı keserek başlar
  @override
  Future<void> speak(String word) async {
    if (word.isEmpty) return;
    if (!_ready) {
      // TTS henüz hazır değil — en son kelimeyi beklet (eski bekleme iptal)
      _pendingWord = word;
      return;
    }
    try {
      await _tts.stop();
      await _tts.speak(word);
    } catch (e) {
      debugPrint('❌ TTS speak hatası: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  @override
  void dispose() {
    _tts.stop();
  }
}
