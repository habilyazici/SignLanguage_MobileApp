import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';

class ScaffoldWithNav extends StatelessWidget {
  final Widget child;

  const ScaffoldWithNav({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/live-translation'))
      return 0; // İşaretten Metne (Sol 1)
    if (location.startsWith('/dictionary')) return 1; // Sözlük (Sol 2)
    if (location.startsWith('/home')) return 2; // Ana Sayfa (Orta)
    if (location.startsWith('/text-to-sign'))
      return 3; // Metinden İşarete (Sağ 1)
    if (location.startsWith('/profile')) return 4; // Profilim (Sağ 2)
    return 2;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/live-translation');
        break;
      case 1:
        context.go('/dictionary');
        break;
      case 2:
        context.go('/home');
        break;
      case 3:
        context.go('/text-to-sign');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    ? [AppTheme.darkBg, const Color(0xFF162544)]
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
                color: AppTheme.secondaryBlue.withOpacity(0.3),
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
                color: AppTheme.primaryBlue.withOpacity(0.2),
              ),
            ),
          ),
          SafeArea(bottom: false, child: child),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: _buildGlassBottomNav(context),
    );
  }

  Widget _buildGlassBottomNav(BuildContext context) {
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
              color: Theme.of(context).cardColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
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
                  isSelected: currentIndex == 1,
                  onTap: () => _onTap(context, 1),
                ),
                _NavBarItem(
                  icon: Icons.back_hand_rounded,
                  label: 'Kamera',
                  isSelected: currentIndex == 0,
                  onTap: () => _onTap(context, 0),
                ),
                _NavBarItem(
                  icon: Icons.home_rounded,
                  label: 'Ana Sayfa',
                  isSelected: currentIndex == 2,
                  onTap: () => _onTap(context, 2),
                  isHomeButton: true,
                ),
                _NavBarItem(
                  icon: Icons.sign_language_rounded,
                  label: 'Avatar',
                  isSelected: currentIndex == 3,
                  onTap: () => _onTap(context, 3),
                ),
                _NavBarItem(
                  icon: Icons.person_rounded,
                  label: 'Profil',
                  isSelected: currentIndex == 4,
                  onTap: () => _onTap(context, 4),
                ),
              ],
            ),
          ),
        ),
      ),
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
        : AppTheme.primaryBlue.withOpacity(0.6);

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
                    ? activeColor.withOpacity(0.15)
                    : Colors.transparent),
          borderRadius: isHomeButton
              ? BorderRadius.circular(30)
              : BorderRadius.circular(20),
          boxShadow: isHomeButton
              ? [
                  BoxShadow(
                    color: homeBgColor.withOpacity(0.3),
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
