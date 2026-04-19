import '../../domain/entities/daily_word.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_local_datasource.dart';

class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl(this._datasource);

  final HomeLocalDatasource _datasource;

  @override
  DailyWord getDailyWord() => _datasource.getDailyWord();
}
