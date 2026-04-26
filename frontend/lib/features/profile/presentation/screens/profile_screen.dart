import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/presentation/widgets/app_logo.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../bookmarks/presentation/providers/bookmarks_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final isGuest = auth.isGuest;
    final displayName = isGuest
        ? 'Misafir Kullanıcı'
        : (auth.displayName ?? auth.email?.split('@').first ?? 'Kullanıcı');
    final email = isGuest ? null : auth.email;
    final initials = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'M';
    final bookmarkCount = ref.watch(
      bookmarksProvider.select((s) => s.wordIds.length),
    );

    return Scaffold(
      backgroundColor: AppTheme.softGrey,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            // ── Üst Bar ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  AppLogo(height: 40),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.push('/settings'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.settings_rounded,
                            size: 15,
                            color: AppTheme.midGrey,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Ayarlar',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.midGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 350.ms),

            const SizedBox(height: 24),

            // ── Profil Kartı ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: isGuest
                      ? null
                      : const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0046AF), Color(0xFF005CE1)],
                        ),
                  color: isGuest ? Colors.white : null,
                  borderRadius: BorderRadius.circular(20),
                  border: isGuest
                      ? Border.all(color: AppTheme.borderColor)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: isGuest
                          ? Colors.black.withValues(alpha: 0.04)
                          : AppTheme.primaryBlue.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isGuest
                            ? AppTheme.primaryBlueTint
                            : Colors.white.withValues(alpha: 0.2),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: isGuest ? AppTheme.primaryBlue : Colors.white,
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
                            displayName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isGuest ? AppTheme.textPrimary : Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (email != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 13,
                                color: isGuest
                                    ? AppTheme.midGrey
                                    : Colors.white.withValues(alpha: 0.8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isGuest
                                  ? AppTheme.bgSecondary
                                  : Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isGuest
                                        ? AppTheme.textMuted
                                        : Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  isGuest ? 'Misafir' : 'Aktif Hesap',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isGuest ? AppTheme.midGrey : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 60.ms, duration: 400.ms)
                .slideY(begin: 0.06, end: 0),

            // ── İstatistikler ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                    _StatItem(
                      value: '0',
                      label: 'Çeviri',
                      icon: Icons.translate_rounded,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppTheme.borderColor,
                    ),
                    _StatItem(
                      value: '$bookmarkCount',
                      label: 'Kaydedilen',
                      icon: Icons.bookmark_rounded,
                      onTap: () => context.push('/bookmarks'),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppTheme.borderColor,
                    ),
                    _StatItem(
                      value: '0',
                      label: 'Gün Serisi',
                      icon: Icons.local_fire_department_rounded,
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 120.ms, duration: 350.ms),

            // ── Giriş CTA — sadece misafir ────────────────────────────────
            if (isGuest) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => context.push('/login'),
                        child: const Text('Giriş Yap'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => context.push('/register'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.primaryBlue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Kayıt Ol',
                          style: TextStyle(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 160.ms, duration: 350.ms),
            ],

            // ── Uygulama Bölümü ───────────────────────────────────────────
            _SectionLabel('Uygulama'),
            _Card(
              children: [
                _Tile(
                  icon: Icons.share_rounded,
                  iconColor: AppTheme.secondaryBlue,
                  title: 'Uygulamayı Paylaş',
                  onTap: () => Share.share(
                    'Hear Me Out - İşaret Dili Uygulamasını keşfet!',
                  ),
                ),
                _Divider(),
                _Tile(
                  icon: Icons.mail_rounded,
                  iconColor: AppTheme.primaryStatusYellow,
                  title: 'Bize Ulaşın',
                  onTap: () => launchUrl(
                    Uri.parse(
                      'mailto:habilyazici00@gmail.com?subject=Hear%20Me%20Out%20-%20Geri%20Bildirim',
                    ),
                  ),
                ),
                _Divider(),
                _Tile(
                  icon: Icons.help_outline_rounded,
                  iconColor: AppTheme.primaryStatusGreen,
                  title: 'Nasıl Kullanılır?',
                  onTap: () => context.push('/onboarding'),
                ),
                _Divider(),
                _Tile(
                  icon: Icons.settings_rounded,
                  iconColor: AppTheme.midGrey,
                  title: 'Ayarlar',
                  onTap: () => context.push('/settings'),
                ),
              ],
            ).animate().fadeIn(delay: 180.ms, duration: 350.ms).slideY(begin: 0.06, end: 0),

            // ── Hesap Bölümü — sadece üye ─────────────────────────────────
            if (!isGuest) ...[
              _SectionLabel('Hesap'),
              _Card(
                children: [
                  _Tile(
                    icon: Icons.edit_outlined,
                    iconColor: AppTheme.secondaryBlue,
                    title: 'Profili Düzenle',
                    onTap: () => context.push('/profile/edit'),
                  ),
                  _Divider(),
                  _Tile(
                    icon: Icons.logout_rounded,
                    iconColor: AppTheme.primaryStatusRed,
                    title: 'Çıkış Yap',
                    titleColor: AppTheme.primaryStatusRed,
                    showArrow: false,
                    onTap: () => _confirmSignOut(context, ref),
                  ),
                ],
              ).animate().fadeIn(delay: 220.ms, duration: 350.ms).slideY(begin: 0.06, end: 0),
            ],
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
        content: const Text('Hesabınızdan çıkmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryStatusRed,
            ),
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).signOut();
            },
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    this.onTap,
  });
  final String value;
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryBlue),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.midGrey),
            textAlign: TextAlign.center,
          ),
        ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);
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

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 64,
      color: Colors.black.withValues(alpha: 0.05),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
    this.titleColor,
    this.showArrow = true,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final Color? titleColor;
  final bool showArrow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: titleColor ?? AppTheme.textPrimary,
                ),
              ),
            ),
            if (showArrow)
              const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}
