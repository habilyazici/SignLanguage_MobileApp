import 'package:flutter/material.dart';

import '../../../../core/constants/recognition_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enum'lar
// ─────────────────────────────────────────────────────────────────────────────

enum AppTextSize {
  standard, // index 0 — Standart (varsayılan)
  large, // index 1 — Büyük
  extraLarge, // index 2 — Çok Büyük
  small, // index 3 — Küçük (sona eklendi, mevcut kayıtlı indeksler korundu)
}

enum ConfidenceLevel {
  low, // %65 — daha duyarlı, daha fazla yanlış pozitif
  medium, // %75 — dengeli (varsayılan)
  high, // %85 — daha katı, daha az tanıma
}

enum FpsPreference {
  powerSaver, // 15 FPS
  balanced, // 20 FPS
  performance, // 30 FPS
  unlimited, // Maksimum (Throttling kapalı)
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
  final FpsPreference fpsPreference;

  // ── Veri & Video ──────────────────────────────────────────────────────────
  final bool cellularVideoDisabled;
  final VideoQuality videoQuality;

  // ── Gizlilik & Veri ───────────────────────────────────────────────────────
  final bool zeroDataMode;

  // ── Ses ───────────────────────────────────────────────────────────────────
  final bool ttsEnabled;
  final bool sttEnabled;

  // ── Geliştirici ───────────────────────────────────────────────────────────
  final bool devMode;
  final bool showDevButton;

  // ── AI Kararlılık (Dynamic) ────────────────────────────────────────────────
  final int stableFramesThreshold;
  final double motionThreshold;

  const AppSettings({
    this.themeMode = ThemeMode.light,
    this.textSize = AppTextSize.standard,
    this.leftHandMode = false,
    this.confidenceLevel = ConfidenceLevel.medium,
    this.fpsPreference = FpsPreference.performance,
    this.cellularVideoDisabled = false,
    this.videoQuality = VideoQuality.high,
    this.zeroDataMode = false,
    this.ttsEnabled = true,
    this.sttEnabled = true,
    this.devMode = false,
    this.showDevButton = false,
    this.stableFramesThreshold = RecognitionConstants.defaultStableFrames,
    this.motionThreshold = RecognitionConstants.motionThreshold,
  });

  /// Confidence level'ı TFLite threshold değerine dönüştürür.
  double get confidenceThreshold => switch (confidenceLevel) {
    ConfidenceLevel.low => 0.65,
    ConfidenceLevel.medium => 0.75,
    ConfidenceLevel.high => 0.85,
  };

  /// Hedef FPS değeri.
  /// 0 değeri sınırsız (throttle yok) anlamına gelir.
  int get targetFps => switch (fpsPreference) {
    FpsPreference.powerSaver => 15,
    FpsPreference.balanced => 20,
    FpsPreference.performance => 30,
    FpsPreference.unlimited => 0,
  };

  AppSettings copyWith({
    ThemeMode? themeMode,
    AppTextSize? textSize,
    bool? leftHandMode,
    ConfidenceLevel? confidenceLevel,
    FpsPreference? fpsPreference,
    bool? cellularVideoDisabled,
    VideoQuality? videoQuality,
    bool? zeroDataMode,
    bool? ttsEnabled,
    bool? sttEnabled,
    bool? devMode,
    bool? showDevButton,
    int? stableFramesThreshold,
    double? motionThreshold,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    textSize: textSize ?? this.textSize,
    leftHandMode: leftHandMode ?? this.leftHandMode,
    confidenceLevel: confidenceLevel ?? this.confidenceLevel,
    fpsPreference: fpsPreference ?? this.fpsPreference,
    cellularVideoDisabled: cellularVideoDisabled ?? this.cellularVideoDisabled,
    videoQuality: videoQuality ?? this.videoQuality,
    zeroDataMode: zeroDataMode ?? this.zeroDataMode,
    ttsEnabled: ttsEnabled ?? this.ttsEnabled,
    sttEnabled: sttEnabled ?? this.sttEnabled,
    devMode: devMode ?? this.devMode,
    showDevButton: showDevButton ?? this.showDevButton,
    stableFramesThreshold: stableFramesThreshold ?? this.stableFramesThreshold,
    motionThreshold: motionThreshold ?? this.motionThreshold,
  );
}
