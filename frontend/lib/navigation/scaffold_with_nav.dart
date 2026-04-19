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
    if (location.startsWith('/dictionary')) {
      return 0;
    }
    if (location.startsWith('/live-translation')) {
      return 1;
    }
    if (location.startsWith('/home')) {
      return 2;
    }
    if (location.startsWith('/text-to-sign')) {
      return 3;
    }
    if (location.startsWith('/profile')) {
      return 4;
    }
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
      bottomNavigationBar: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Menünün daha iyi oturması için alt kısma hafif bir gölge gradyanı
          IgnorePointer(
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          _buildGlassBottomNav(context, ref, isDark),
        ],
      ),
    );
  }

  Widget _buildGlassBottomNav(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
  ) {
    final currentIndex = _calculateSelectedIndex(context);
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: bottomPadding > 0 ? bottomPadding : 24,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            height: 84,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: (isDark ? AppTheme.darkSurface : Colors.white).withValues(
                alpha: isDark ? 0.35 : 0.45,
              ),
              borderRadius: BorderRadius.circular(35),
              border: Border.all(
                color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _NavBarItem(
                    icon: Icons.menu_book_rounded,
                    label: 'Sözlük',
                    isSelected: currentIndex == 0,
                    onTap: () => _onTap(context, ref, 0),
                  ),
                ),
                Expanded(
                  child: _NavBarItem(
                    icon: Icons.visibility_rounded,
                    label: 'İşaret Oku',
                    isSelected: currentIndex == 1,
                    onTap: () => _onTap(context, ref, 1),
                  ),
                ),
                Expanded(
                  child: _NavBarItem(
                    icon: Icons.home_rounded,
                    label: 'Keşfet',
                    isSelected: currentIndex == 2,
                    onTap: () => _onTap(context, ref, 2),
                    isHomeButton: true,
                  ),
                ),
                Expanded(
                  child: _NavBarItem(
                    icon: Icons.sign_language_rounded,
                    label: 'İşaret Anlat',
                    isSelected: currentIndex == 3,
                    onTap: () => _onTap(context, ref, 3),
                  ),
                ),
                Expanded(
                  child: _NavBarItem(
                    icon: Icons.person_rounded,
                    label: 'Profil',
                    isSelected: currentIndex == 4,
                    onTap: () => _onTap(context, ref, 4),
                  ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = AppTheme.secondaryBlue;
    final inactiveColor = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : AppTheme.primaryBlue.withValues(alpha: 0.45);

    // Ana sayfa özel tasarım
    if (isHomeButton) {
      final bgColor = isSelected
          ? AppTheme.primaryBlue
          : AppTheme.secondaryBlue;
      return Tooltip(
        message: label,
        preferBelow: false,
        verticalOffset: 48,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: bgColor.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 26),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Normal butonlar — her zaman etiket göster
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
              // Seçim göstergesi nokta
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
