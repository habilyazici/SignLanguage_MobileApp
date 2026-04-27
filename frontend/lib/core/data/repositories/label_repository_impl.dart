import '../../domain/repositories/label_repository.dart';
import '../../utils/label_mapper.dart';

class LabelRepositoryImpl implements LabelRepository {
  const LabelRepositoryImpl(this._mapper);
  final LabelMapper _mapper;

  @override
  String getTrWord(int index) => _mapper.getTrWord(index);

  @override
  int get count => _mapper.count;

  @override
  List<(int, String)> getAllEntries() => _mapper.getAllEntries();
}
