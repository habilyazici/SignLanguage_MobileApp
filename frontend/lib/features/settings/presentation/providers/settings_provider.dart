import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../data/datasources/settings_local_datasource.dart';
import '../../data/repositories/settings_repository_impl.dart';

// Mevcut import'lar settings_provider.dart üzerinden geldiğinden
// uyumluluk için domain entity'lerini yeniden dışa aktarıyoruz.
export '../../domain/entities/app_settings.dart'
    show AppSettings, AppTextSize, ConfidenceLevel, VideoQuality, FpsPreference;

// ─────────────────────────────────────────────────────────────────────────────
// SharedPreferences erken yükleme provider'ı
// main.dart'ta await ile yüklenen prefs buraya override edilir.
// ─────────────────────────────────────────────────────────────────────────────

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('main.dart içinde override edilmeli'),
);

// ─────────────────────────────────────────────────────────────────────────────
// Repository provider — data katmanını presentation'a bağlar
// ─────────────────────────────────────────────────────────────────────────────

/// Public — diğer feature'lar doğrudan SettingsRepository'e bağlanabilir.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return SettingsRepositoryImpl(SettingsLocalDatasource(prefs));
});

// ─────────────────────────────────────────────────────────────────────────────
// Settings provider
// ─────────────────────────────────────────────────────────────────────────────

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends Notifier<AppSettings> {
  late SettingsRepository _repo;

  @override
  AppSettings build() {
    ref.keepAlive();
    _repo = ref.read(settingsRepositoryProvider);
    return _repo.load();
  }

  void _persist(AppSettings updated) {
    state = updated;
    _repo.save(updated);
  }

  // ── Görünüm ───────────────────────────────────────────────────────────────
  void setThemeMode(ThemeMode mode) =>
      _persist(state.copyWith(themeMode: mode));

  void setTextSize(AppTextSize size) =>
      _persist(state.copyWith(textSize: size));

  void toggleLeftHandMode() =>
      _persist(state.copyWith(leftHandMode: !state.leftHandMode));

  // ── Kamera & AI ───────────────────────────────────────────────────────────
  void setConfidenceLevel(ConfidenceLevel level) =>
      _persist(state.copyWith(confidenceLevel: level));

  void setFpsPreference(FpsPreference pref) =>
      _persist(state.copyWith(fpsPreference: pref));

  // ── Veri & Video ──────────────────────────────────────────────────────────
  void toggleCellularVideo() => _persist(
    state.copyWith(cellularVideoDisabled: !state.cellularVideoDisabled),
  );

  void setVideoQuality(VideoQuality q) =>
      _persist(state.copyWith(videoQuality: q));

  // ── Gizlilik ──────────────────────────────────────────────────────────────
  void toggleZeroDataMode() =>
      _persist(state.copyWith(zeroDataMode: !state.zeroDataMode));

  void toggleCloudSync() =>
      _persist(state.copyWith(cloudSyncEnabled: !state.cloudSyncEnabled));

  // ── Ses ───────────────────────────────────────────────────────────────────
  void toggleTts() => _persist(state.copyWith(ttsEnabled: !state.ttsEnabled));

  void toggleStt() => _persist(state.copyWith(sttEnabled: !state.sttEnabled));

  // ── Geliştirici ───────────────────────────────────────────────────────────
  void toggleDevMode() => _persist(state.copyWith(devMode: !state.devMode));

  void toggleShowDevButton() =>
      _persist(state.copyWith(showDevButton: !state.showDevButton));

  void setStableFramesThreshold(int val) =>
      _persist(state.copyWith(stableFramesThreshold: val));

  void setMotionThreshold(double val) =>
      _persist(state.copyWith(motionThreshold: val));
}
