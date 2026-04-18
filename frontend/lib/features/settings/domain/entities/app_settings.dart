import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enum'lar
// ─────────────────────────────────────────────────────────────────────────────

enum AppTextSize {
  standard, // varsayılan
  large, // Büyük
  extraLarge, // Ekstra Büyük
}

enum ConfidenceLevel {
  low, // %65 — daha duyarlı, daha fazla yanlış pozitif
  medium, // %75 — dengeli (varsayılan)
  high, // %85 — daha katı, daha az tanıma
}

enum VideoQuality {
  high, // 720p
  dataSaver, // 360p
}

// ─────────────────────────────────────────────────────────────────────────────
// AppSettings — saf domain entity, platform bağımlılığı yok
// ─────────────────────────────────────────────────────────────────────────────

class AppSettings {
  // ── Görünüm ──────────────────────────────────────────────────────────────
  final ThemeMode themeMode;
  final AppTextSize textSize;
  final bool leftHandMode;

  // ── Kamera & Yapay Zeka ───────────────────────────────────────────────────
  final ConfidenceLevel confidenceLevel;
  final bool fpsLimitEnabled;
  final bool hapticEnabled;
  final bool temporalSmoothingEnabled;

  // ── Veri & Video ──────────────────────────────────────────────────────────
  final bool cellularVideoDisabled;
  final VideoQuality videoQuality;

  // ── Gizlilik & Veri ───────────────────────────────────────────────────────
  final bool zeroDataMode;
  final bool cloudSyncEnabled;

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
    ConfidenceLevel.low => 0.65,
    ConfidenceLevel.medium => 0.75,
    ConfidenceLevel.high => 0.85,
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
}
