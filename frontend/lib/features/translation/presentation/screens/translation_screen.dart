import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/providers/camera_lifecycle_provider.dart';
import '../../../../../core/providers/translation_tab_provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../recognition/presentation/screens/recognition_screen.dart';
import '../../../text_to_sign/presentation/screens/translator_screen.dart';

/// Çeviri merkezi — İşaret Oku ve İşaret Anlat modlarını içerir.
///
/// Tab geçişleri hem _ModeSelector butonlarıyla hem de ScaffoldWithNav'ın
/// swipe sistemiyle (translationTabProvider üzerinden) tetiklenebilir.
class TranslationScreen extends ConsumerStatefulWidget {
  const TranslationScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  ConsumerState<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends ConsumerState<TranslationScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialTab.clamp(0, 1);
    _tabController = TabController(length: 2, vsync: this, initialIndex: initial);
    _tabController.addListener(_onTabChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Route'tan gelen initialTab'ı provider ile senkronize et.
      ref.read(translationTabProvider.notifier).setTab(initial);
      _syncCamera(initial);
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    // Animasyon süresinde birden fazla tetiklenmeyi önle.
    if (_tabController.indexIsChanging) return;
    final newTab = _tabController.index;
    // setState gerekli: IndexedStack(index: _tabController.index) değerini
    // güncellemek için build() yeniden çağrılmalı. setState olmadan tab
    // butonları değişir ama içerik hiç değişmez.
    setState(() {});
    _syncCamera(newTab);
    // Provider'ı güncelle ki _SwipeNavWrapper sanal indeksi doğru hesaplasın.
    if (ref.read(translationTabProvider) != newTab) {
      ref.read(translationTabProvider.notifier).setTab(newTab);
    }
  }

  /// Sekme 0 = İşaret Oku → kamera açık; Sekme 1 = İşaret Anlat → kamera kapalı.
  void _syncCamera(int index) {
    ref.read(cameraActiveProvider.notifier).setActive(
      active: index == 0,
      // iOS'ta STT AVAudioSession için kamera donanımının tamamen serbest
      // bırakılması gerekir. Diğer tab geçişlerinde stream durdurulur yeterlidir.
      releaseHardware: Platform.isIOS && index != 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Swipe navigasyonundan gelen dış tab değişikliklerini dinle.
    ref.listen(translationTabProvider, (_, next) {
      if (_tabController.index != next) {
        _tabController.animateTo(next);
        // _syncCamera, animasyon bitince _onTabChanged tarafından çağrılır.
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Mod Seçici ──────────────────────────────────────────────
            _ModeSelector(controller: _tabController),

            // ── İçerik ─────────────────────────────────────────────────
            // NeverScrollableScrollPhysics: yatay swipe'lar _SwipeNavWrapper
            // tarafından yakalanır; bu sayede tab geçişi ve ekran geçişi
            // aynı gesture sistemiyle tutarlı biçimde çalışır.
            Expanded(
              child: IndexedStack(
                index: _tabController.index,
                children: const [
                  RecognitionScreen(),
                  TranslatorScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mod seçici — iki ayrı buton
// ─────────────────────────────────────────────────────────────────────────────

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerBg = isDark ? AppTheme.darkSurface : Colors.black.withValues(alpha: 0.05);
    final borderColor = isDark ? Colors.white10 : Colors.transparent;

    return Padding(
      // Genişliği biraz daha azaltmak için dış padding'i 64'e çıkardık
      padding: const EdgeInsets.fromLTRB(64, 12, 64, 6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: containerBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final index = controller.index;
            return Row(
              children: [
                Expanded(
                  child: _ModeButton(
                    label: 'İşaretten Çeviri',
                    isSelected: index == 0,
                    isLeft: true,
                    onTap: () => controller.animateTo(0),
                  ),
                ),
                Expanded(
                  child: _ModeButton(
                    label: 'Sesten Çeviri',
                    isSelected: index == 1,
                    isLeft: false,
                    onTap: () => controller.animateTo(1),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.isSelected,
    required this.isLeft,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isLeft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveText = isDark ? Colors.white60 : Colors.black54;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
          // İki butonun ortada kesiştiği yeri (iç kenarı) dikdörtgen/düz, dış kenarı yuvarlak yaptık
          borderRadius: BorderRadius.horizontal(
            left: Radius.circular(isLeft ? 12 : 0),
            right: Radius.circular(isLeft ? 0 : 12),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : inactiveText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
