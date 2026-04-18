/// Recognition pipeline için domain repository arayüzü.
/// RecognitionNotifier'ın ileride buna bağlanması hedeflenir.
abstract interface class RecognitionRepository {
  Future<void> initialize();
  Future<void> pauseCamera();
  Future<void> resumeCamera();
  Future<void> switchCamera();
  Future<void> dispose();
}
