import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/camera_lifecycle_provider.dart';

class ScaffoldWithNav extends ConsumerWidget {
  final Widget child;

  const ScaffoldWithNav({super.key, required this.child});

  // Görsel soldan-sağa sırayla eşleşen index → rota tablosu:
  // 0=AnaSayfa  1=Sözlük  2=Çeviri  3=Favoriler  4=Profil
  static const _tabRoutes = [
    '/home',
    '/dictionary',
    '/translation',
    '/favorites',
    '/profile',
  ];

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/dictionary')) return 1;
    if (location.startsWith('/translation')) return 2;
    if (location.startsWith('/favorites')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, WidgetRef ref, int index) {
    // index 2 = Çeviri (kamera alt sekmesi olan İşaret Oku).
    // TranslationScreen kendi alt sekme durumuna göre kamerayı yönetir;
    // diğer sekmelerden gelindiğinde kamerayı kapattığımızdan emin oluruz.
    if (index != 2) {
      ref.read(cameraActiveProvider.notifier).setActive(active: false);
    }
    context.go(_tabRoutes[index]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [AppTheme.darkBg, AppTheme.gradientDeep]
                    : [AppTheme.softGrey, const Color(0xFFD6E2F0)],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: _SwipeNavWrapper(
              currentIndex: _calculateSelectedIndex(context),
              onNavigate: (index) => _onTap(context, ref, index),
              child: child,
            ),
          ),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 12, right: 12, bottom: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(35),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                height: 84,
                decoration: BoxDecoration(
                  color: (isDark ? AppTheme.darkSurface : Colors.white)
                      .withValues(alpha: isDark ? 0.35 : 0.45),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _NavBarItem(
                        icon: Icons.home_rounded,
                        label: 'Ana Sayfa',
                        isSelected: _calculateSelectedIndex(context) == 0,
                        onTap: () => _onTap(context, ref, 0),
                      ),
                    ),
                    Expanded(
                      child: _NavBarItem(
                        icon: Icons.menu_book_rounded,
                        label: 'Sözlük',
                        isSelected: _calculateSelectedIndex(context) == 1,
                        onTap: () => _onTap(context, ref, 1),
                      ),
                    ),
                    Expanded(
                      child: Transform.translate(
                        offset: const Offset(0, -10),
                        child: GestureDetector(
                          onTap: () => _onTap(context, ref, 2),
                          behavior: HitTestBehavior.opaque,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryBlue.withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.photo_camera_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Kamera',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : AppTheme.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _NavBarItem(
                        icon: Icons.bookmark_rounded,
                        label: 'Favoriler',
                        isSelected: _calculateSelectedIndex(context) == 3,
                        onTap: () => _onTap(context, ref, 3),
                      ),
                    ),
                    Expanded(
                      child: _NavBarItem(
                        icon: Icons.person_rounded,
                        label: 'Profil',
                        isSelected: _calculateSelectedIndex(context) == 4,
                        onTap: () => _onTap(context, ref, 4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Global swipe navigation wrapper (Instagram-style)
// Swipe right (velocity > 0) → previous tab, swipe left (velocity < 0) → next tab
// ─────────────────────────────────────────────────────────────────────────────

class _SwipeNavWrapper extends StatelessWidget {
  const _SwipeNavWrapper({
    required this.currentIndex,
    required this.onNavigate,
    required this.child,
  });

  final int currentIndex;
  final void Function(int index) onNavigate;
  final Widget child;

  static const _threshold = 300.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity;
        if (v == null) return;
        if (v > _threshold && currentIndex > 0) {
          // Finger moved right → go to left tab
          onNavigate(currentIndex - 1);
        } else if (v < -_threshold && currentIndex < 4) {
          // Finger moved left → go to right tab
          onNavigate(currentIndex + 1);
        }
      },
      child: child,
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = AppTheme.secondaryBlue;
    final inactiveColor = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : AppTheme.primaryBlue.withValues(alpha: 0.45);

    return Tooltip(
      message: label,
      preferBelow: false,
      verticalOffset: 48,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? activeColor : inactiveColor,
                size: 24,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? activeColor : inactiveColor,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: isSelected ? 16 : 0,
                height: isSelected ? 3 : 0,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
