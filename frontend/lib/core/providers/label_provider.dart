import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/label_repository_impl.dart';
import '../domain/repositories/label_repository.dart';

final labelRepositoryProvider = Provider<LabelRepository>(
  (_) => const LabelRepositoryImpl(),
);
