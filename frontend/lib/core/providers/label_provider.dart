import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/repositories/label_repository.dart';

/// main.dart'ta [LabelRepositoryImpl] ile overrideWithValue yapılmalıdır.
final labelRepositoryProvider = Provider<LabelRepository>(
  (_) => throw UnimplementedError('labelRepositoryProvider must be overridden in main()'),
);
