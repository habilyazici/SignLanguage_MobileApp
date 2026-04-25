import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_keys.dart';
import '../../../../core/theme/app_theme.dart';

class _OnboardingPage {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String body;
  final String detailsTitle;
  final String detailsBody;

  const _OnboardingPage({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.detailsTitle,
    required this.detailsBody,
  });
}

const _pages = [
  _OnboardingPage(
    icon: Icons.videocam_rounded,
    iconColor: AppTheme.secondaryBlue,
    title: 'İşaretten Metne',
    subtitle: 'Kamera ile anlık tanıma',
    body:
        'Kamerayı açıp işaret yapmanız yeterli. Gerçek zamanlı olarak tanır ve metne dönüştürür.',
    detailsTitle: 'Kamera & Işık İpuçları',
    detailsBody:
        '• En iyi sonuç için yeterli ışıkta kullanın.\n'
        '• Ellerinizi kamera çerçevesi içinde tutun.\n'
        '• Ayarlardan haptik geri bildirimi açabilirsiniz.',
  ),
  _OnboardingPage(
    icon: Icons.sign_language_rounded,
    iconColor: AppTheme.primaryBlue,
    title: 'İşaret Anlat',
    subtitle: 'Yaz ya da sesli söyle',
    body:
        'Uygulama yazdıklarınıza veya söylediklerinize karşılık gelen işaretleri oynatır.',
    detailsTitle: 'Giriş Yöntemleri',
    detailsBody:
        '• Metin kutusuna kelime yazarak arama yapın.\n'
        '• Mikrofon butonuna basarak sesli komut verin.\n'
        '• İşaretleri yavaşlatabilir veya tekrar oynatabilirsiniz.',
  ),
  _OnboardingPage(
    icon: Icons.menu_book_rounded,
    iconColor: AppTheme.primaryStatusGreen,
    title: 'Sözlük & Profil',
    subtitle: '1500+ işaret · Offline',
    body:
        'İnternet gerektirmeden tüm işaretleri keşfedin ve bilgilerinizi kaydedin.',
    detailsTitle: 'Ek Özellikler',
    detailsBody:
        '• Acil durum mesajlarınızı tek tuşla gösterin.\n'
        '• Sağlık kartınızı oluşturup profile ekleyin.\n'
        '• Tüm veriler cihazınızda güvenle saklanır.',
  ),
];

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

  void _back() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppKeys.onboardingCompleted, true);
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLast = _currentPage == _pages.length - 1;
    final pageColor = _pages[_currentPage].iconColor;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
        color: isDark
            ? Color.lerp(AppTheme.darkBg, pageColor, 0.07)!
            : Color.lerp(AppTheme.softGrey, pageColor, 0.07)!,
        child: SafeArea(
          child: Column(
            children: [
              // ── Üst bar ──────────────────────────────────────────────────
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
                                ? pageColor
                                : (isDark ? Colors.white24 : Colors.black12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    // Atla
                    OutlinedButton(
                      onPressed: _skip,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: pageColor,
                        side: BorderSide(color: pageColor),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Atla',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Sayfa içeriği ─────────────────────────────────────────────
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, index) =>
                      _PageContent(page: _pages[index], isDark: isDark),
                ),
              ),

              // ── Alt butonlar ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Row(
                  children: [
                    // Geri — ilk sayfada görünmez
                    AnimatedOpacity(
                      opacity: _currentPage > 0 ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: IgnorePointer(
                        ignoring: _currentPage == 0,
                        child: SizedBox(
                          width: 88,
                          height: 56,
                          child: OutlinedButton(
                            onPressed: _back,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: pageColor,
                              side: BorderSide(color: pageColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text(
                              'Geri',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_currentPage > 0) const SizedBox(width: 12),
                    // İleri / Başla
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: FilledButton(
                          onPressed: _next,
                          style: FilledButton.styleFrom(
                            backgroundColor: pageColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            isLast ? 'Başla' : 'İleri',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
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

class _PageContent extends StatefulWidget {
  const _PageContent({required this.page, required this.isDark});

  final _OnboardingPage page;
  final bool isDark;

  @override
  State<_PageContent> createState() => _PageContentState();
}

class _PageContentState extends State<_PageContent> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          // İkon
          Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.page.iconColor.withValues(alpha: 0.1),
                  border: Border.all(
                    color: widget.page.iconColor.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: Icon(
                  widget.page.icon,
                  size: 64,
                  color: widget.page.iconColor,
                ),
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
                widget.page.title,
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: widget.isDark ? Colors.white : widget.page.iconColor,
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
              color: widget.page.iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.page.subtitle,
              style: TextStyle(
                fontSize: 13,
                color: widget.page.iconColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ).animate().fadeIn(delay: 250.ms, duration: 400.ms),

          const SizedBox(height: 24),

          // Açıklama
          Text(
            widget.page.body,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: widget.isDark ? Colors.white60 : AppTheme.midGrey,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 350.ms, duration: 400.ms),

          const SizedBox(height: 32),

          // ── Genişletilebilir Bilgi Alanı ───────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.page.iconColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.page.iconColor.withValues(
                    alpha: _isExpanded ? 0.3 : 0.1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.lightbulb_outline_rounded,
                        size: 18,
                        color: widget.page.iconColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isExpanded ? 'Kapat' : 'Daha Fazla Bilgi',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: widget.page.iconColor,
                        ),
                      ),
                    ],
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox(width: double.infinity),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.page.detailsTitle,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: widget.isDark
                                  ? Colors.white
                                  : widget.page.iconColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.page.detailsBody,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: widget.isDark
                                  ? Colors.white70
                                  : AppTheme.midGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    crossFadeState: _isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 450.ms, duration: 400.ms),
        ],
      ),
    );
  }
}
