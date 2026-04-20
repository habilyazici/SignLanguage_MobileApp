import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/app_settings.dart';

/// SharedPreferences üzerinde AppSettings okuma/yazma işlemlerini kapsar.
/// Platform bağımlılığı (SharedPreferences) yalnızca bu sınıfta bulunur.
class SettingsLocalDatasource {
  const SettingsLocalDatasource(this._prefs);

  final SharedPreferences _prefs;

  AppSettings read() => AppSettings(
    themeMode: _enumVal(ThemeMode.values, 'themeMode', ThemeMode.system),
    textSize: _enumVal(AppTextSize.values, 'textSize', AppTextSize.standard),
    leftHandMode: _prefs.getBool('leftHandMode') ?? false,
    confidenceLevel: _enumVal(
      ConfidenceLevel.values,
      'confidenceLevel',
      ConfidenceLevel.medium,
    ),
    fpsPreference: _enumVal(
      FpsPreference.values,
      'fpsPreference',
      FpsPreference.performance,
    ),
    cellularVideoDisabled: _prefs.getBool('cellularVideoDisabled') ?? false,
    videoQuality: _enumVal(
      VideoQuality.values,
      'videoQuality',
      VideoQuality.high,
    ),
    zeroDataMode: _prefs.getBool('zeroDataMode') ?? false,
    cloudSyncEnabled: _prefs.getBool('cloudSyncEnabled') ?? false,
    ttsEnabled: _prefs.getBool('ttsEnabled') ?? true,
    sttEnabled: _prefs.getBool('sttEnabled') ?? true,
    devMode: _prefs.getBool('devMode') ?? false,
    showDevButton: _prefs.getBool('showDevButton') ?? false,
    stableFramesThreshold: _prefs.getInt('stableFramesThreshold') ?? 3,
    motionThreshold: _prefs.getDouble('motionThreshold') ?? 0.025,
  );

  Future<void> write(AppSettings s) async {
    await _prefs.setInt('themeMode', s.themeMode.index);
    await _prefs.setInt('textSize', s.textSize.index);
    await _prefs.setBool('leftHandMode', s.leftHandMode);
    await _prefs.setInt('confidenceLevel', s.confidenceLevel.index);
    await _prefs.setInt('fpsPreference', s.fpsPreference.index);
    await _prefs.setBool('cellularVideoDisabled', s.cellularVideoDisabled);
    await _prefs.setInt('videoQuality', s.videoQuality.index);
    await _prefs.setBool('zeroDataMode', s.zeroDataMode);
    await _prefs.setBool('cloudSyncEnabled', s.cloudSyncEnabled);
    await _prefs.setBool('ttsEnabled', s.ttsEnabled);
    await _prefs.setBool('sttEnabled', s.sttEnabled);
    await _prefs.setBool('devMode', s.devMode);
    await _prefs.setBool('showDevButton', s.showDevButton);
    await _prefs.setInt('stableFramesThreshold', s.stableFramesThreshold);
    await _prefs.setDouble('motionThreshold', s.motionThreshold);
  }

  /// Kaydedilmiş index enum sınırları dışındaysa (uygulama güncellemesi
  /// sonrası enum küçüldüyse vb.) varsayılan değere düşer.
  T _enumVal<T>(List<T> values, String key, T fallback) {
    final idx = _prefs.getInt(key);
    if (idx == null || idx < 0 || idx >= values.length) return fallback;
    return values[idx];
  }
}
