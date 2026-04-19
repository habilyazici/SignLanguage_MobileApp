import '../../../../../core/domain/repositories/label_repository.dart';
import '../../domain/entities/sign_entry.dart';

/// LabelRepository üzerinden zaten yüklü olan etiketleri okur.
class DictionaryLocalDatasource {
  const DictionaryLocalDatasource(this._labels);

  final LabelRepository _labels;

  List<SignEntry> readAll() => _labels
      .getAllEntries()
      .map((e) => SignEntry(id: e.$1, label: e.$2))
      .toList();
}
