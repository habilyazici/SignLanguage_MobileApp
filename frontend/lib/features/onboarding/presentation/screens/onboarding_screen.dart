import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../splash/presentation/screens/splash_screen.dart'
    show OnboardingKeys;

// ─────────────────────────────────────────────────────────────────────────────
// Onboarding slayt verisi
// ─────────────────────────────────────────────────────────────────────────────

class _OnboardingPage {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String body;

  const _OnboardingPage({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.body,
  });
}

const _pages = [
  _OnboardingPage(
    icon: Icons.back_hand_rounded,
    iconColor: AppTheme.secondaryBlue,
    title: 'İşareti Metne Çevir',
    subtitle: 'Kamera ile anlık tanıma',
    body:
        'Kamerayı açıp işaret yapmanız yeterli. '
        'Yapay zeka modelimiz 226 farklı Türk İşaret Dili kelimesini '
        'gerçek zamanlı olarak tanır ve metne dönüştürür.',
  ),
  _OnboardingPage(
    icon: Icons.sign_language_rounded,
    iconColor: AppTheme.primaryBlue,
    title: 'Metni İşarete Çevir',
    subtitle: 'Yaz ya da sesli söyle',
    body:
        'Metin giriş alanına yazın ya da mikrofon butonuna basarak '
        'sesli giriş yapın. Uygulama kelimeye karşılık gelen '
        'işaret videosunu otomatik olarak oynatır.',
  ),
  _OnboardingPage(
    icon: Icons.menu_book_rounded,
    iconColor: AppTheme.primaryStatusGreen,
    title: 'Sözlük & Profil',
    subtitle: '226 işaret · Offline çalışır',
    body:
        'Tüm işaret kelimelerini sözlükten keşfedin, '
        'acil durum mesajlarınızı kaydedin ve sağlık kartınızı oluşturun. '
        'Model tamamen cihazda çalışır — internet gerektirmez.',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Ekran
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeAndNavigate();
    }
  }

  void _skip() => _completeAndNavigate();

  Future<void> _completeAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OnboardingKeys.completed, true);
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.softGrey,
      body: SafeArea(
        child: Column(
          children: [
            // ── Üst bar: atlama ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Sayfa göstergesi (noktalar)
                  Row(
                    children: List.generate(_pages.length, (i) {
                      final active = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        width: active ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? AppTheme.secondaryBlue
                              : (isDark ? Colors.white24 : Colors.black12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  TextButton(
                    onPressed: _skip,
                    child: Text(
                      'Atla',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : AppTheme.midGrey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Sayfa içeriği ────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) =>
                    _PageContent(page: _pages[index], isDark: isDark),
              ),
            ),

            // ── Alt buton ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLast ? 'Başlayalım' : 'Devam',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isLast
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tek slayt içeriği
// ─────────────────────────────────────────────────────────────────────────────

class _PageContent extends StatelessWidget {
  const _PageContent({required this.page, required this.isDark});

  final _OnboardingPage page;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // İkon
          Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: page.iconColor.withValues(alpha: 0.1),
                  border: Border.all(
                    color: page.iconColor.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: Icon(page.icon, size: 64, color: page.iconColor),
              )
              .animate()
              .scale(
                begin: const Offset(0.7, 0.7),
                duration: 500.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 400.ms),

          const SizedBox(height: 44),

          // Başlık
          Text(
                page.title,
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.primaryBlue,
                ),
                textAlign: TextAlign.center,
              )
              .animate()
              .fadeIn(delay: 150.ms, duration: 400.ms)
              .slideY(begin: 0.1),

          const SizedBox(height: 10),

          // Alt başlık
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: page.iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              page.subtitle,
              style: TextStyle(
                fontSize: 13,
                color: page.iconColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ).animate().fadeIn(delay: 250.ms, duration: 400.ms),

          const SizedBox(height: 24),

          // Açıklama
          Text(
            page.body,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: isDark ? Colors.white60 : AppTheme.midGrey,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 350.ms, duration: 400.ms),
        ],
      ),
    );
  }
}
