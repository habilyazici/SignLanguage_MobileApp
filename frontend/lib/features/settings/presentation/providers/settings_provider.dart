import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enum'lar
// ─────────────────────────────────────────────────────────────────────────────

enum AppTextSize {
  standard, // varsayılan
  large, // Büyük
  extraLarge, // Ekstra Büyük
}

enum ConfidenceLevel {
  low, // %70 — daha duyarlı, daha fazla yanlış pozitif
  medium, // %80 — dengeli (varsayılan)
  high, // %90 — daha katı, daha az tanıma
}

enum VideoQuality {
  high, // 720p
  dataSaver, // 360p
}

// ─────────────────────────────────────────────────────────────────────────────
// AppSettings veri modeli
// ─────────────────────────────────────────────────────────────────────────────

class AppSettings {
  // ── Görünüm ──────────────────────────────────────────────────────────────
  final ThemeMode themeMode;
  final AppTextSize textSize;
  final bool leftHandMode;

  // ── Kamera & Yapay Zeka ───────────────────────────────────────────────────
  final ConfidenceLevel confidenceLevel;
  final bool fpsLimitEnabled; // 30fps → 15fps
  final bool hapticEnabled; // Titreşim geri bildirimi
  final bool temporalSmoothingEnabled;

  // ── Veri & Video (backend hazır olduğunda aktif olacak) ───────────────────
  final bool cellularVideoDisabled;
  final VideoQuality videoQuality;

  // ── Gizlilik & Veri ───────────────────────────────────────────────────────
  final bool zeroDataMode; // Çeviri geçmişini kaydetme
  final bool cloudSyncEnabled; // Ayarları buluta senkronize et

  // ── Ses ───────────────────────────────────────────────────────────────────
  final bool ttsEnabled;
  final bool sttEnabled;

  // ── Geliştirici ───────────────────────────────────────────────────────────
  final bool devMode;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.textSize = AppTextSize.standard,
    this.leftHandMode = false,
    this.confidenceLevel = ConfidenceLevel.medium,
    this.fpsLimitEnabled = false,
    this.hapticEnabled = true,
    this.temporalSmoothingEnabled = true,
    this.cellularVideoDisabled = false,
    this.videoQuality = VideoQuality.high,
    this.zeroDataMode = false,
    this.cloudSyncEnabled = false,
    this.ttsEnabled = true,
    this.sttEnabled = true,
    this.devMode = false,
  });

  /// Confidence level'ı TFLite threshold değerine dönüştürür.
  double get confidenceThreshold => switch (confidenceLevel) {
    ConfidenceLevel.low => 0.70,
    ConfidenceLevel.medium => 0.80,
    ConfidenceLevel.high => 0.90,
  };

  /// Hedef FPS değeri.
  int get targetFps => fpsLimitEnabled ? 15 : 30;

  AppSettings copyWith({
    ThemeMode? themeMode,
    AppTextSize? textSize,
    bool? leftHandMode,
    ConfidenceLevel? confidenceLevel,
    bool? fpsLimitEnabled,
    bool? hapticEnabled,
    bool? temporalSmoothingEnabled,
    bool? cellularVideoDisabled,
    VideoQuality? videoQuality,
    bool? zeroDataMode,
    bool? cloudSyncEnabled,
    bool? ttsEnabled,
    bool? sttEnabled,
    bool? devMode,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    textSize: textSize ?? this.textSize,
    leftHandMode: leftHandMode ?? this.leftHandMode,
    confidenceLevel: confidenceLevel ?? this.confidenceLevel,
    fpsLimitEnabled: fpsLimitEnabled ?? this.fpsLimitEnabled,
    hapticEnabled: hapticEnabled ?? this.hapticEnabled,
    temporalSmoothingEnabled:
        temporalSmoothingEnabled ?? this.temporalSmoothingEnabled,
    cellularVideoDisabled: cellularVideoDisabled ?? this.cellularVideoDisabled,
    videoQuality: videoQuality ?? this.videoQuality,
    zeroDataMode: zeroDataMode ?? this.zeroDataMode,
    cloudSyncEnabled: cloudSyncEnabled ?? this.cloudSyncEnabled,
    ttsEnabled: ttsEnabled ?? this.ttsEnabled,
    sttEnabled: sttEnabled ?? this.sttEnabled,
    devMode: devMode ?? this.devMode,
  );

  // ── SharedPreferences serileştirme ────────────────────────────────────────

  static AppSettings fromPrefs(SharedPreferences prefs) {
    return AppSettings(
      themeMode:
          ThemeMode.values[prefs.getInt('themeMode') ?? ThemeMode.system.index],
      textSize: AppTextSize
          .values[prefs.getInt('textSize') ?? AppTextSize.standard.index],
      leftHandMode: prefs.getBool('leftHandMode') ?? false,
      confidenceLevel:
          ConfidenceLevel.values[prefs.getInt('confidenceLevel') ??
              ConfidenceLevel.medium.index],
      fpsLimitEnabled: prefs.getBool('fpsLimitEnabled') ?? false,
      hapticEnabled: prefs.getBool('hapticEnabled') ?? true,
      temporalSmoothingEnabled:
          prefs.getBool('temporalSmoothingEnabled') ?? true,
      cellularVideoDisabled: prefs.getBool('cellularVideoDisabled') ?? false,
      videoQuality: VideoQuality
          .values[prefs.getInt('videoQuality') ?? VideoQuality.high.index],
      zeroDataMode: prefs.getBool('zeroDataMode') ?? false,
      cloudSyncEnabled: prefs.getBool('cloudSyncEnabled') ?? false,
      ttsEnabled: prefs.getBool('ttsEnabled') ?? true,
      sttEnabled: prefs.getBool('sttEnabled') ?? true,
      devMode: prefs.getBool('devMode') ?? false,
    );
  }

  Future<void> saveToPrefs(SharedPreferences prefs) async {
    await prefs.setInt('themeMode', themeMode.index);
    await prefs.setInt('textSize', textSize.index);
    await prefs.setBool('leftHandMode', leftHandMode);
    await prefs.setInt('confidenceLevel', confidenceLevel.index);
    await prefs.setBool('fpsLimitEnabled', fpsLimitEnabled);
    await prefs.setBool('hapticEnabled', hapticEnabled);
    await prefs.setBool('temporalSmoothingEnabled', temporalSmoothingEnabled);
    await prefs.setBool('cellularVideoDisabled', cellularVideoDisabled);
    await prefs.setInt('videoQuality', videoQuality.index);
    await prefs.setBool('zeroDataMode', zeroDataMode);
    await prefs.setBool('cloudSyncEnabled', cloudSyncEnabled);
    await prefs.setBool('ttsEnabled', ttsEnabled);
    await prefs.setBool('sttEnabled', sttEnabled);
    await prefs.setBool('devMode', devMode);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends Notifier<AppSettings> {
  SharedPreferences? _prefs;

  @override
  AppSettings build() {
    ref.keepAlive();
    _loadFromPrefs();
    return const AppSettings();
  }

  // ── Disk'ten yükle ─────────────────────────────────────────────────────────

  Future<void> _loadFromPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    state = AppSettings.fromPrefs(_prefs!);
  }

  // ── Disk'e kaydet (her state değişikliğinde çağrılır) ─────────────────────

  void _persist(AppSettings updated) {
    state = updated;
    _prefs?.let((p) => updated.saveToPrefs(p));
  }

  // Görünüm
  void setThemeMode(ThemeMode mode) =>
      _persist(state.copyWith(themeMode: mode));

  void setTextSize(AppTextSize size) =>
      _persist(state.copyWith(textSize: size));

  void toggleLeftHandMode() =>
      _persist(state.copyWith(leftHandMode: !state.leftHandMode));

  // Kamera & AI
  void setConfidenceLevel(ConfidenceLevel level) =>
      _persist(state.copyWith(confidenceLevel: level));

  void toggleFpsLimit() =>
      _persist(state.copyWith(fpsLimitEnabled: !state.fpsLimitEnabled));

  void toggleHaptic() =>
      _persist(state.copyWith(hapticEnabled: !state.hapticEnabled));

  void toggleTemporalSmoothing() => _persist(
    state.copyWith(temporalSmoothingEnabled: !state.temporalSmoothingEnabled),
  );

  // Veri & Video
  void toggleCellularVideo() => _persist(
    state.copyWith(cellularVideoDisabled: !state.cellularVideoDisabled),
  );

  void setVideoQuality(VideoQuality q) =>
      _persist(state.copyWith(videoQuality: q));

  // Gizlilik
  void toggleZeroDataMode() =>
      _persist(state.copyWith(zeroDataMode: !state.zeroDataMode));

  void toggleCloudSync() =>
      _persist(state.copyWith(cloudSyncEnabled: !state.cloudSyncEnabled));

  // Ses
  void toggleTts() => _persist(state.copyWith(ttsEnabled: !state.ttsEnabled));

  void toggleStt() => _persist(state.copyWith(sttEnabled: !state.sttEnabled));

  // Geliştirici
  void toggleDevMode() => _persist(state.copyWith(devMode: !state.devMode));
}

// ─────────────────────────────────────────────────────────────────────────────
// Null-safe yardımcı extension
// ─────────────────────────────────────────────────────────────────────────────

extension _NullSafeExt<T> on T? {
  void let(void Function(T value) fn) {
    final v = this;
    if (v != null) fn(v);
  }
}
