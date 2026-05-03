import 'package:flutter_riverpod/flutter_riverpod.dart';

/// TranslationScreen'deki aktif sekme (0=İşaretten Çeviri, 1=Sesten Çeviri).
/// ScaffoldWithNav swipe sistemi ile TranslationScreen arasında paylaşılır.
final translationTabProvider =
    NotifierProvider<_TranslationTabNotifier, int>(_TranslationTabNotifier.new);

class _TranslationTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int tab) => state = tab.clamp(0, 1);
}
