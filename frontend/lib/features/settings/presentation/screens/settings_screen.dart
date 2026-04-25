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

const _kKeywords = <String, List<String>>{
  'Genel & Görünüm': [
    'tema', 'görünüm', 'açık', 'koyu', 'sistem', 'solak', 'metin', 'boyut', 'tipografi', 'palette',
  ],
  'Ses': [
    'ses', 'tts', 'sesli okuma', 'stt', 'mikrofon', 'konuşma', 'hoparlör', 'text', 'speech',
  ],
  'Veri & Video': [
    'veri', 'video', 'kalite', 'önbellek', 'temizle', 'hd', '720', '360', 'mobil', 'wifi',
  ],
  'Gizlilik & Veri': [
    'gizlilik', 'güvenlik', 'bulut', 'senkronizasyon', 'yerel', 'hesap', 'sil', 'gdpr', 'kvkk',
  ],
  'İleri Seviye (Geliştirici)': [
    'geliştirici', 'ai', 'hassasiyet', 'fps', 'hareket', 'kararlılık', 'dev', 'teknik', 'yapay',
  ],
};

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
      () => setState(() => _query = _searchController.text.trim().toLowerCase()),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _visible(String section) {
    if (_query.isEmpty) return true;
    return (_kKeywords[section] ?? []).any((k) => k.contains(_query));
  }

  bool get _noResults => _kKeywords.keys.every((s) => !_visible(s));

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    final auth = ref.watch(authProvider);
    final isGuest = auth.isGuest;

    return Scaffold(
      backgroundColor: AppTheme.softGrey,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            // ── Üst Bar ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                    color: AppTheme.textPrimary,
                  ),
                  Text(
                    'Ayarlar',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 350.ms),

            const SizedBox(height: 12),

            // ── Arama ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Ayarlarda ara…',
                          hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                      ),
                    ),
                    ListenableBuilder(
                      listenable: _searchController,
                      builder: (context2, child) => _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear_rounded,
                                size: 18,
                                color: AppTheme.textMuted,
                              ),
                              onPressed: _searchController.clear,
                              visualDensity: VisualDensity.compact,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 60.ms, duration: 350.ms),

            const SizedBox(height: 16),

            // ── Boş Arama Durumu ──────────────────────────────────────────
            if (_noResults)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: AppTheme.bgSecondary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.search_off_rounded,
                        size: 28,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Ayar bulunamadı',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.midGrey,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 250.ms),

            // ── Genel & Görünüm ───────────────────────────────────────────
            if (_visible('Genel & Görünüm')) ...[
              const SettingsSection('Genel & Görünüm'),
              SettingsCard(
                isDark: false,
                children: [
                  ThemeRow(
                    current: settings.themeMode,
                    onChanged: n.setThemeMode,
                    isDark: false,
                  ),
                  SettingsDivider(isDark: false),
                  TextSizeRow(
                    current: settings.textSize,
                    onChanged: n.setTextSize,
                    isDark: false,
                  ),
                  SettingsDivider(isDark: false),
                  SettingsSwitchRow(
                    isDark: false,
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
              ).animate().fadeIn(delay: 100.ms, duration: 350.ms).slideY(begin: 0.06, end: 0),
            ],

            // ── Ses ───────────────────────────────────────────────────────
            if (_visible('Ses')) ...[
              const SettingsSection('Ses'),
              SettingsCard(
                isDark: false,
                children: [
                  SettingsSwitchRow(
                    isDark: false,
                    icon: Icons.volume_up_rounded,
                    iconColor: Colors.deepOrangeAccent,
                    title: 'Sesli Okuma (TTS)',
                    subtitle: 'Tanınan kelimeyi Türkçe seslendir',
                    value: settings.ttsEnabled,
                    helpText:
                        'Text-to-Speech teknolojisi ile AI\'nın çevirdiği metni cihaz hoparlöründen sesli olarak duymanızı sağlar.',
                    onChanged: (_) => n.toggleTts(),
                  ),
                  SettingsDivider(isDark: false),
                  SettingsSwitchRow(
                    isDark: false,
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
              ).animate().fadeIn(delay: 140.ms, duration: 350.ms).slideY(begin: 0.06, end: 0),
            ],

            // ── Veri & Video ──────────────────────────────────────────────
            if (_visible('Veri & Video')) ...[
              const SettingsSection('Veri & Video'),
              SettingsCard(
                isDark: false,
                children: [
                  SettingsSwitchRow(
                    isDark: false,
                    icon: Icons.data_usage_rounded,
                    iconColor: Colors.blueAccent,
                    title: 'Mobil Veride Videoyu Kapat',
                    subtitle: 'Eğitim videolarını sadece Wi-Fi ile yükle',
                    value: settings.cellularVideoDisabled,
                    helpText:
                        'İnternet paketinizi korumak için sözlükteki öğretici videoların mobil veri üzerinden indirilmesini engeller.',
                    onChanged: (_) => n.toggleCellularVideo(),
                  ),
                  SettingsDivider(isDark: false),
                  VideoQualityRow(
                    current: settings.videoQuality,
                    onChanged: n.setVideoQuality,
                    isDark: false,
                  ),
                  SettingsDivider(isDark: false),
                  SettingsActionRow(
                    isDark: false,
                    icon: Icons.cleaning_services_rounded,
                    iconColor: Colors.blueAccent,
                    title: 'Önbelleği Temizle',
                    subtitle: 'İndirilen videoları sil',
                    label: 'Temizle',
                    labelColor: Colors.blueAccent,
                    helpText:
                        'Cihazınızda yer açmak için daha önce indirilen öğretici videoları siler.',
                    onTap: () => SettingsDialogs.showCacheDialog(context, false),
                  ),
                ],
              ).animate().fadeIn(delay: 180.ms, duration: 350.ms).slideY(begin: 0.06, end: 0),
            ],

            // ── Gizlilik & Veri ───────────────────────────────────────────
            if (_visible('Gizlilik & Veri')) ...[
              const SettingsSection('Gizlilik & Veri'),
              SettingsCard(
                isDark: false,
                children: [
                  SettingsSwitchRow(
                    isDark: false,
                    icon: Icons.security_rounded,
                    iconColor: AppTheme.primaryStatusGreen,
                    title: 'Sıfır Veri Modu (Yerel)',
                    subtitle: 'Geçmiş kaydedilmez, her şey cihazda kalır',
                    value: settings.zeroDataMode,
                    helpText:
                        'Maksimum gizlilik için tasarlanmıştır. Hiçbir çeviri geçmişi tutulmaz.',
                    onChanged: (_) => n.toggleZeroDataMode(),
                  ),
                  SettingsDivider(isDark: false),
                  SettingsSwitchRow(
                    isDark: false,
                    icon: Icons.cloud_off_rounded,
                    iconColor: Colors.blueGrey,
                    title: 'Bulut Senkronizasyonu',
                    subtitle: 'Şu an devre dışı (Yerel çalışır)',
                    value: settings.cloudSyncEnabled,
                    helpText:
                        'Verilerinizin farklı cihazlarda senkronize edilmesini sağlar.',
                    onChanged: isGuest
                        ? (_) => context.push('/login')
                        : (_) => n.toggleCloudSync(),
                  ),
                  SettingsDivider(isDark: false),
                  SettingsActionRow(
                    isDark: false,
                    icon: Icons.delete_forever_rounded,
                    iconColor: AppTheme.primaryStatusRed,
                    title: 'Hesabı Sil',
                    subtitle: 'Tüm verilerini kalıcı olarak sil (GDPR/KVKK)',
                    label: 'Sil',
                    labelColor: AppTheme.primaryStatusRed,
                    helpText:
                        'Uygulama üzerindeki tüm varlığınızı, ayarlarınızı ve verilerinizi siler.',
                    onTap: () => SettingsDialogs.showDeleteAccountDialog(context, false),
                  ),
                ],
              ).animate().fadeIn(delay: 220.ms, duration: 350.ms).slideY(begin: 0.06, end: 0),
            ],

            // ── Geliştirici ────────────────────────────────────────────────
            if (_visible('İleri Seviye (Geliştirici)')) ...[
              const SettingsSection('İleri Seviye (Geliştirici)'),
              SettingsCard(
                isDark: false,
                children: [
                  SettingsSwitchRow(
                    isDark: false,
                    icon: Icons.precision_manufacturing_rounded,
                    iconColor: Colors.cyanAccent,
                    title: 'Geliştirici Ayarlarını Etkinleştir',
                    subtitle: 'Yapay Zeka ayarları ile teknik detayları yönet',
                    value: settings.devMode,
                    helpText: 'Arka planda gelişmiş Yapay Zeka ayarları panelini açar.',
                    onChanged: (_) => n.toggleDevMode(),
                  ),
                  if (settings.devMode) ...[
                    SettingsDivider(isDark: false),
                    ConfidenceRow(
                      current: settings.confidenceLevel,
                      onChanged: n.setConfidenceLevel,
                      isDark: false,
                    ),
                    SettingsDivider(isDark: false),
                    StabilityRow(
                      isDark: false,
                      current: settings.stableFramesThreshold,
                      onChanged: n.setStableFramesThreshold,
                    ),
                    SettingsDivider(isDark: false),
                    FpsRow(
                      isDark: false,
                      current: settings.fpsPreference,
                      onChanged: n.setFpsPreference,
                    ),
                    SettingsDivider(isDark: false),
                    MotionThresholdRow(
                      isDark: false,
                      current: settings.motionThreshold,
                      onChanged: n.setMotionThreshold,
                    ),
                    SettingsDivider(isDark: false),
                    SettingsSwitchRow(
                      isDark: false,
                      icon: Icons.ads_click_rounded,
                      iconColor: Colors.amberAccent,
                      title: 'Hızlı Dev Butonu',
                      subtitle: 'Ana ekranda test butonu görünür',
                      value: settings.showDevButton,
                      helpText:
                          'Ana ekranda hızlı testler yapabileceğiniz "DEV" ikonunu etkinleştirir.',
                      onChanged: (_) => n.toggleShowDevButton(),
                    ),
                    SettingsDivider(isDark: false),
                    LandmarkLegend(isDark: false),
                  ],
                ],
              ).animate().fadeIn(delay: 260.ms, duration: 350.ms).slideY(begin: 0.06, end: 0),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
