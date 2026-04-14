# 🧠 HEAR ME OUT — Yapay Zeka (AI/ML) Spesifikasyonu

## 1. Veri ve Model Yapısı
- **Dataset:** AUTSL (Ankara Üniversitesi Türk İşaret Dili), ~36.302 video.
- **Sınıf (Kelime) Sayısı:** 226 sınıf.
- **Girdi Formatı:** Videodan çıkarılan `(batch_size, 60_frames, 106_features)` koordinat dizesi.
- **Model Boyutu:** ~587 KB (TFLite Dynamic Range INT8 Quantization).
- **Inference Pipeline:** `tflite_flutter` vasıtasıyla on-device.

## 2. Landmark (Özellik) Çıkarımı
Mobil tarafta **MediaPipe Holistic** kullanılarak piksel boyutundan bağımsız 106 koordinat değeri x,y cinsinden çekilir.

| Bölge      | Landmark Sayısı | x, y Değer |
|------------|-----------------|------------|
| Sağ El     | 21              | 42         |
| Sol El     | 21              | 42         |
| Pose (Üst) | 11              | 22         |
| **TOPLAM** | **53 Nokta**    | **106 Val**|

## 3. Sliding Window (Zaman Çizelgesi) Özeti
Görüntü akışı doğrudan prediction modeline atılmaz, kayan bir pencere kuyruğuna alınır.

- **Window Size:** 60 kare (30fps = 2 saniye). 
- **Stride (Canlı):** 5 kare. 
- **Yöntem:** FIFO buffer. Her 5 frame'de model `(1, 60, 106)` ile TFLite Inference çalıştırır. Padded veya Sampled yapıda veriler buffer edilir.

## 4. Model Mimarisi (Keras)
(Bidirectional LSTM + Self-Attention)
1. LayerNormalization
2. BiLSTM (128) -> BatchNormalization -> Dropout(0.4)
3. BiLSTM (64) -> BatchNormalization -> Dropout(0.4)
4. Custom SelfAttention Layer
5. Dense (256) -> BatchNormalization -> Dropout(0.3)
6. Dense (128) -> BatchNormalization
7. Dense (226, Softmax) -> `Output: Confidence + Sınıf Indexi`

## 5. Confidence (Güven) Eşik Standardı
TFLite'dan çıkan güven skorunun (confidence) app statelerine göre standartlaşması:

| Seviye | Aralık | UI Renk / State | 
|--------|--------|-----------------|
| **Yüksek** | `≥ %90` | Yeşil (Haptic Feedback) |
| **Orta**   | `%80 – %89.9` | Sarı | 
| **Düşük**  | `%70 – %79.9` | Kırmızı (Uyarı İkonu) |
| **Garbage**| `< %70` | Reject / Belirsiz. State UI'a pushlanmaz. |

## 6. Kritik Normalizasyon Kuralı (Dart-Python Uyum Zorunluluğu)
Model eğitilirken Python'da uygulanan ölçeklendirme mantığı, mobil uygulamada Canlı stream esnasında aynen Dart içinde de uygulanmalıdır:
1. Sağ/sol el `(x, y)` değerleri bilek noktasına (wrist_x, wrist_y) bağlanıp merkezlenir.
2. Pose verileri burun referansıyla merkezlenir.
3. Bulunan değerler array `max(abs) + 1e-6`'e bölünerek Float array'e normalize edilir.
