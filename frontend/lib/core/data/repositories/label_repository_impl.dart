import '../../domain/repositories/label_repository.dart';
import '../../utils/label_mapper.dart';

/// LabelMapper static sınıfını LabelRepository arayüzüne saran ince sarmalayıcı.
/// main.dart'ta LabelMapper.loadLabels() çağrıldıktan sonra kullanılabilir.
class LabelRepositoryImpl implements LabelRepository {
  const LabelRepositoryImpl();

  @override
  String getTrWord(int index) => LabelMapper.getTrWord(index);

  @override
  int get count => LabelMapper.count;

  @override
  List<(int, String)> getAllEntries() => LabelMapper.getAllEntries();
}
