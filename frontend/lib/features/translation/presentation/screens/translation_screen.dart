import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/providers/camera_lifecycle_provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../recognition/presentation/screens/recognition_screen.dart';
import '../../../text_to_sign/presentation/screens/translator_screen.dart';

/// İşaret Oku ve İşaret Anlat sayfalarını tek çatı altında birleştiren ekran.
///
/// Yapı:
///   - Üstte özel segment tab çubuğu (2 sekme)
///   - Altta [TabBarView]: sağa/sola kaydırma ile sekme geçişi
///   - Kamera yaşam döngüsü: [RecognitionScreen] görünürken aktif, diğerinde kapalı
class TranslationScreen extends ConsumerStatefulWidget {
  const TranslationScreen({super.key});

  @override
  ConsumerState<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends ConsumerState<TranslationScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);

    // İlk render'dan sonra kamera durumunu belirle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncCamera(_tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _syncCamera(_tabController.index);
    }
  }

  /// Sekme 0 = İşaret Oku → kamera açık, Sekme 1 = İşaret Anlat → kamera kapalı
  void _syncCamera(int index) {
    ref.read(cameraActiveProvider.notifier).setActive(active: index == 0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TranslationTabBar(controller: _tabController, isDark: isDark),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [RecognitionScreen(), TranslatorScreen()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Özel segment tab çubuğu
// ─────────────────────────────────────────────────────────────────────────────

class _TranslationTabBar extends StatelessWidget {
  const _TranslationTabBar({required this.controller, required this.isDark});

  final TabController controller;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final index = controller.index;
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppTheme.primaryBlue.withValues(alpha: 0.07),
              ),
              child: Row(
                children: [
                  _TabItem(
                    icon: Icons.videocam_rounded,
                    label: 'İşaretten Metne',
                    isSelected: index == 0,
                    isDark: isDark,
                    onTap: () => controller.animateTo(0),
                  ),
                  _TabItem(
                    icon: Icons.sign_language_rounded,
                    label: 'Metinden İşarete',
                    isSelected: index == 1,
                    isDark: isDark,
                    onTap: () => controller.animateTo(1),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: EdgeInsets.zero,
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppTheme.secondaryBlue : AppTheme.primaryBlue)
                : Colors.transparent,
            borderRadius: BorderRadius.zero,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18, // 16'dan büyütüldü
                color: isSelected
                    ? Colors.white
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.5)
                          : AppTheme.primaryBlue.withValues(alpha: 0.6)),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14, // 13'ten büyütüldü
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.5)
                            : AppTheme.primaryBlue.withValues(alpha: 0.6)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
