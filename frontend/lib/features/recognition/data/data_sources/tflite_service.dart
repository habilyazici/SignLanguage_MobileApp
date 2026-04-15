import 'package:tflite_flutter/tflite_flutter.dart';

class TFLiteService {
  Interpreter? _interpreter;

  /// Modeli ilk seferde asenkron olarak güvenli şekilde yükler.
  Future<void> initModel() async {
    try {
      // INT8 Quantization modeli uygulamanın paketlenmiş assets kanalından yükleniyor
      _interpreter = await Interpreter.fromAsset(
        'assets/models/sign_language_model.tflite',
      );
      print(
        '✅ TFLite Modeli "sign_language_model.tflite" başarıyla Cihazın RAM\'ine alındı.',
      );

      // Modelin giriş ve çıkış tensor bilgilerini konsola basarak emin olun (Kontrol amaçlı)
      var inputShape = _interpreter?.getInputTensor(0).shape;
      var outputShape = _interpreter?.getOutputTensor(0).shape;
      print('ℹ️ TFLite Giriş Şekli (Input Shape): $inputShape');
      print('ℹ️ TFLite Çıkış Şekli (Output Shape): $outputShape');
    } catch (e) {
      print('🚨 TFLite Modeli yüklenirken Kiritik Hata oluştu: $e');
    }
  }

  bool _hasLoggedMissingModel = false;

  /// Kameradan/MediaPipe'tan akan koordinat paketini alır ve yapay zekaya yedirip çıkış döndürür.
  /// Beklenen Input Şekli: batch_size, 60 sekans, her sekansta 106 koordinat -> [1, 60, 106]
  List<double>? predict(List<List<List<double>>> sequenceFrames) {
    if (_interpreter == null) {
      if (!_hasLoggedMissingModel) {
        print(
          'Çıkarım (Inference) Hatası: TFLite modeli henüz hazır değil (Veya assets klasöründe yok)!',
        );
        _hasLoggedMissingModel = true;
      }
      return null;
    }

    // Çıkış buffer'ını hazırla: Modelimiz Türk İşaret Dilinde "226" sınıf ihtimali hesaplayacak.
    // Şekli: [1_batch, 226_sınıf]
    var outputBuffer = List.generate(1, (index) => List.filled(226, 0.0));

    try {
      _interpreter?.run(sequenceFrames, outputBuffer);
      // İlk (ve tek) işlemi array/list olarak geri döndürüyoruz
      return outputBuffer[0];
    } catch (e) {
      print('ML Tahmin Çıkarımı sırasında hata: $e');
      return null;
    }
  }

  /// Servis kapatılırken RAM'i temizle ve Interpreter yükünü serbest bırak.
  void close() {
    _interpreter?.close();
  }
}
