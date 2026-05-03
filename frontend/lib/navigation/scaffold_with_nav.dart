import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/camera_lifecycle_provider.dart';
import '../core/providers/translation_tab_provider.dart';
import '../features/auth/presentation/providers/auth_provider.dart';

class ScaffoldWithNav extends ConsumerWidget {
  final Widget child;

  const ScaffoldWithNav({super.key, required this.child});

  static const _tabRoutes = [
    '/home',
    '/dictionary',
    '/translation',
    '/history',
    '/profile',
  ];

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home'))        return 0;
    if (location.startsWith('/dictionary'))  return 1;
    if (location.startsWith('/translation')) return 2;
    if (location.startsWith('/history'))     return 3;
    if (location.startsWith('/profile'))     return 4;
    return 0;
  }

  void _onTap(BuildContext context, WidgetRef ref, int index) {
    if (index == 2) {
      ref.read(translationTabProvider.notifier).setTab(0);
      context.go('/translation?tab=0');
    } else {
      ref.read(cameraActiveProvider.notifier).setActive(active: false);
      if (index == 4 && ref.read(authProvider).isGuest) {
        context.push('/login');
      } else {
        context.go(_tabRoutes[index]);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = _calculateSelectedIndex(context);
    final isHome = currentIndex == 0;

    return PopScope(
      canPop: isHome,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/home');
      },
      child: Scaffold(
        backgroundColor: AppTheme.softGrey,
        extendBody: true,
        body: _SwipeNavWrapper(
          currentIndex: currentIndex,
          child: child,
        ),
        bottomNavigationBar: _buildBottomNav(context, ref),
      ),
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

              Positioned(
                top: -(bottomPadding > 0 ? 24.0 : 28.0),
                child: GestureDetector(
                  onTap: () => _onTap(context, ref, 2),
                  child: Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0046AF), Color(0xFF005CE1)],
                      ),
                      border: Border.all(color: Colors.white, width: 3.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.40),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      currentIndex == 2
                          ? Icons.camera_alt_rounded
                          : Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 30,
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
// Swipe navigasyonu — 6 sanal pozisyon
//
// Sanal indeks:
//   0 = Anasayfa   1 = Sözlük   2 = İşaret Oku   3 = İşaret Anlat
//   4 = Geçmiş     5 = Profil
//
// Kamera ekranında (sanal 2 veya 3) dışarı çıkan swipe'lar çift kaydırma
// gerektirir. İlk swipe'ta hint pill gösterilir; 2 saniye içinde aynı yöne
// tekrar kaydırılırsa navigasyon gerçekleşir.
// ─────────────────────────────────────────────────────────────────────────────

class _SwipeNavWrapper extends ConsumerStatefulWidget {
  const _SwipeNavWrapper({required this.currentIndex, required this.child});

  /// GoRouter tabanlı rota indeksi (0-4).
  final int currentIndex;
  final Widget child;

  @override
  ConsumerState<_SwipeNavWrapper> createState() => _SwipeNavWrapperState();
}

class _SwipeNavWrapperState extends ConsumerState<_SwipeNavWrapper> {
  static const _velThreshold = 300.0;
  static const _confirmDuration = Duration(seconds: 2);

  int? _pendingTarget;
  Timer? _confirmTimer;

  int _effective(int routeIdx, int translationTab) {
    if (routeIdx < 2) return routeIdx;
    if (routeIdx == 2) return 2 + translationTab;
    return routeIdx + 1;
  }

  bool _isCamera(int virtual) => virtual == 2 || virtual == 3;

  String _targetLabel(int virtual) => switch (virtual) {
    0 => 'Anasayfa',
    1 => 'Sözlük',
    2 => 'İşaret Oku',
    3 => 'İşaret Anlat',
    4 => 'Geçmiş',
    _ => 'Profil',
  };

  void _navigate(int to) {
    switch (to) {
      case 0:
        ref.read(cameraActiveProvider.notifier).setActive(active: false);
        context.go('/home');
      case 1:
        ref.read(cameraActiveProvider.notifier).setActive(active: false);
        context.go('/dictionary');
      case 2:
        ref.read(translationTabProvider.notifier).setTab(0);
        if (widget.currentIndex != 2) context.go('/translation?tab=0');
      case 3:
        ref.read(translationTabProvider.notifier).setTab(1);
        if (widget.currentIndex != 2) context.go('/translation?tab=1');
      case 4:
        ref.read(cameraActiveProvider.notifier).setActive(active: false);
        context.go('/history');
      case 5:
        ref.read(cameraActiveProvider.notifier).setActive(active: false);
        if (ref.read(authProvider).isGuest) {
          context.push('/login');
        } else {
          context.go('/profile');
        }
    }
  }

  void _handleSwipe(int effective, int target) {
    // Kamera dışına çıkış → çift kaydırma gerekli
    if (_isCamera(effective) && !_isCamera(target)) {
      if (_pendingTarget == target) {
        _clearPending();
        _navigate(target);
      } else {
        _confirmTimer?.cancel();
        setState(() => _pendingTarget = target);
        _confirmTimer = Timer(_confirmDuration, () {
          if (mounted) setState(() => _pendingTarget = null);
        });
      }
    } else {
      _clearPending();
      _navigate(target);
    }
  }

  void _clearPending() {
    _confirmTimer?.cancel();
    if (_pendingTarget != null) setState(() => _pendingTarget = null);
  }

  @override
  void dispose() {
    _confirmTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translationTab = ref.watch(translationTabProvider);
    final effective = _effective(widget.currentIndex, translationTab);

    return Stack(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: (details) {
            final v = details.primaryVelocity;
            if (v == null) return;
            if (v > _velThreshold && effective > 0) {
              _handleSwipe(effective, effective - 1);
            } else if (v < -_velThreshold && effective < 5) {
              _handleSwipe(effective, effective + 1);
            }
          },
          child: widget.child,
        ),
        if (_pendingTarget != null && _isCamera(effective))
          _SwipeHint(
            label: _targetLabel(_pendingTarget!),
            isLeft: _pendingTarget! < effective,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SwipeHint extends StatelessWidget {
  const _SwipeHint({required this.label, required this.isLeft});
  final String label;
  final bool isLeft;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 110,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLeft) ...[
                const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 15),
                const SizedBox(width: 6),
              ],
              Text(
                'Tekrar kaydır · $label',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!isLeft) ...[
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 15),
              ],
            ],
          ),
        ),
      ),
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
