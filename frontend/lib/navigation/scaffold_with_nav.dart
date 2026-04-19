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
  // 0=Sözlük  1=Kamera  2=Home(orta)  3=Avatar  4=Profil
  static const _tabRoutes = [
    '/dictionary',
    '/live-translation',
    '/home',
    '/text-to-sign',
    '/profile',
  ];

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/dictionary'))       { return 0; }
    if (location.startsWith('/live-translation')) { return 1; }
    if (location.startsWith('/home'))             { return 2; }
    if (location.startsWith('/text-to-sign'))     { return 3; }
    if (location.startsWith('/profile'))          { return 4; }
    return 2;
  }

  void _onTap(BuildContext context, WidgetRef ref, int index) {
    // index 1 = kamera ekranı; diğerleri kamerayı durdurur
    ref.read(cameraActiveProvider.notifier).setActive(active: index == 1);
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
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.secondaryBlue.withValues(alpha: 0.3),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryBlue.withValues(alpha: 0.2),
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
      bottomNavigationBar: _buildGlassBottomNav(context, ref),
    );
  }

  Widget _buildGlassBottomNav(BuildContext context, WidgetRef ref) {
    final currentIndex = _calculateSelectedIndex(context);

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _NavBarItem(
                  icon: Icons.menu_book_rounded,
                  label: 'Sözlük',
                  isSelected: currentIndex == 0,
                  onTap: () => _onTap(context, ref, 0),
                ),
                _NavBarItem(
                  icon: Icons.back_hand_rounded,
                  label: 'Kamera',
                  isSelected: currentIndex == 1,
                  onTap: () => _onTap(context, ref, 1),
                ),
                _NavBarItem(
                  icon: Icons.home_rounded,
                  label: 'Ana Sayfa',
                  isSelected: currentIndex == 2,
                  onTap: () => _onTap(context, ref, 2),
                  isHomeButton: true,
                ),
                _NavBarItem(
                  icon: Icons.sign_language_rounded,
                  label: 'Çevirmen',
                  isSelected: currentIndex == 3,
                  onTap: () => _onTap(context, ref, 3),
                ),
                _NavBarItem(
                  icon: Icons.person_rounded,
                  label: 'Profil',
                  isSelected: currentIndex == 4,
                  onTap: () => _onTap(context, ref, 4),
                ),
              ],
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
  final bool isHomeButton;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isHomeButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = AppTheme.secondaryBlue;
    final inactiveColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : AppTheme.primaryBlue.withValues(alpha: 0.6);

    // Ana sayfa butonu için özel yuvarlak arka plan ve ikon rengi ayarlaması
    final iconColor = isHomeButton
        ? Colors.white
        : (isSelected ? activeColor : inactiveColor);
    final homeBgColor = isSelected
        ? AppTheme.primaryBlue
        : AppTheme.secondaryBlue;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(
          horizontal: isHomeButton ? 16 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isHomeButton
              ? homeBgColor
              : (isSelected
                    ? activeColor.withValues(alpha: 0.15)
                    : Colors.transparent),
          borderRadius: isHomeButton
              ? BorderRadius.circular(30)
              : BorderRadius.circular(20),
          boxShadow: isHomeButton
              ? [
                  BoxShadow(
                    color: homeBgColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: isHomeButton ? 28 : 26),
            const SizedBox(height: 2),
            if (isSelected && !isHomeButton)
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: activeColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}
