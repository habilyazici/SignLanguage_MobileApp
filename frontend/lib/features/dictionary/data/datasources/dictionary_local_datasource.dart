import '../../../../../core/utils/label_mapper.dart';
import '../../domain/entities/sign_entry.dart';

/// LabelMapper'dan zaten yüklü olan etiketleri okur.
/// main.dart'ta LabelMapper.loadLabels() çağrıldıktan sonra kullanılabilir.
class DictionaryLocalDatasource {
  List<SignEntry> readAll() => LabelMapper.getAllEntries()
      .map((e) => SignEntry(id: e.$1, label: e.$2))
      .toList();
}
