import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/turkish_normalizer.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/history_item.dart';
import '../providers/history_provider.dart';

extension _TypeLabel on HistoryItemType {
  String get label => switch (this) {
        HistoryItemType.recognition => 'Tanıma',
        HistoryItemType.dictionary => 'Sözlük',
        HistoryItemType.translation => 'Çeviri',
      };
  IconData get icon => switch (this) {
        HistoryItemType.recognition => Icons.videocam_rounded,
        HistoryItemType.dictionary => Icons.menu_book_rounded,
        HistoryItemType.translation => Icons.sign_language_rounded,
      };
}

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final TextEditingController _search = TextEditingController();
  HistoryItemType? _selectedType; // null = Tümü

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final history = ref.watch(historyProvider);

    final q = TurkishNormalizer.trLower(_search.text.trim());
    final filtered = history.items.where((i) {
      if (_selectedType != null && i.type != _selectedType) return false;
      if (q.isNotEmpty && !TurkishNormalizer.trLower(i.text).contains(q)) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppTheme.darkBg
          : AppTheme.softGrey,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Başlık + Temizle ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Geçmiş',
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tanınan tüm işaretler burada kaydedilir.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  if (history.items.isNotEmpty)
                    _IconBtn(
                      icon: Icons.delete_sweep_rounded,
                      tooltip: 'Tümünü Temizle',
                      onTap: () => _confirmClearAll(context, ref),
                    ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 12),

            // ── Filtre chip'leri ─────────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Tümü',
                    icon: Icons.list_rounded,
                    selected: _selectedType == null,
                    onTap: () => setState(() => _selectedType = null),
                  ),
                  const SizedBox(width: 8),
                  ...HistoryItemType.values.map((t) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: t.label,
                      icon: t.icon,
                      selected: _selectedType == t,
                      onTap: () => setState(() => _selectedType = t),
                    ),
                  )),
                ],
              ),
            ).animate().fadeIn(delay: 80.ms, duration: 300.ms),

            const SizedBox(height: 8),

            // ── Arama ───────────────────────────────────────────────────
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
                    const Icon(Icons.search_rounded,
                        color: AppTheme.textMuted, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'Geçmişte ara…',
                          hintStyle:
                              TextStyle(color: AppTheme.textMuted, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: const TextStyle(
                            fontSize: 14, color: AppTheme.textPrimary),
                      ),
                    ),
                    if (_search.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            size: 18, color: AppTheme.textMuted),
                        onPressed: () {
                          _search.clear();
                          setState(() {});
                        },
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

            const SizedBox(height: 12),

            // ── İçerik ──────────────────────────────────────────────────
            Expanded(
              child: !auth.isAuthenticated
                  ? _GuestState()
                  : history.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : history.error != null
                          ? _ErrorState(
                              onRetry: () =>
                                  ref.read(historyProvider.notifier).retry(),
                            )
                          : filtered.isEmpty
                              ? _EmptyState(isSearch: _search.text.isNotEmpty)
                              : _HistoryList(
                                  items: filtered,
                                  isLoadingMore: history.isLoadingMore,
                                  hasMore: history.hasMore && _search.text.isEmpty && _selectedType == null,
                                  onDelete: (id) => ref
                                      .read(historyProvider.notifier)
                                      .delete(id),
                                  onLoadMore: () => ref
                                      .read(historyProvider.notifier)
                                      .loadMore(),
                                ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Geçmişi Temizle'),
        content:
            const Text('Tüm geçmiş silinecek. Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryStatusRed),
            onPressed: () {
              Navigator.pop(context);
              ref.read(historyProvider.notifier).clearAll();
            },
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _HistoryList extends StatefulWidget {
  const _HistoryList({
    required this.items,
    required this.onDelete,
    required this.onLoadMore,
    required this.isLoadingMore,
    required this.hasMore,
  });
  final List<HistoryItem> items;
  final void Function(String id) onDelete;
  final VoidCallback onLoadMore;
  final bool isLoadingMore;
  final bool hasMore;

  @override
  State<_HistoryList> createState() => _HistoryListState();
}

class _HistoryListState extends State<_HistoryList> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.hasMore || widget.isLoadingMore) return;
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: widget.items.length + (widget.isLoadingMore ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == widget.items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
          );
        }
        return _HistoryCard(
          item: widget.items[i],
          onDelete: () => widget.onDelete(widget.items[i].id),
        )
            .animate()
            .fadeIn(delay: Duration(milliseconds: 30 * i), duration: 220.ms)
            .slideY(begin: 0.05, end: 0);
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item, required this.onDelete});
  final HistoryItem item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('dd MMM, HH:mm', 'tr_TR').format(item.createdAt);

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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        title: Text(
          item.text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Row(
            children: [
              Icon(item.type.icon, size: 12, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Text(
                timeStr,
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded,
              size: 20, color: AppTheme.textMuted),
          onPressed: onDelete,
          visualDensity: VisualDensity.compact,
          tooltip: 'Sil',
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isSearch});
  final bool isSearch;

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
              color: AppTheme.primaryBlueTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_rounded,
                size: 36, color: AppTheme.primaryBlue),
          ),
          const SizedBox(height: 16),
          Text(
            isSearch ? 'Sonuç bulunamadı' : 'Henüz geçmiş yok',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.midGrey,
            ),
          ),
          if (!isSearch) ...[
            const SizedBox(height: 8),
            const Text(
              'Tanınan işaretler burada görünecek.',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _GuestState extends StatelessWidget {
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
            child: const Icon(Icons.lock_outline_rounded,
                size: 34, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 16),
          const Text(
            'Giriş Gerekli',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.midGrey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Geçmişi görmek için hesabınıza giriş yapın.',
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

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
            child: const Icon(Icons.wifi_off_rounded,
                size: 30, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 14),
          const Text(
            'Geçmiş yüklenemedi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.midGrey,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Tekrar Dene'),
            style:
                FilledButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  const _IconBtn(
      {required this.icon, required this.onTap, required this.tooltip});
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Icon(icon, size: 18, color: AppTheme.midGrey),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primaryBlue : AppTheme.borderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? Colors.white : AppTheme.midGrey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppTheme.midGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
