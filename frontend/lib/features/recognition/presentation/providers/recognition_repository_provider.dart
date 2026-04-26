import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/camera_datasource.dart';
import '../../data/datasources/inference_datasource.dart';
import '../../data/datasources/ml_pipeline_datasource.dart';
import '../../data/repositories/recognition_repository_impl.dart';
import '../../domain/repositories/recognition_repository.dart';

// ── DataSources Providers ──────────────────────────────────────────────────
final cameraDataSourceProvider = Provider((ref) => CameraDataSource());
final mlPipelineDataSourceProvider = Provider((ref) => MlPipelineDatasource());
final inferenceDataSourceProvider = Provider((ref) => InferenceDatasource());

// ── Repository Provider ───────────────────────────────────────────────────
final recognitionRepositoryProvider = Provider<RecognitionRepository>((ref) {
  return RecognitionRepositoryImpl(
    cameraDataSource: ref.watch(cameraDataSourceProvider),
    mlPipelineDataSource: ref.watch(mlPipelineDataSourceProvider),
    inferenceDataSource: ref.watch(inferenceDataSourceProvider),
  );
});
