import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/settings_provider.dart';
import 'settings_dialogs.dart';
import 'settings_widgets.dart';

// ── Tema Satırı ──────────────────────────────────────────────────────────────
class ThemeRow extends StatelessWidget {
  const ThemeRow({
    super.key,
    required this.current,
    required this.onChanged,
    required this.isDark,
  });
  final ThemeMode current;
  final ValueChanged<ThemeMode> onChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          settingsIconBox(Icons.palette_rounded, AppTheme.secondaryBlue),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Tema',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          SettingsSegmentButtons<ThemeMode>(
            isDark: isDark,
            items: const [
              (ThemeMode.light, 'Açık'),
              (ThemeMode.system, 'Sistem'),
              (ThemeMode.dark, 'Koyu'),
            ],
            current: current,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ── Metin Boyutu Satırı ───────────────────────────────────────────────────────

// Slider'daki sıra (küçükten büyüğe) — enum index sırasından bağımsız
const _textSizeOrder = [
  AppTextSize.small,
  AppTextSize.standard,
  AppTextSize.large,
  AppTextSize.extraLarge,
];

const _textSizeLabels = ['Küçük', 'Standart', 'Büyük', 'Çok Büyük'];

class TextSizeRow extends StatelessWidget {
  const TextSizeRow({
    super.key,
    required this.current,
    required this.onChanged,
    required this.isDark,
  });
  final AppTextSize current;
  final ValueChanged<AppTextSize> onChanged;
  final bool isDark;

  String get _currentLabel =>
      _textSizeLabels[_textSizeOrder.indexOf(current)];

  @override
  Widget build(BuildContext context) {
    final sliderValue = _textSizeOrder.indexOf(current).toDouble();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              settingsIconBox(Icons.text_fields_rounded, Colors.indigoAccent),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Metin Boyutu',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Dinamik tipografi',
                      style: TextStyle(fontSize: 12, color: AppTheme.midGrey),
                    ),
                  ],
                ),
              ),
              Text(
                _currentLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 50),
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                activeTrackColor: AppTheme.primaryBlue,
                inactiveTrackColor: AppTheme.primaryBlue.withValues(alpha: 0.18),
                thumbColor: AppTheme.primaryBlue,
              ),
              child: Slider(
                value: sliderValue,
                min: 0,
                max: (_textSizeOrder.length - 1).toDouble(),
                divisions: _textSizeOrder.length - 1,
                onChanged: (v) => onChanged(_textSizeOrder[v.round()]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(50, 0, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Küçük',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.midGrey.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  'Çok Büyük',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.midGrey.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hassasiyet Satırı ─────────────────────────────────────────────────────────
class ConfidenceRow extends StatelessWidget {
  const ConfidenceRow({
    super.key,
    required this.current,
    required this.onChanged,
    required this.isDark,
  });
  final ConfidenceLevel current;
  final ValueChanged<ConfidenceLevel> onChanged;
  final bool isDark;

  String get _label => switch (current) {
    ConfidenceLevel.low => 'Düşük (%65)',
    ConfidenceLevel.medium => 'Orta (%75)',
    ConfidenceLevel.high => 'Yüksek (%85)',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          settingsIconBox(Icons.tune_rounded, Colors.greenAccent.shade700),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Çeviri Hassasiyeti',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  'Şu an: $_label',
                  style: const TextStyle(fontSize: 12, color: AppTheme.midGrey),
                ),
              ],
            ),
          ),
          SettingsSegmentButtons<ConfidenceLevel>(
            isDark: isDark,
            items: const [
              (ConfidenceLevel.low, '%65'),
              (ConfidenceLevel.medium, '%75'),
              (ConfidenceLevel.high, '%85'),
            ],
            current: current,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ── Video Kalitesi Satırı ────────────────────────────────────────────────────
class VideoQualityRow extends StatelessWidget {
  const VideoQualityRow({
    super.key,
    required this.current,
    required this.onChanged,
    required this.isDark,
  });
  final VideoQuality current;
  final ValueChanged<VideoQuality> onChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          settingsIconBox(Icons.hd_rounded, Colors.lightBlueAccent),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Video Kalitesi',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 2),
                Text(
                  'Öğrenme videoları için çözünürlük',
                  style: TextStyle(fontSize: 12, color: AppTheme.midGrey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SettingsSegmentButtons<VideoQuality>(
            isDark: isDark,
            items: const [
              (VideoQuality.high, '720p'),
              (VideoQuality.dataSaver, '360p'),
            ],
            current: current,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ── FPS Tercihi Satırı ───────────────────────────────────────────────────────
class FpsRow extends StatelessWidget {
  const FpsRow({
    super.key,
    required this.current,
    required this.onChanged,
    required this.isDark,
  });
  final FpsPreference current;
  final ValueChanged<FpsPreference> onChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          settingsIconBox(Icons.speed_rounded, Colors.orangeAccent),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kamera Kare Hızı (FPS)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 2),
                Text(
                  'Pil ve akıcılık dengesi',
                  style: TextStyle(fontSize: 12, color: AppTheme.midGrey),
                ),
              ],
            ),
          ),
          SettingsSegmentButtons<FpsPreference>(
            isDark: isDark,
            items: const [
              (FpsPreference.powerSaver, 'Pil'),
              (FpsPreference.balanced, 'Den'),
              (FpsPreference.performance, 'Perf'),
              (FpsPreference.unlimited, 'Max'),
            ],
            current: current,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ── Kararlılık (Stabilizasyon) Satırı ───────────────────────────────────────
class StabilityRow extends StatelessWidget {
  const StabilityRow({
    super.key,
    required this.current,
    required this.onChanged,
    required this.isDark,
  });
  final int current;
  final ValueChanged<int> onChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SettingsActionRow(
      isDark: isDark,
      icon: Icons.filter_alt_rounded,
      iconColor: Colors.purpleAccent,
      title: 'Kararlılık Eşiği',
      subtitle: 'Daha yüksek = Daha az gürültü',
      label: current.toString(),
      labelColor: AppTheme.primaryBlue,
      helpText:
          'AI\'nın bir kelimeyi ekrana yazması için onu kaç kez üst üste doğrulaması gerektiğini belirler.\n\n1 = Smoothing kapalı, her tespit anında kabul edilir\nÖnerilen: 4\nKatı: 8+',
      onTap: () => SettingsDialogs.showNumberPickerDialog(
        context: context,
        isDark: isDark,
        title: 'Kararlılık Eşiği',
        current: current,
        onChanged: onChanged,
        max: 10,
      ),
    );
  }
}

// ── Hareket Hassasiyeti Satırı ────────────────────────────────────────────────
class MotionThresholdRow extends StatelessWidget {
  const MotionThresholdRow({
    super.key,
    required this.current,
    required this.onChanged,
    required this.isDark,
  });
  final double current;
  final ValueChanged<double> onChanged;
  final bool isDark;

  String get _label {
    if (current <= 0.015) return 'Hassas (${current.toStringAsFixed(3)})';
    if (current <= 0.030) return 'Normal (${current.toStringAsFixed(3)})';
    return 'Kaba (${current.toStringAsFixed(3)})';
  }

  @override
  Widget build(BuildContext context) {
    return SettingsActionRow(
      isDark: isDark,
      icon: Icons.sensors_rounded,
      iconColor: Colors.tealAccent.shade700,
      title: 'Hareket Hassasiyeti',
      subtitle: 'Şu an: $_label',
      label: current.toStringAsFixed(3),
      labelColor: AppTheme.primaryBlue,
      helpText:
          'El hareketinin "gerçek hareket" sayılması için gereken minimum değişim miktarı.\n\nHassas: titrek eller veya küçük işaretler için\nKaba: yanlış tetiklenmeyi azaltır\n\nVarsayılan: 0.030',
      onTap: () => SettingsDialogs.showMotionThresholdDialog(
        context: context,
        isDark: isDark,
        current: current,
        onChanged: onChanged,
      ),
    );
  }
}
