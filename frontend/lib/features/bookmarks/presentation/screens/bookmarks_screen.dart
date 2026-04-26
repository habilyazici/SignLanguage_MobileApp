import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../dictionary/domain/entities/sign_entry.dart';
import '../../../dictionary/presentation/providers/dictionary_provider.dart';
import '../providers/bookmarks_provider.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(bookmarksProvider);
    final allSigns = ref.watch(dictionaryProvider.select((s) => s.allSigns));

    final saved = allSigns
        .where((s) => bookmarks.contains(s.id))
        .toList()
      ..sort((a, b) => a.label.compareTo(b.label));

    return Scaffold(
      backgroundColor: AppTheme.softGrey,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Üst Bar ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    color: AppTheme.textPrimary,
                    onPressed: () => context.pop(),
                  ),
                  const Spacer(),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: saved.isEmpty
                        ? const SizedBox.shrink()
                        : Container(
                            key: const ValueKey('count'),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlueTint,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.borderColor),
                            ),
                            child: Text(
                              '${saved.length} kelime',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            // ── Başlık ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Text(
                'Kaydedilenler',
                style: Theme.of(context).textTheme.displayMedium,
              ),
            ).animate().fadeIn(delay: 60.ms, duration: 300.ms),

            // ── Liste ────────────────────────────────────────────────────
            Expanded(
              child: bookmarks.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : saved.isEmpty
                      ? _EmptyState()
                      : _SavedList(signs: saved),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SavedList extends StatelessWidget {
  const _SavedList({required this.signs});
  final List<SignEntry> signs;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: signs.length,
      itemBuilder: (context, index) => _SavedCard(sign: signs[index])
          .animate()
          .fadeIn(delay: Duration(milliseconds: 40 * index), duration: 250.ms)
          .slideY(begin: 0.06, end: 0),
    );
  }
}

class _SavedCard extends ConsumerWidget {
  const _SavedCard({required this.sign});
  final SignEntry sign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        title: Text(
          sign.label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppTheme.textPrimary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                Icons.bookmark_rounded,
                color: AppTheme.primaryBlue,
                size: 20,
              ),
              onPressed: () =>
                  ref.read(bookmarksProvider.notifier).toggle(sign.id),
              visualDensity: VisualDensity.compact,
              tooltip: 'Kaydı kaldır',
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppTheme.textMuted,
            ),
          ],
        ),
        onTap: () => context.push('/dictionary/${sign.id}'),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppTheme.bgSecondary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bookmark_border_rounded,
              size: 34,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Henüz kaydedilen kelime yok',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.midGrey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sözlükten kelimeleri kaydedebilirsin.',
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
