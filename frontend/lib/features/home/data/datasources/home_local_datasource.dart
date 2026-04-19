import '../../../../core/domain/repositories/label_repository.dart';
import '../../domain/entities/daily_word.dart';

/// Yıl içindeki gün sayısını seed olarak kullanarak her gün
/// farklı ama deterministik bir kelime seçer.
class HomeLocalDatasource {
  const HomeLocalDatasource(this._labels);

  final LabelRepository _labels;

  DailyWord getDailyWord() {
    final entries = _labels.getAllEntries();
    if (entries.isEmpty) return const DailyWord(id: 0, word: 'Merhaba');

    final now = DateTime.now();
    // Yılın kaçıncı günü: her gün farklı kelime, yıl başında döngü
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    final idx = dayOfYear % entries.length;
    final (id, word) = entries[idx];
    return DailyWord(id: id, word: word);
  }
}
