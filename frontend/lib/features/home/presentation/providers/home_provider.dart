import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/label_provider.dart';
import '../../data/datasources/home_local_datasource.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../domain/entities/daily_word.dart';
import '../../domain/repositories/home_repository.dart';

final _homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => HomeRepositoryImpl(
    HomeLocalDatasource(ref.watch(labelRepositoryProvider)),
  ),
);

final dailyWordProvider = Provider<DailyWord>(
  (ref) => ref.watch(_homeRepositoryProvider).getDailyWord(),
);
