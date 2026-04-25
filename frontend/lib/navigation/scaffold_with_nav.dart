import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/camera_lifecycle_provider.dart';

class ScaffoldWithNav extends ConsumerWidget {
  final Widget child;

  const ScaffoldWithNav({super.key, required this.child});

  // 0=Anasayfa  1=Sözlük  2=Çeviri  3=Geçmiş  4=Profil
  static const _tabRoutes = [
    '/home',
    '/dictionary',
    '/translation',
    '/gecmis',
    '/profile',
  ];

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home'))        return 0;
    if (location.startsWith('/dictionary'))  return 1;
    if (location.startsWith('/translation')) return 2;
    if (location.startsWith('/gecmis'))      return 3;
    if (location.startsWith('/profile'))     return 4;
    return 0;
  }

  void _onTap(BuildContext context, WidgetRef ref, int index) {
    if (index != 2) {
      ref.read(cameraActiveProvider.notifier).setActive(active: false);
    }
    context.go(_tabRoutes[index]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.softGrey,
      extendBody: true,
      body: _SwipeNavWrapper(
        currentIndex: _calculateSelectedIndex(context),
        onNavigate: (index) => _onTap(context, ref, index),
        child: child,
      ),
      bottomNavigationBar: _buildBottomNav(context, ref),
    );
  }

  Widget _buildBottomNav(BuildContext context, WidgetRef ref) {
    final currentIndex = _calculateSelectedIndex(context);
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // ── 4 normal tab ──────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _NavItem(
                      icon: Icons.home_rounded,
                      label: 'Anasayfa',
                      isSelected: currentIndex == 0,
                      onTap: () => _onTap(context, ref, 0),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.menu_book_rounded,
                      label: 'Sözlük',
                      isSelected: currentIndex == 1,
                      onTap: () => _onTap(context, ref, 1),
                    ),
                  ),
                  // Merkez kamera butonu için boşluk
                  const Expanded(child: SizedBox()),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.history_rounded,
                      label: 'Geçmiş',
                      isSelected: currentIndex == 3,
                      onTap: () => _onTap(context, ref, 3),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.person_rounded,
                      label: 'Profil',
                      isSelected: currentIndex == 4,
                      onTap: () => _onTap(context, ref, 4),
                    ),
                  ),
                ],
              ),

              // ── Merkez yükseltilmiş kamera butonu ────────────────────
              Positioned(
                top: -(bottomPadding > 0 ? 20.0 : 24.0),
                child: GestureDetector(
                  onTap: () => _onTap(context, ref, 2),
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0046AF), Color(0xFF005CE1)],
                      ),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      currentIndex == 2
                          ? Icons.camera_alt_rounded
                          : Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
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
// Swipe ile sekmeler arası geçiş (kamera sekmesinde devre dışı)
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
    if (currentIndex == 2) return child;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity;
        if (v == null) return;
        // index 2 (kamera) swipe'la atlanır: 1→3, 3→1
        if (v > _threshold && currentIndex > 0) {
          final prev = currentIndex == 3 ? 1 : currentIndex - 1;
          onNavigate(prev);
        } else if (v < -_threshold && currentIndex < 4) {
          final next = currentIndex == 1 ? 3 : currentIndex + 1;
          onNavigate(next);
        }
      },
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppTheme.primaryBlue : AppTheme.textMuted;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: color,
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
