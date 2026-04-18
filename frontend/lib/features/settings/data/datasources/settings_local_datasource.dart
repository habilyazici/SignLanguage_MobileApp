import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/app_settings.dart';

/// SharedPreferences üzerinde AppSettings okuma/yazma işlemlerini kapsar.
/// Platform bağımlılığı (SharedPreferences) yalnızca bu sınıfta bulunur.
class SettingsLocalDatasource {
  const SettingsLocalDatasource(this._prefs);

  final SharedPreferences _prefs;

  AppSettings read() => AppSettings(
    themeMode:
        ThemeMode.values[_prefs.getInt('themeMode') ?? ThemeMode.system.index],
    textSize: AppTextSize
        .values[_prefs.getInt('textSize') ?? AppTextSize.standard.index],
    leftHandMode: _prefs.getBool('leftHandMode') ?? false,
    confidenceLevel: ConfidenceLevel
        .values[_prefs.getInt('confidenceLevel') ?? ConfidenceLevel.medium.index],
    fpsLimitEnabled: _prefs.getBool('fpsLimitEnabled') ?? false,
    hapticEnabled: _prefs.getBool('hapticEnabled') ?? true,
    temporalSmoothingEnabled: _prefs.getBool('temporalSmoothingEnabled') ?? true,
    cellularVideoDisabled: _prefs.getBool('cellularVideoDisabled') ?? false,
    videoQuality: VideoQuality
        .values[_prefs.getInt('videoQuality') ?? VideoQuality.high.index],
    zeroDataMode: _prefs.getBool('zeroDataMode') ?? false,
    cloudSyncEnabled: _prefs.getBool('cloudSyncEnabled') ?? false,
    ttsEnabled: _prefs.getBool('ttsEnabled') ?? true,
    sttEnabled: _prefs.getBool('sttEnabled') ?? true,
    devMode: _prefs.getBool('devMode') ?? false,
  );

  Future<void> write(AppSettings s) async {
    await _prefs.setInt('themeMode', s.themeMode.index);
    await _prefs.setInt('textSize', s.textSize.index);
    await _prefs.setBool('leftHandMode', s.leftHandMode);
    await _prefs.setInt('confidenceLevel', s.confidenceLevel.index);
    await _prefs.setBool('fpsLimitEnabled', s.fpsLimitEnabled);
    await _prefs.setBool('hapticEnabled', s.hapticEnabled);
    await _prefs.setBool('temporalSmoothingEnabled', s.temporalSmoothingEnabled);
    await _prefs.setBool('cellularVideoDisabled', s.cellularVideoDisabled);
    await _prefs.setInt('videoQuality', s.videoQuality.index);
    await _prefs.setBool('zeroDataMode', s.zeroDataMode);
    await _prefs.setBool('cloudSyncEnabled', s.cloudSyncEnabled);
    await _prefs.setBool('ttsEnabled', s.ttsEnabled);
    await _prefs.setBool('sttEnabled', s.sttEnabled);
    await _prefs.setBool('devMode', s.devMode);
  }
}
