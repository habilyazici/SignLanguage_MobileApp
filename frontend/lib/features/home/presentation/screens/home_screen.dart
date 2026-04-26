import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/presentation/widgets/app_logo.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dictionary/presentation/providers/dictionary_provider.dart';
import '../providers/home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final isGuest = auth.isGuest;
    final dailyWord = ref.watch(dailyWordProvider);
    final displayName = auth.displayName ?? auth.email?.split('@').first ?? 'Kullanıcı';
    final dictCount = ref.watch(dictionaryProvider.select((s) => s.allSigns.length));

    String getGreeting() {
      final hour = DateTime.now().hour;
      if (hour >= 5 && hour < 12) return 'Günaydın';
      if (hour >= 12 && hour < 17) return 'Tünaydın';
      if (hour >= 17 && hour < 22) return 'İyi Akşamlar';
      return 'İyi Geceler';
    }

    String capitalize(String s) {
      if (s.isEmpty) return s;
      return s[0].toUpperCase() + s.substring(1).toLowerCase();
    }

    final greeting = getGreeting();
    final name = capitalize(displayName);

    return Scaffold(
      backgroundColor: AppTheme.softGrey,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),

              // ── Üst Bar ───────────────────────────────────────────────
              Row(
                children: [
                  AppLogo(height: 72),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.go('/profile'),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        size: 18,
                        color: AppTheme.midGrey,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 350.ms),

              const SizedBox(height: 8),

              // ── Karşılama ─────────────────────────────────────────────
              Text(
                isGuest ? '$greeting!' : '$greeting, $name!',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  height: 1.1,
                ),
              ).animate().fadeIn(delay: 80.ms, duration: 350.ms).slideY(begin: -0.1, end: 0),
              const SizedBox(height: 4),
              Text(
                'Bugün ne öğrenmek istersin?',
                style: Theme.of(context).textTheme.bodyMedium,
              ).animate().fadeIn(delay: 120.ms, duration: 350.ms),

              const SizedBox(height: 24),

              // ── Günün İşareti ──────────────────────────────────────────
              _DailyWordCard(wordId: dailyWord.id, word: dailyWord.word)
                  .animate()
                  .fadeIn(delay: 160.ms, duration: 400.ms)
                  .slideY(begin: 0.08, end: 0),

              const SizedBox(height: 28),

              // ── Hızlı Erişim ──────────────────────────────────────────
              Text(
                'Hızlı Erişim',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
              const SizedBox(height: 12),

              // Büyük birincil kart — Çeviri (kamera + metin modlarını kapsar)
              _PrimaryQuickCard(
                title: 'Çeviri',
                subtitle: 'Kamera veya metin ile işaret dili çevirisi',
                icon: Icons.camera_alt_rounded,
                tag: 'CANLI · AI',
                onTap: () => context.go('/translation'),
              ).animate().fadeIn(delay: 240.ms, duration: 400.ms).slideY(begin: 0.08, end: 0),

              const SizedBox(height: 12),

              // Sözlük — tam genişlik (daha ince ve açıklayıcı)
              _SecondaryQuickCard(
                title: 'İşaret Sözlüğü',
                subtitle: dictCount > 0 
                  ? '$dictCount farklı işareti ve yapılışını keşfet' 
                  : 'Tüm işaretlerin listesine göz at ve öğren',
                icon: Icons.menu_book_rounded,
                color: const Color(0xFF7C4DFF),
                onTap: () => context.go('/dictionary'),
              ).animate().fadeIn(delay: 290.ms, duration: 350.ms).slideY(begin: 0.08, end: 0),

              const SizedBox(height: 20),

              // ── Üyelik Bannerı (en altta — içerik önce, çağrı sonra) ──
              if (isGuest)
                _AuthBanner()
                    .animate()
                    .fadeIn(delay: 340.ms, duration: 350.ms)
              else
                _ProgressBanner()
                    .animate()
                    .fadeIn(delay: 340.ms, duration: 350.ms),

              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DailyWordCard extends StatelessWidget {
  const _DailyWordCard({required this.wordId, required this.word});
  final int wordId;
  final String word;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/dictionary/$wordId'),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0046AF), Color(0xFF005CE1)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // ── Dekoratif arka plan daireleri ─────────────────────────────
              Positioned(
                right: -24,
                top: -24,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
              Positioned(
                right: 20,
                bottom: -30,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              // ── İçerik ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.auto_awesome, color: Colors.white70, size: 14),
                              SizedBox(width: 6),
                              Text(
                                'GÜNÜN İŞARETİ',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white70,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '"$word"',
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Nasıl yapıldığını öğrenmek için dokun',
                            style: TextStyle(fontSize: 12, color: Colors.white60),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.waving_hand_rounded, color: Colors.white, size: 26),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _AuthBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/login'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlueTint,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_circle_rounded, color: AppTheme.primaryBlue, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'İlerlemeni Kaydet',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  Text(
                    'Hemen kayıt ol veya giriş yap.',
                    style: TextStyle(fontSize: 12, color: AppTheme.midGrey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.primaryBlue),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ProgressBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.primaryStatusGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryStatusGreen.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryStatusGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: AppTheme.primaryStatusGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Harika Gidiyorsun!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Bugünkü hedeflerini tamamla.',
                  style: TextStyle(fontSize: 12, color: AppTheme.midGrey),
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
// Büyük birincil eylem kartı
// ─────────────────────────────────────────────────────────────────────────────

class _PrimaryQuickCard extends StatelessWidget {
  const _PrimaryQuickCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tag,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String tag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          // Koyu indigo/violet — mavi Günün İŞareti kartından net ayrışır.
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E1B4B), Color(0xFF4338CA)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF4338CA).withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // ── Dekoratif arka plan daireleri ─────────────────────────────
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                right: 50,
                bottom: -35,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),
              // ── İçerik ──────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Başla',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF4338CA),
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: Color(0xFF4338CA),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.13),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 34),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// İkincil kart
// ─────────────────────────────────────────────────────────────────────────────

class _SecondaryQuickCard extends StatelessWidget {
  const _SecondaryQuickCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppTheme.midGrey),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.5), size: 20),
          ],
        ),
      ),
    );
  }
}
