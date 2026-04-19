import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    final isGuest = ref.watch(authProvider).isGuest;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.softGrey,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkBg : AppTheme.softGrey,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: isDark ? Colors.white : AppTheme.primaryBlue,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Ayarlar',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.primaryBlue,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          // ── Genel Cihaz & Görünüm ──────────────────────────────────────────
          _SectionHeader('Genel Cihaz & Görünüm'),
          _SettingsCard(
                isDark: isDark,
                children: [
                  _ThemeRow(
                    current: settings.themeMode,
                    onChanged: n.setThemeMode,
                    isDark: isDark,
                  ),
                  _Divider(isDark),
                  _TextSizeRow(
                    current: settings.textSize,
                    onChanged: n.setTextSize,
                    isDark: isDark,
                  ),
                  _Divider(isDark),
                  _SwitchRow(
                    isDark: isDark,
                    icon: Icons.back_hand_rounded,
                    iconColor: const Color(0xFF7C4DFF),
                    title: 'Solak Modu',
                    subtitle: 'Kamera deklanşörünü sola hizalar',
                    value: settings.leftHandMode,
                    onChanged: (_) => n.toggleLeftHandMode(),
                  ),
                ],
              )
              .animate()
              .fadeIn(delay: 60.ms, duration: 350.ms)
              .slideY(begin: 0.06),

          // ── Kamera & Yapay Zeka ────────────────────────────────────────────
          _SectionHeader('Kamera & Yapay Zeka'),
          _SettingsCard(
                isDark: isDark,
                children: [
                  _ConfidenceRow(
                    current: settings.confidenceLevel,
                    onChanged: n.setConfidenceLevel,
                    isDark: isDark,
                  ),
                  _Divider(isDark),
                  _SwitchRow(
                    isDark: isDark,
                    icon: Icons.blur_on_rounded,
                    iconColor: Colors.purpleAccent,
                    title: 'Temporal Düzleme',
                    subtitle: '2 ardışık onay eşleşirse kelimeyi ekrana yaz',
                    value: settings.temporalSmoothingEnabled,
                    onChanged: (_) => n.toggleTemporalSmoothing(),
                  ),
                  _Divider(isDark),
                  _SwitchRow(
                    isDark: isDark,
                    icon: Icons.speed_rounded,
                    iconColor: Colors.orangeAccent,
                    title: 'Düşük Güç Modu (15 FPS)',
                    subtitle:
                        'Pil tasarrufu — kamera kare hızını 15\'e indirir',
                    value: settings.fpsLimitEnabled,
                    onChanged: (_) => n.toggleFpsLimit(),
                  ),
                  _Divider(isDark),
                  _SwitchRow(
                    isDark: isDark,
                    icon: Icons.vibration_rounded,
                    iconColor: Colors.tealAccent,
                    title: 'Titreşim Geri Bildirimi',
                    subtitle: 'Kelime tanındığında hafif titreşim',
                    value: settings.hapticEnabled,
                    onChanged: (_) => n.toggleHaptic(),
                  ),
                ],
              )
              .animate()
              .fadeIn(delay: 120.ms, duration: 350.ms)
              .slideY(begin: 0.06),

          // ── Ses ───────────────────────────────────────────────────────────
          _SectionHeader('Ses'),
          _SettingsCard(
                isDark: isDark,
                children: [
                  _SwitchRow(
                    isDark: isDark,
                    icon: Icons.volume_up_rounded,
                    iconColor: Colors.deepOrangeAccent,
                    title: 'Sesli Okuma (TTS)',
                    subtitle: 'Tanınan kelimeyi Türkçe seslendir',
                    value: settings.ttsEnabled,
                    onChanged: (_) => n.toggleTts(),
                  ),
                  _Divider(isDark),
                  _SwitchRow(
                    isDark: isDark,
                    icon: Icons.mic_rounded,
                    iconColor: Colors.pinkAccent,
                    title: 'Sesli Giriş (STT)',
                    subtitle: 'Metin→İşaret ekranında mikrofon',
                    value: settings.sttEnabled,
                    onChanged: (_) => n.toggleStt(),
                  ),
                ],
              )
              .animate()
              .fadeIn(delay: 160.ms, duration: 350.ms)
              .slideY(begin: 0.06),

          // ── Veri Kullanımı & Video ─────────────────────────────────────────
          _SectionHeader('Veri Kullanımı & Video'),
          _SettingsCard(
                isDark: isDark,
                children: [
                  _SwitchRow(
                    isDark: isDark,
                    icon: Icons.signal_cellular_off_rounded,
                    iconColor: Colors.redAccent,
                    title: 'Mobil Veri\'de Video Kapalı',
                    subtitle: 'Wi-Fi yokken işaret videoları oynatılmaz',
                    value: settings.cellularVideoDisabled,
                    onChanged: (_) => n.toggleCellularVideo(),
                  ),
                  _Divider(isDark),
                  _VideoQualityRow(
                    current: settings.videoQuality,
                    onChanged: n.setVideoQuality,
                    isDark: isDark,
                  ),
                  _Divider(isDark),
                  _ActionRow(
                    isDark: isDark,
                    icon: Icons.cleaning_services_rounded,
                    iconColor: Colors.blueAccent,
                    title: 'Önbelleği Temizle',
                    subtitle: 'İndirilen videoları sil',
                    label: 'Temizle',
                    labelColor: Colors.blueAccent,
                    onTap: () => _showCacheDialog(context, isDark),
                  ),
                ],
              )
              .animate()
              .fadeIn(delay: 200.ms, duration: 350.ms)
              .slideY(begin: 0.06),

          // ── Gizlilik & Veri Kontrolü ───────────────────────────────────────
          _SectionHeader('Gizlilik & Veri Kontrolü'),
          _SettingsCard(
                isDark: isDark,
                children: [
                  _SwitchRow(
                    isDark: isDark,
                    icon: Icons.visibility_off_rounded,
                    iconColor: Colors.grey,
                    title: 'Sıfır-Veri Modu',
                    subtitle: 'Çeviri geçmişini hiç kaydetme',
                    value: settings.zeroDataMode,
                    onChanged: (_) => n.toggleZeroDataMode(),
                  ),
                  _Divider(isDark),
                  _SwitchRow(
                    isDark: isDark,
                    icon: Icons.cloud_sync_rounded,
                    iconColor: AppTheme.secondaryBlue,
                    title: 'Bulut Eşzamanlaması',
                    subtitle: isGuest
                        ? 'Giriş yaparak etkinleştir'
                        : 'Ayarları ve Sağlık Kartını senkronize et',
                    value: settings.cloudSyncEnabled,
                    onChanged: isGuest
                        ? (_) => context.push('/login')
                        : (_) => n.toggleCloudSync(),
                  ),
                  _Divider(isDark),
                  _ActionRow(
                    isDark: isDark,
                    icon: Icons.delete_forever_rounded,
                    iconColor: Colors.red,
                    title: 'Hesabı Sil',
                    subtitle: 'Tüm verilerini kalıcı olarak sil (GDPR/KVKK)',
                    label: 'Sil',
                    labelColor: Colors.red,
                    onTap: () => _showDeleteAccountDialog(context, isDark),
                  ),
                ],
              )
              .animate()
              .fadeIn(delay: 240.ms, duration: 350.ms)
              .slideY(begin: 0.06),

          // ── Geliştirici ────────────────────────────────────────────────────
          _SectionHeader('Geliştirici'),
          _SettingsCard(
                isDark: isDark,
                children: [
                  _SwitchRow(
                    isDark: isDark,
                    icon: Icons.developer_mode_rounded,
                    iconColor: Colors.cyanAccent,
                    title: 'Geliştirici Modu',
                    subtitle: 'Landmark noktaları + istatistik paneli',
                    value: settings.devMode,
                    onChanged: (_) => n.toggleDevMode(),
                  ),
                  if (settings.devMode) ...[
                    _Divider(isDark),
                    _LandmarkLegend(isDark: isDark),
                  ],
                ],
              )
              .animate()
              .fadeIn(delay: 280.ms, duration: 350.ms)
              .slideY(begin: 0.06),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showCacheDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        title: const Text('Önbelleği Temizle'),
        content: const Text(
          'İndirilen tüm videolar silinecek. Devam edilsin mi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Temizle',
              style: TextStyle(color: Colors.blueAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        title: const Text('Hesabı Sil'),
        content: const Text(
          'Tüm verileriniz (geçmiş, profil, sağlık kartı) kalıcı olarak silinecek. Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bölüm başlığı
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 0, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.midGrey,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ayar kartı
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children, required this.isDark});
  final List<Widget> children;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tema satırı — 3 segment
// ─────────────────────────────────────────────────────────────────────────────

class _ThemeRow extends StatelessWidget {
  const _ThemeRow({
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
          _iconBox(Icons.palette_rounded, AppTheme.secondaryBlue),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Tema',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          _SegmentButtons<ThemeMode>(
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

// ─────────────────────────────────────────────────────────────────────────────
// Metin boyutu satırı — 3 segment
// ─────────────────────────────────────────────────────────────────────────────

class _TextSizeRow extends StatelessWidget {
  const _TextSizeRow({
    required this.current,
    required this.onChanged,
    required this.isDark,
  });
  final AppTextSize current;
  final ValueChanged<AppTextSize> onChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          _iconBox(Icons.text_fields_rounded, Colors.indigoAccent),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Metin Boyutu',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 2),
                Text(
                  'Dinamik tipografi',
                  style: TextStyle(fontSize: 12, color: AppTheme.midGrey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _SegmentButtons<AppTextSize>(
            isDark: isDark,
            items: const [
              (AppTextSize.standard, 'S'),
              (AppTextSize.large, 'M'),
              (AppTextSize.extraLarge, 'L'),
            ],
            current: current,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hassasiyet eşiği satırı
// ─────────────────────────────────────────────────────────────────────────────

class _ConfidenceRow extends StatelessWidget {
  const _ConfidenceRow({
    required this.current,
    required this.onChanged,
    required this.isDark,
  });
  final ConfidenceLevel current;
  final ValueChanged<ConfidenceLevel> onChanged;
  final bool isDark;

  String get _label => switch (current) {
    ConfidenceLevel.low => 'Düşük (%70)',
    ConfidenceLevel.medium => 'Orta (%80)',
    ConfidenceLevel.high => 'Yüksek (%90)',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          _iconBox(Icons.tune_rounded, Colors.greenAccent.shade700),
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
          _SegmentButtons<ConfidenceLevel>(
            isDark: isDark,
            items: const [
              (ConfidenceLevel.low, 'Düş'),
              (ConfidenceLevel.medium, 'Ort'),
              (ConfidenceLevel.high, 'Yük'),
            ],
            current: current,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Video kalitesi satırı
// ─────────────────────────────────────────────────────────────────────────────

class _VideoQualityRow extends StatelessWidget {
  const _VideoQualityRow({
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
          _iconBox(Icons.hd_rounded, Colors.lightBlueAccent),
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
                  'İşaret video oynatma kalitesi',
                  style: TextStyle(fontSize: 12, color: AppTheme.midGrey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _SegmentButtons<VideoQuality>(
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

// ─────────────────────────────────────────────────────────────────────────────
// Genel segment buton widget
// ─────────────────────────────────────────────────────────────────────────────

class _SegmentButtons<T> extends StatelessWidget {
  const _SegmentButtons({
    required this.items,
    required this.current,
    required this.onChanged,
    required this.isDark,
  });

  final List<(T, String)> items;
  final T current;
  final ValueChanged<T> onChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: items.map((item) {
          final (value, label) = item;
          final isSelected = current == value;
          return GestureDetector(
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? AppTheme.secondaryBlue : AppTheme.primaryBlue)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white38 : Colors.black38),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Switch satırı
// ─────────────────────────────────────────────────────────────────────────────

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _iconBox(icon, iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppTheme.midGrey),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppTheme.secondaryBlue,
            inactiveThumbColor: isDark ? Colors.white38 : Colors.white,
            inactiveTrackColor: isDark ? Colors.white12 : Colors.black12,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Aksiyon satırı (butonlu)
// ─────────────────────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.label,
    required this.labelColor,
    required this.onTap,
  });

  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String label;
  final Color labelColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _iconBox(icon, iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppTheme.midGrey),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor: labelColor,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w600, color: labelColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dev mode landmark açıklaması
// ─────────────────────────────────────────────────────────────────────────────

class _LandmarkLegend extends StatelessWidget {
  const _LandmarkLegend({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kamera üzerinde gösterilen noktalar:',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : AppTheme.midGrey,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _dot(Colors.yellowAccent),
              const SizedBox(width: 6),
              const Text('Pose iskelet (11)', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 16),
              _dot(Colors.redAccent),
              const SizedBox(width: 6),
              const Text('Sağ el (21)', style: TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _dot(Colors.blueAccent),
              const SizedBox(width: 6),
              const Text('Sol el (21)', style: TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Ayırıcı
// ─────────────────────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider(this.isDark);
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 58,
      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Yardımcı
// ─────────────────────────────────────────────────────────────────────────────

Widget _iconBox(IconData icon, Color color) => Container(
  width: 36,
  height: 36,
  decoration: BoxDecoration(
    color: color.withValues(alpha: 0.15),
    borderRadius: BorderRadius.circular(10),
  ),
  child: Icon(icon, color: color, size: 18),
);
