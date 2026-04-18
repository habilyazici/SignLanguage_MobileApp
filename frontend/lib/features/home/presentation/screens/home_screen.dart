import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/presentation/widgets/glass_card.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final isGuest = ref.watch(authProvider).isGuest;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // ── Hero başlık ──────────────────────────────────────────────
                _HeroHeader(isDark: isDark, isGuest: isGuest)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: -0.12, end: 0, curve: Curves.easeOut),

                const SizedBox(height: 32),

                // ── Günün İşareti ────────────────────────────────────────────
                _DailyWordCard(isDark: isDark)
                    .animate()
                    .fadeIn(delay: 120.ms, duration: 400.ms)
                    .slideY(begin: 0.12, end: 0, curve: Curves.easeOut),

                const SizedBox(height: 24),

                // ── Hızlı erişim butonları ───────────────────────────────────
                Text(
                  'Hızlı Erişim',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 220.ms, duration: 300.ms),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        title: 'İşareti\nMetne Çevir',
                        icon: Icons.back_hand_rounded,
                        color: AppTheme.secondaryBlue,
                        hint: 'Sola Kaydır',
                        hintIcon: Icons.swipe_left_rounded,
                        onTap: () => context.go('/live-translation'),
                      )
                          .animate()
                          .fadeIn(delay: 300.ms, duration: 400.ms)
                          .scale(
                            begin: const Offset(0.92, 0.92),
                            end: const Offset(1, 1),
                            curve: Curves.easeOutBack,
                          ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _ActionCard(
                        title: 'Metni\nİşarete Çevir',
                        icon: Icons.sign_language_rounded,
                        color: AppTheme.primaryBlue,
                        hint: 'Sağa Kaydır',
                        hintIcon: Icons.swipe_right_rounded,
                        onTap: () => context.go('/text-to-sign'),
                      )
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 400.ms)
                          .scale(
                            begin: const Offset(0.92, 0.92),
                            end: const Offset(1, 1),
                            curve: Curves.easeOutBack,
                          ),
                    ),
                  ],
                ),

                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero başlık — logo büyük, karşılama metni hemen altında
// ─────────────────────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.isDark, required this.isGuest});
  final bool isDark;
  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? AppTheme.darkSurface
                : AppTheme.primaryBlue.withValues(alpha: 0.08),
            border: Border.all(
              color: isDark
                  ? AppTheme.secondaryBlue.withValues(alpha: 0.3)
                  : AppTheme.primaryBlue.withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/logo.png',
              width: 80,
              height: 80,
              fit: BoxFit.contain,
              errorBuilder: (ctx, err, st) => Icon(
                Icons.hearing,
                size: 44,
                color: isDark ? AppTheme.secondaryBlue : AppTheme.primaryBlue,
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
                'Hear Me Out',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.primaryBlue,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hoş Geldin! 👋',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : AppTheme.midGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Bugün ne öğrenmek istersin?',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white38 : AppTheme.midGrey,
                ),
              ),
            ],
          ),
        ),
        // Misafir login pill
        if (isGuest)
          GestureDetector(
            onTap: () => context.push('/login'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.secondaryBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.secondaryBlue.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.login_rounded,
                      size: 14, color: AppTheme.secondaryBlue),
                  const SizedBox(width: 5),
                  Text(
                    'Giriş Yap',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.secondaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Günün İşareti kartı
// ─────────────────────────────────────────────────────────────────────────────

class _DailyWordCard extends StatelessWidget {
  const _DailyWordCard({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 20,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppTheme.primaryStatusYellow, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Günün İşareti',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '"Merhaba"',
                  style: GoogleFonts.poppins(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryStatusGreen,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'İşaret dilinde temel selamlama.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryStatusGreen.withValues(alpha: 0.12),
            ),
            child: const Icon(
              Icons.waving_hand_rounded,
              color: AppTheme.primaryStatusGreen,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hızlı erişim kartı
// ─────────────────────────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.hint,
    required this.hintIcon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String hint;
  final IconData hintIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
        borderRadius: 20,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 15,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(hintIcon, size: 14, color: color.withValues(alpha: 0.7)),
                const SizedBox(width: 4),
                Text(
                  hint,
                  style: TextStyle(
                    fontSize: 11,
                    color: color.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
