import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            // ── Profil başlığı ────────────────────────────────────────────
            _ProfileHeader(auth: auth, isDark: isDark)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: -0.08, curve: Curves.easeOut),

            const SizedBox(height: 24),

            // ── Misafir ise giriş CTA'sı ─────────────────────────────────
            if (auth.isGuest)
              _GuestBanner(isDark: isDark)
                  .animate()
                  .fadeIn(delay: 80.ms, duration: 350.ms)
                  .slideY(begin: 0.06),

            // ── Aktif ayar özeti (giriş yapmış kullanıcılarda) ────────────
            if (auth.isAuthenticated)
              _StatusSummary(settings: settings, isDark: isDark)
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 350.ms)
                  .slideY(begin: 0.06),

            const SizedBox(height: 16),

            // ── Ayarlar ───────────────────────────────────────────────────
            Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _NavTile(
                    isDark: isDark,
                    icon: Icons.settings_rounded,
                    iconColor: AppTheme.secondaryBlue,
                    title: 'Ayarlar',
                    subtitle: 'Tema, kamera, ses, gizlilik',
                    onTap: () => context.push('/settings'),
                  ),
                )
                .animate()
                .fadeIn(delay: 180.ms, duration: 350.ms)
                .slideY(begin: 0.06),

            // ── Çıkış (sadece giriş yapılmışsa) ──────────────────────────
            if (auth.isAuthenticated) ...[
              const SizedBox(height: 10),
              Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _NavTile(
                      isDark: isDark,
                      icon: Icons.logout_rounded,
                      iconColor: Colors.orangeAccent,
                      title: 'Çıkış Yap',
                      subtitle: auth.email ?? '',
                      onTap: () => _confirmSignOut(context, ref),
                      showArrow: false,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 250.ms, duration: 350.ms)
                  .slideY(begin: 0.06),
            ],

            const SizedBox(height: 24),

            // ── Hakkında ──────────────────────────────────────────────────
            _SectionTitle('Hakkında'),
            _InfoCard(
              isDark: isDark,
            ).animate().fadeIn(delay: 300.ms, duration: 350.ms),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabından çıkmak istediğine emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).signOut();
            },
            child: const Text(
              'Çıkış Yap',
              style: TextStyle(color: Colors.orangeAccent),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profil başlığı
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.auth, required this.isDark});
  final AuthState auth;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppTheme.darkSurface, const Color(0xFF1A3055)]
              : [AppTheme.primaryBlue, AppTheme.secondaryBlue],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.15),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Center(
              child: auth.isGuest
                  ? const Icon(
                      Icons.person_outline_rounded,
                      color: Colors.white70,
                      size: 30,
                    )
                  : Text(
                      auth.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.isGuest ? 'Misafir' : (auth.displayName ?? 'Kullanıcı'),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  auth.isGuest
                      ? 'Hear Me Out — İşaret Dili Çevirisi'
                      : (auth.email ?? ''),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 12,
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

// ─────────────────────────────────────────────────────────────────────────────
// Misafir giriş CTA banner'ı
// ─────────────────────────────────────────────────────────────────────────────

class _GuestBanner extends StatelessWidget {
  const _GuestBanner({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlue.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.secondaryBlue.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.cloud_off_rounded,
                color: AppTheme.secondaryBlue,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Misafir modunda kullanıyorsun',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppTheme.secondaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Giriş yaparak ilerlemenin kaydedilmesini ve\nbulut senkronizasyonunu etkinleştir.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : AppTheme.midGrey,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push('/login'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        'Giriş Yap',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push('/register'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.secondaryBlue.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Kayıt Ol',
                        style: TextStyle(
                          color: AppTheme.secondaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Aktif ayar özeti chip'leri
// ─────────────────────────────────────────────────────────────────────────────

class _StatusSummary extends StatelessWidget {
  const _StatusSummary({required this.settings, required this.isDark});
  final AppSettings settings;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final chips = <(IconData, String, Color)>[
      if (settings.ttsEnabled)
        (Icons.volume_up_rounded, 'TTS Açık', Colors.deepOrangeAccent),
      if (settings.devMode)
        (Icons.developer_mode_rounded, 'Dev Modu', Colors.cyanAccent),
      if (settings.fpsLimitEnabled)
        (Icons.speed_rounded, '15 FPS', Colors.orangeAccent),
      if (settings.zeroDataMode)
        (Icons.visibility_off_rounded, 'Sıfır-Veri', Colors.grey),
      if (!settings.hapticEnabled)
        (Icons.vibration_rounded, 'Titreşim Kapalı', Colors.red),
    ];

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: chips.map((c) {
          final (icon, label, color) = c;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Navigasyon kartı
// ─────────────────────────────────────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showArrow = true,
  });

  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.midGrey,
                    ),
                  ),
                ],
              ),
            ),
            if (showArrow)
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: AppTheme.midGrey.withValues(alpha: 0.5),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bölüm başlığı
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 0, 8),
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
// Hakkında kartı
// ─────────────────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.isDark});
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
      child: Column(
        children: [
          _row(
            isDark,
            Icons.info_outline_rounded,
            AppTheme.midGrey,
            'Sürüm',
            'v1.0.0',
          ),
          _divider(isDark),
          _row(
            isDark,
            Icons.school_rounded,
            Colors.amber,
            'Veri Seti',
            'AUTSL · 226 işaret',
          ),
          _divider(isDark),
          _row(
            isDark,
            Icons.memory_rounded,
            AppTheme.secondaryBlue,
            'Model',
            'BiLSTM · ~637 KB',
          ),
          _divider(isDark),
          _row(
            isDark,
            Icons.accessibility_new_rounded,
            AppTheme.primaryBlue,
            'Amaç',
            'TİD → Türkçe',
          ),
        ],
      ),
    );
  }

  Widget _row(
    bool isDark,
    IconData icon,
    Color color,
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : AppTheme.midGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) => Divider(
    height: 1,
    indent: 58,
    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
  );
}
