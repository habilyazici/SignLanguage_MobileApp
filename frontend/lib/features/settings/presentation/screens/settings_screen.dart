import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_dialogs.dart';
import '../widgets/settings_rows.dart';
import '../widgets/settings_widgets.dart';

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
          const SettingsSection('Genel Cihaz & Görünüm'),
          SettingsCard(
            isDark: isDark,
            children: [
              ThemeRow(
                current: settings.themeMode,
                onChanged: n.setThemeMode,
                isDark: isDark,
              ),
              SettingsDivider(isDark: isDark),
              TextSizeRow(
                current: settings.textSize,
                onChanged: n.setTextSize,
                isDark: isDark,
              ),
              SettingsDivider(isDark: isDark),
              SettingsSwitchRow(
                isDark: isDark,
                icon: Icons.back_hand_rounded,
                iconColor: const Color(0xFF7C4DFF),
                title: 'Solak Modu',
                subtitle: 'Kamera deklanşörünü sola hizalar',
                value: settings.leftHandMode,
                helpText:
                    'Uygulama arayüzündeki butonların ve deklanşörün yerleşimini sol elle kullanıma uygun hale getirir.',
                onChanged: (_) => n.toggleLeftHandMode(),
              ),
            ],
          ).animate().fadeIn(delay: 60.ms, duration: 350.ms).slideY(begin: 0.06),

          // ── Ses ───────────────────────────────────────────────────────────
          const SettingsSection('Ses'),
          SettingsCard(
            isDark: isDark,
            children: [
              SettingsSwitchRow(
                isDark: isDark,
                icon: Icons.volume_up_rounded,
                iconColor: Colors.deepOrangeAccent,
                title: 'Sesli Okuma (TTS)',
                subtitle: 'Tanınan kelimeyi Türkçe seslendir',
                value: settings.ttsEnabled,
                helpText:
                    'Text-to-Speech teknolojisi ile AI\'nın çevirdiği metni cihaz hoparlöründen sesli olarak duymanızı sağlar.',
                onChanged: (_) => n.toggleTts(),
              ),
              SettingsDivider(isDark: isDark),
              SettingsSwitchRow(
                isDark: isDark,
                icon: Icons.mic_rounded,
                iconColor: Colors.pinkAccent,
                title: 'Sesli Giriş (STT)',
                subtitle: 'Metin→İşaret ekranında mikrofon',
                value: settings.sttEnabled,
                helpText:
                    'Speech-to-Text teknolojisi ile kendi sesinizi metne dönüştürüp işaret dili animasyonlarını tetiklemenizi sağlar.',
                onChanged: (_) => n.toggleStt(),
              ),
            ],
          ).animate().fadeIn(delay: 160.ms, duration: 350.ms).slideY(begin: 0.06),

          // ── Veri Kullanımı & Video ─────────────────────────────────────────
          const SettingsSection('Veri Kullanımı & Video'),
          SettingsCard(
            isDark: isDark,
            children: [
              SettingsSwitchRow(
                isDark: isDark,
                icon: Icons.data_usage_rounded,
                iconColor: Colors.blueAccent,
                title: 'Mobil Veride Videoyu Kapat',
                subtitle: 'Eğitim videolarını sadece Wi-Fi ile yükle',
                value: settings.cellularVideoDisabled,
                helpText:
                    'İnternet paketinizi korumak için sözlükteki öğretici videoların mobil veri üzerinden indirilmesini engeller.',
                onChanged: (_) => n.toggleCellularVideo(),
              ),
              SettingsDivider(isDark: isDark),
              VideoQualityRow(
                current: settings.videoQuality,
                onChanged: n.setVideoQuality,
                isDark: isDark,
              ),
              SettingsDivider(isDark: isDark),
              SettingsActionRow(
                isDark: isDark,
                icon: Icons.cleaning_services_rounded,
                iconColor: Colors.blueAccent,
                title: 'Önbelleği Temizle',
                subtitle: 'İndirilen videoları sil',
                label: 'Temizle',
                labelColor: Colors.blueAccent,
                helpText:
                    'Cihazınızda yer açmak için daha önce indirilen öğretici videoları siler. Videolar tekrar izlendiğinde yeniden indirilir.',
                onTap: () => SettingsDialogs.showCacheDialog(context, isDark),
              ),
            ],
          ).animate().fadeIn(delay: 200.ms, duration: 350.ms).slideY(begin: 0.06),

          // ── Gizlilik & Veri Kontrolü ───────────────────────────────────────
          const SettingsSection('Gizlilik & Veri Kontrolü'),
          SettingsCard(
            isDark: isDark,
            children: [
              SettingsSwitchRow(
                isDark: isDark,
                icon: Icons.security_rounded,
                iconColor: Colors.tealAccent,
                title: 'Sıfır Veri Modu (Yerel)',
                subtitle: 'Geçmiş kaydedilmez, her şey cihazda kalır',
                value: settings.zeroDataMode,
                helpText:
                    'Maksimum gizlilik için tasarlanmıştır. Hiçbir çeviri geçmişi tutulmaz ve hiçbir veri dışarıya sızmaz.',
                onChanged: (_) => n.toggleZeroDataMode(),
              ),
              SettingsDivider(isDark: isDark),
              SettingsSwitchRow(
                isDark: isDark,
                icon: Icons.cloud_off_rounded,
                iconColor: Colors.blueGrey,
                title: 'Bulut Senkronizasyonu',
                subtitle: 'Şu an devre dışı (Yerel çalışır)',
                value: settings.cloudSyncEnabled,
                helpText:
                    'Verilerinizin farklı cihazlarda senkronize edilmesini sağlar. Şu an gizlilik gereği kapatılmıştır.',
                onChanged: isGuest
                    ? (_) => context.push('/login')
                    : (_) => n.toggleCloudSync(),
              ),
              SettingsDivider(isDark: isDark),
              SettingsActionRow(
                isDark: isDark,
                icon: Icons.delete_forever_rounded,
                iconColor: Colors.red,
                title: 'Hesabı Sil',
                subtitle: 'Tüm verilerini kalıcı olarak sil (GDPR/KVKK)',
                label: 'Sil',
                labelColor: Colors.red,
                helpText:
                    'Uygulama üzerindeki tüm varlığınızı, ayarlarınızı ve (varsa) verilerinizi sunucularımızdan tamamen temizler.',
                onTap: () =>
                    SettingsDialogs.showDeleteAccountDialog(context, isDark),
              ),
            ],
          ).animate().fadeIn(delay: 240.ms, duration: 350.ms).slideY(begin: 0.06),

          // ── İleri Seviye (Geliştirici) ─────────────────────────────────────
          const SettingsSection('İleri Seviye (Geliştirici)'),
          SettingsCard(
            isDark: isDark,
            children: [
              SettingsSwitchRow(
                isDark: isDark,
                icon: Icons.precision_manufacturing_rounded,
                iconColor: Colors.cyanAccent,
                title: 'Geliştirici Ayarlarını Etkinleştir',
                subtitle: 'Yapay Zeka ayarları ile teknik detayları yönet',
                value: settings.devMode,
                helpText:
                    'Arka planda gelişmiş Yapay Zeka ayarları panelini açar ve kamera ekranında anlık teknik istatistikleri görmenizi sağlar.',
                onChanged: (_) => n.toggleDevMode(),
              ),
              if (settings.devMode) ...[
                SettingsDivider(isDark: isDark),
                ConfidenceRow(
                  current: settings.confidenceLevel,
                  onChanged: n.setConfidenceLevel,
                  isDark: isDark,
                ),
                SettingsDivider(isDark: isDark),
                StabilityRow(
                  isDark: isDark,
                  current: settings.stableFramesThreshold,
                  onChanged: n.setStableFramesThreshold,
                ),
                SettingsDivider(isDark: isDark),
                FpsRow(
                  isDark: isDark,
                  current: settings.fpsPreference,
                  onChanged: n.setFpsPreference,
                ),
                SettingsDivider(isDark: isDark),
                MotionThresholdRow(
                  isDark: isDark,
                  current: settings.motionThreshold,
                  onChanged: n.setMotionThreshold,
                ),
                SettingsDivider(isDark: isDark),
                SettingsSwitchRow(
                  isDark: isDark,
                  icon: Icons.ads_click_rounded,
                  iconColor: Colors.amberAccent,
                  title: 'Hızlı Dev Butonu',
                  subtitle: 'Ana ekranda test butonu görünür',
                  value: settings.showDevButton,
                  helpText:
                      'Ana ekranda hızlı testler yapabileceğiniz "DEV" ikonunu etkinleştirir.',
                  onChanged: (_) => n.toggleShowDevButton(),
                ),
                SettingsDivider(isDark: isDark),
                LandmarkLegend(isDark: isDark),
              ],
            ],
          ).animate().fadeIn(delay: 280.ms, duration: 350.ms).slideY(begin: 0.06),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
