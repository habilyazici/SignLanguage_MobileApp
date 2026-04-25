import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/presentation/widgets/app_logo.dart';
import '../../domain/entities/sign_entry.dart';
import '../providers/dictionary_provider.dart';

const _kTurkishAlphabet = [
  'A','B','C','Ç','D','E','F','G','Ğ','H',
  'I','İ','J','K','L','M','N','O','Ö','P',
  'R','S','Ş','T','U','Ü','V','Y','Z',
];

class DictionaryScreen extends ConsumerStatefulWidget {
  const DictionaryScreen({super.key});

  @override
  ConsumerState<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends ConsumerState<DictionaryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _letterScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      ref.read(dictionaryProvider.notifier).setQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _letterScrollController.dispose();
    super.dispose();
  }

  void _selectLetter(String? letter) {
    _searchController.clear();
    ref.read(dictionaryProvider.notifier).setLetter(letter);
  }

  bool get _isFiltered =>
      ref.read(dictionaryProvider).selectedLetter != null ||
      _searchController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final dict = ref.watch(dictionaryProvider);

    return Scaffold(
      backgroundColor: AppTheme.softGrey,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Üst Bar ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  AppLogo(height: 22),
                  const Spacer(),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      key: ValueKey(_isFiltered ? 'filtered' : 'all'),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _isFiltered
                            ? AppTheme.primaryBlueTint
                            : AppTheme.bgSecondary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Text(
                        _isFiltered
                            ? '${dict.filteredSigns.length} / ${dict.allSigns.length}'
                            : '${dict.allSigns.length} kelime',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _isFiltered
                              ? AppTheme.primaryBlue
                              : AppTheme.midGrey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 350.ms),

            // ── Başlık ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Text(
                'İşaret Sözlüğü',
                style: Theme.of(context).textTheme.displayMedium,
              ),
            ).animate().fadeIn(delay: 60.ms, duration: 350.ms),

            // ── Arama ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Kelime ara…',
                          hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                      ),
                    ),
                    ListenableBuilder(
                      listenable: _searchController,
                      builder: (_, child) => _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18, color: AppTheme.textMuted),
                              onPressed: _searchController.clear,
                              visualDensity: VisualDensity.compact,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

            const SizedBox(height: 10),

            // ── Harf Şeridi ────────────────────────────────────────────────
            SizedBox(
              height: 44,
              child: ListView(
                controller: _letterScrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                children: [
                  _LetterChip(
                    label: 'Tümü',
                    isSelected: dict.selectedLetter == null,
                    onTap: () => _selectLetter(null),
                  ),
                  const SizedBox(width: 6),
                  for (final letter in _kTurkishAlphabet) ...[
                    _LetterChip(
                      label: letter,
                      isSelected: dict.selectedLetter == letter,
                      onTap: () => _selectLetter(letter),
                    ),
                    const SizedBox(width: 6),
                  ],
                ],
              ),
            ).animate().fadeIn(delay: 140.ms, duration: 300.ms),

            const SizedBox(height: 6),

            // ── Liste ──────────────────────────────────────────────────────
            Expanded(
              child: dict.filteredSigns.isEmpty
                  ? const _EmptyState()
                  : _SignList(signs: dict.filteredSigns),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _LetterChip extends StatelessWidget {
  const _LetterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.midGrey,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SignList extends StatelessWidget {
  const _SignList({required this.signs});
  final List<SignEntry> signs;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
      itemCount: signs.length,
      itemBuilder: (context, index) => _SignCard(sign: signs[index]),
    );
  }
}

class _SignCard extends StatelessWidget {
  const _SignCard({required this.sign});
  final SignEntry sign;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlueTint,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              sign.label.isEmpty ? '?' : sign.label[0].toUpperCase(),
              style: const TextStyle(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ),
        ),
        title: Text(
          sign.label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppTheme.textPrimary,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: AppTheme.textMuted,
        ),
        onTap: () => context.push('/dictionary/${sign.id}'),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppTheme.bgSecondary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded, size: 30, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 14),
          const Text(
            'Sonuç bulunamadı',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.midGrey),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
