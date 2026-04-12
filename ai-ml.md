# 🧠 HEAR ME OUT — Yapay Zeka ve Makine Öğrenmesi

## 1. Genel Bakış

| Alan | Bilgi |
|------|-------|
| **Amaç** | Gerçek zamanlı, video tabanlı Türk İşaret Dili (TİD) tanıma |
| **Referans Model** | LSTM + Multi-Head Attention mimarisi |
| **Veri Seti** | AUTSL (Ankara Üniversitesi Türk İşaret Dili Veri Seti) |
| **Sınıf Sayısı** | 226 kelime |
| **Video Sayısı** | ~36.302 video |
| **Başarı Hedefi** | %94 ve üzeri doğruluk |
| **Eğitim Ortamı** | Google Colab (GPU: A100/L4) |
| **Deployment** | TensorFlow Lite — cihaz üzerinde (on-device) |

---

## 2. Veri Pipeline (Data Processing)

### 2.1. AUTSL Veri Seti
- **Kaynak**: Ankara Üniversitesi
- **İçerik**: Türk İşaret Dili videolarından oluşan geniş kapsamlı veri seti
- **226 sınıf** (kelime): Sağlık, günlük hayat, duygular, sayılar vb.
- **~36.302 video**: Farklı kişiler, açılar ve ışık koşullarında çekilmiş
- **Format**: Video dosyaları (.mp4/.avi)

### 2.2. Feature Extraction (Özellik Çıkarma)

**Motor**: Google MediaPipe Holistic

MediaPipe, video karelerinden insan vücudunun anahtar noktalarını (landmark) çıkaran bir bilgisayar görüşü kütüphanesidir. Bu projede piksel bazlı görüntü işleme yerine **koordinat bazlı** yaklaşım kullanılır — bu da modelin çok daha hızlı ve hafif olmasını sağlar.

#### Nokta Seçimi (Feature Engineering)

| Bölge | Fiziksel Nokta | Koordinat (x, y) | Toplam Değer |
|-------|---------------|-------------------|-------------|
| Sağ El | 21 nokta | Her nokta 2 değer | 42 |
| Sol El | 21 nokta | Her nokta 2 değer | 42 |
| Pose (Üst Vücut) | 11 nokta | Her nokta 2 değer | 22 |
| **TOPLAM** | **53 nokta** | — | **106 değer** |

> **Neden z (derinlik) kullanılmıyor?**
> Telefon kameraları 2D görüntü verir. MediaPipe z koordinatını tahmin eder ama bu tahmin güvenilir değildir. Tutarlılık için sadece `(x, y)` kullanılır.

#### Pose Noktaları Detayı (11 Kritik Nokta)
Tüm vücut yerine sadece işaret dili için anlamlı noktalar seçildi:
- **Omuzlar** (2): Sağ omuz, sol omuz — kolun yönünü belirler
- **Dirsekler** (2): Sağ dirsek, sol dirsek — kol açısını gösterir
- **Bilekler** (2): Sağ bilek, sol bilek — elin başlangıç noktası
- **Gözler** (2): Sağ göz, sol göz — elin yüze yakınlığını ölçer
- **Burun** (1): Yüzün merkez noktası — referans
- **Ağız** (2): Sağ ağız köşesi, sol ağız köşesi — bazı işaretlerde ağız hareketi önemli

### 2.3. 🕒 Sliding Window (Kaydıran Pencere) Mekanizması

Sliding Window, sürekli bir veri akışını modelin işleyebileceği **sabit uzunluktaki küçük parçalara (pencerelere)** bölme tekniğidir. İşaret dili tanımada bir işaretin başlangıcı ve bitişi arasındaki "zaman akışını" yakalamak için kullanılır.

#### Temel Bileşenler

| Parametre | Değer | Açıklama |
|-----------|-------|----------|
| **Window Size** | **60 kare** | Modelin bir kerede baktığı frame sayısı. 30 FPS × 2sn = 60 kare |
| **Stride (Eğitim)** | **30 kare** | Pencerenin eğitimde kaç kare ileri kaydığı (overlap = 50%) |
| **Stride (Canlı)** | **1-5 kare** | FIFO mantığıyla her yeni karede pencere güncellenir |

> - **Stride = Window Size** → Pencereler birbiriyle çakışmaz → Veri kaybı riski artar  
> - **Stride < Window Size** → Pencereler birbiriyle çakışır (overlap) → Hareketin akıcılığını yakalamak için **en ideal** yaklaşım

---

#### A. Eğitim Aşamasında (Offline)

Veri setindeki uzun bir videodan **birden fazla eğitim örneği** üretmek için kullanılır. Bu sayede yüzlerce video yerine binlerce eğitim örneği elde edilir.

**Örnek:** 120 karelik video + Pencere Boyutu = 60 + Stride = 30:
```
Pencere 1: kare [0  → 59]
Pencere 2: kare [30 → 89]
Pencere 3: kare [60 → 119]
```
→ Tek bir videodan **3 farklı eğitim örneği** elde edilmiş olur (veri zenginleştirme).

```python
import numpy as np

def create_sliding_windows(features: np.ndarray, window_size=60, stride=30):
    """(N_kare, 106) şeklindeki veriyi sliding window ile böl."""
    windows = []
    for start in range(0, len(features) - window_size + 1, stride):
        window = features[start:start + window_size]  # (60, 106)
        windows.append(window)
    return np.array(windows)  # (N_windows, 60, 106)
```

---

#### B. Canlı Tahmin Aşamasında (Online / Flutter)

Kullanıcı kameranın karşısında hareket ederken modelin **sürekli ve gerçek zamanlı** tahmin yapmasını sağlar.

```
Kamera her kare → MediaPipe → 106 koordinat
        ↓
+--------------------------+
|  FIFO Buffer (deque)     |  ← Maksimum 60 kare tutar
|  [kare_1, kare_2, ...]   |
+--------------------------+
        ↓ (buffer 60 kareden kısa → tahmin yapma, bekle)
        ↓ (buffer 60 kareye dolunca → model çalışır)
        ↓
Her 5 yeni karede bir:
  • En eski 5 kare buffer'dan atılır (FIFO)
  • 5 yeni kare buffer'a eklenir
  • Güncel 60 karelik pencere modele verilir
        ↓
Confidence > %75 → Ekrana kelime yaz
Confidence < %75 → Sessiz kal (garbage filter)
```

**Flutter'da Dart kodu (mantık):**
```dart
final buffer = Queue<List<double>>(); // FIFO deque
const int windowSize = 60;

void onNewFrame(List<double> landmarks) { // 106 float
  buffer.addLast(landmarks);
  if (buffer.length > windowSize) buffer.removeFirst(); // Eski atılır
  
  if (buffer.length == windowSize) {
    // Her 5 karede bir tahmin yap (performans optimizasyonu)
    if (frameCount % 5 == 0) {
      final input = bufferToTensor(buffer); // [1, 60, 106]
      runInference(input);
    }
  }
  frameCount++;
}
```

---

#### Neden Sliding Window Kullanıyoruz?

| Neden | Açıklama |
|-------|----------|
| **Zaman Serisi Yakalama** | LSTM modelleri verinin geçmişine ihtiyaç duyar; window bu geçmişi paketler |
| **Hareketin Sürekliliği** | İşaret videonun başında da olsa sonunda da olsa pencere o ana geldiğinde yakalar |
| **Gecikme Azaltma** | Videonun bitmesini beklemeden pencere dolduğu anda tahmin üretilir |
| **Veri Zenginleştirme** | Eğitimde stride < window ile tek video → birden fazla örnek |

---

> [!IMPORTANT]
> **💡 Cursor / AI Asistanı İçin Teknik Not**
>
> Model girdi olarak `(Batch, Time_Steps, Features)` formatında veri bekliyor.
> Sliding window uygularken:
> ```
> Time_Steps = 60
> Features   = 106  (53 landmark × 2 koordinat)
> ```
> Eğitimde: `numpy.lib.stride_tricks.sliding_window_view` veya manuel `for` döngüsü  
> Flutter'da: `dart:collection > Queue<List<double>>` (FIFO deque) ile manuel buffer yönetimi

---

### 2.4. Çıktı Formatı

```python
# Her bir video/pencere için
window_features.shape = (60, 106)
# 60 kare × 106 koordinat değeri

# Tüm veri seti
X_train.shape = (N_train, 60, 106)  # Eğitim seti
X_val.shape   = (N_val, 60, 106)    # Doğrulama seti
X_test.shape  = (N_test, 60, 106)   # Test seti

# Etiketler
y_train.shape = (N_train,)  # 0-225 arası sınıf indeksleri
```

Veriler `.npy` (NumPy) formatında kaydedilir — hızlı yükleme ve düşük disk kullanımı.

### 2.5. Veri Akış Şeması

```
AUTSL Video (.mp4)
        ↓
OpenCV: Kare kare okuma (frame extraction)
        ↓
MediaPipe Holistic: Her karede 53 landmark çıkarma
        ↓
Koordinat dizisi: (N_kare, 106)
        ↓
Sliding Window (stride=30): (N_windows, 60, 106)
        ↓
NumPy array olarak kaydetme (.npy)
        ↓
Etiketleme: CSV'den sınıf adı eşleştirme
        ↓
Train / Validation / Test split
```


---

## 3. Model Mimarisi

### 3.1. LSTM + Multi-Head Attention

Bu model iki ana bileşenden oluşur:

```
Input: (batch_size, 60, 106)
        ↓
┌───────────────────────────┐
│      LSTM Katmanı         │
│  Zaman serisi analizi     │
│  Hareketin yönü ve hızı  │
│  Sequential pattern       │
└─────────────┬─────────────┘
              ↓
┌───────────────────────────┐
│  Multi-Head Attention     │
│  60 kare içinde "en       │
│  anlamlı" anlara odaklan  │
│  Vurgulu hareketleri bul  │
└─────────────┬─────────────┘
              ↓
┌───────────────────────────┐
│    Dense (Fully Connected)│
│  Dropout (Overfitting ↓)  │
│  Softmax → 226 sınıf     │
└───────────────────────────┘
              ↓
Output: Tahmin edilen kelime + Confidence Score
```

#### Neden LSTM?
- İşaret dili **zaman serisidir** — elin A noktasından B noktasına hareketi anlamlıdır
- LSTM, "uzun süreli bağımlılıkları" (long-term dependencies) öğrenebilir
- Örnek: "Ağrı" işaretinde elin göğse dokunup geri çekilmesi bir zaman serisinin iki farklı anıdır

#### Neden Multi-Head Attention?
- 60 kare içinde her kare eşit önemde değildir
- Attention mekanizması "hangi karelere odaklanmalıyım?" sorusunu öğrenir
- Örnek: Elin hızla yukarı kalkması (kritik an) vs. hazırlık pozisyonunda beklemesi (önemsiz an)
- **Multi-Head**: Birden fazla "bakış açısı" ile farklı örüntüleri aynı anda yakalar

### 3.2. Matematiksel Detay

```
# LSTM çıktısı
h_t = LSTM(x_t, h_{t-1}, c_{t-1})
# h_t: hidden state (gizli durum), her karedeki öğrenilmiş temsil

# Multi-Head Attention
Attention(Q, K, V) = softmax(QK^T / √d_k) × V
# Q, K, V: LSTM çıktılarından türetilir
# d_k: boyut normalizasyonu

# Final tahmin
y = softmax(W × attention_out + b)
# 226 sınıf için olasılık dağılımı
```

---

## 4. Eğitim Stratejisi

### 4.1. Data Augmentation (Veri Artırma)

Orijinal koordinatlar üzerinde uygulanan **sayısal augmentation** teknikleri:

| Teknik | Açıklama | Parametre |
|--------|----------|-----------|
| **Jittering** | Koordinatlara hafif rastgele gürültü ekleme | σ = 0.01-0.03 |
| **Shifting** | Tüm koordinatları x/y yönünde kaydırma | Δ = ±0.05 |
| **Scaling** | Koordinatları ölçeklendirme (büyütme/küçültme) | 0.9-1.1 |
| **Time Warping** | Zaman ekseninde hız değişikliği | ±%10 |

> **Not**: Piksel bazlı augmentation (döndürme, flip) yapılmaz çünkü girdi piksel değil, koordinattır. Bu bir avantajdır — augmentation çok daha hızlı ve kontrollüdür.

### 4.2. Eğitim Parametreleri (Planlanan)

| Parametre | Değer |
|-----------|-------|
| Optimizer | Adam |
| Learning Rate | 1e-3 (ReduceLROnPlateau ile düşürülecek) |
| Batch Size | 64 veya 128 |
| Epochs | 100-200 (Early Stopping ile) |
| Loss Function | Categorical Crossentropy |
| Metrics | Accuracy, F1-Score (macro), Confusion Matrix |
| Regularization | Dropout (0.3-0.5), L2 |
| Early Stopping | Patience = 15-20 epoch |
| Platform | Google Colab Pro (A100/L4 GPU) |

### 4.3. Başarı Metrikleri

| Metrik | Hedef | Açıklama |
|--------|-------|----------|
| **Top-1 Accuracy** | ≥ %94 | En yüksek olasılıklı tahmin doğruluğu |
| **Top-5 Accuracy** | ≥ %99 | İlk 5 tahmin içinde doğru sınıf olma oranı |
| **F1-Score (Macro)** | ≥ %90 | Tüm sınıflar için dengeli başarı |
| **Inference Time** | < 50ms | Mobil cihazda tek tahmin süresi |
| **Model Size** | < 15 MB | TFLite formatında |

---

## 5. TFLite Dönüşümü (Model → Mobil)

Eğitilen TensorFlow modeli doğrudan mobil cihazda çalışamaz. TensorFlow Lite (TFLite) ile optimize edilir:

### 5.1. Dönüşüm Pipeline

```
TensorFlow Model (.h5 / SavedModel)
        ↓
TFLite Converter
   ├── Quantization: Float32 → Float16 veya INT8
   ├── Operator Optimization
   └── Graph Optimization
        ↓
TFLite Model (.tflite)
   • Boyut: ~5-15 MB (orijinalin %10-20'si)
   • Hız: 2-5x daha hızlı inference
        ↓
Flutter'a entegre (tflite_flutter paketi)
```

### 5.2. Quantization Seçenekleri

| Tip | Boyut | Hız | Doğruluk Kaybı | Öneri |
|-----|-------|-----|----------------|-------|
| Float32 (Orijinal) | ~50 MB | Yavaş | %0 | ❌ Çok büyük |
| Float16 | ~25 MB | Orta | <%0.5 | ✅ Dengeli |
| Dynamic Range (INT8) | ~12 MB | Hızlı | <%1 | ✅ Önerilen |
| Full Integer (INT8) | ~10 MB | Çok hızlı | <%2 | ⚠️ Dikkatli test et |

---

## 6. Mobil Inference Pipeline (Flutter)

### 6.1. Cihaz Üzerinde Çalışma Akışı

```
Kamera (CameraController - 30 FPS)
        ↓ CameraImage (YUV420 format)
        ↓
MediaPipe (google_mlkit veya mediapipe_flutter)
        ↓ 53 landmark → 106 float değer
        ↓
Sliding Window Buffer
        ↓ Son 60 kare biriktirilir
        ↓ Yeni kare gelince en eski kare düşer
        ↓
TFLite Interpreter (tflite_flutter)
        ↓ Input: [1, 60, 106] float array
        ↓ Output: [1, 226] olasılık dizisi
        ↓
Post-Processing
        ↓ argmax → Sınıf indeksi
        ↓ max value → Confidence score
        ↓
UI Update (Riverpod State)
        ↓ Kelime + Confidence göster
        ↓ Cümle modunda tampona ekle
```

### 6.2. Performans Optimizasyonları

| Optimizasyon | Açıklama |
|-------------|----------|
| **Isolate** | MediaPipe + TFLite inference ayrı thread'de çalışır (UI donmaz) |
| **Frame Skipping** | Her kareyi işlemek yerine belirli FPS'de örnekleme |
| **Warm-up** | Uygulama açılışında model önceden yüklenir |
| **Batch Normalization** | Model içinde, inference hızını artırır |
| **GPU Delegate** | Destekleyen cihazlarda GPU üzerinde çalıştırma |

---

## 7. Cümle Modu (Sentence Mode)

### Teknik Yaklaşım

Cümle modu **mevcut kelime tabanlı modelin üzerine yazılım katmanı** eklenerek gerçekleştirilir. Model yeniden eğitilmez.

#### İşaret → Metin (Kamera) için:

```
Sürekli Tanıma Döngüsü:
        ↓
Her 60 karelik pencerede tahmin yap
        ↓
Confidence > threshold?
   ├── Evet: Kelimeyi tampona ekle
   │         Son kelimeyle aynı mı?
   │         ├── Evet: Tekrar sayacını artır (duplikasyonu engelle)
   │         └── Hayır: Yeni kelime olarak ekle
   └── Hayır: "Belirsiz" — atla
        ↓
Duraksama algılama (~1-1.5 sn eller aşağıda)
   ├── Duraksama var: Kelime sınırı → sonraki kelimeye geç
   └── Duraksama yok: Aynı kelime devam ediyor
        ↓
"Bitir" butonu veya özel işaret → Cümleyi tamamla
```

#### Metin → İşaret (Çevirici) için:

```
Input: "Benim ağrım var"
        ↓
Split: ["benim", "ağrım", "var"]
        ↓
Her kelime için sözlükten video ara
   ├── "benim" → video_benim.mp4 ▶️
   ├── "ağrım" → video_agri.mp4 ▶️ (kök kelime eşleştirme)
   └── "var"   → video_var.mp4 ▶️
        ↓
Sıralı oynatma (kelimeler arası kısa geçiş)
```

---

## 8. Kullanılan Teknolojiler (AI/ML)

| Teknoloji | Versiyon | Kullanım |
|-----------|----------|----------|
| Python | 3.12 | Veri işleme ve model eğitimi |
| TensorFlow | 2.x | Model inşa ve eğitim |
| Keras | TF içinde | Model API |
| MediaPipe | Latest | Landmark çıkarma (eğitim + mobil) |
| OpenCV | 4.x | Video okuma, kare çıkarma |
| NumPy | Latest | Matris işlemleri, .npy dosyaları |
| Pandas | Latest | CSV etiket yönetimi |
| Scikit-learn | Latest | Metrikler, augmentation yardımcıları |
| TFLite | TF içinde | Model optimizasyonu ve dönüşümü |
| Google Colab | Pro | GPU eğitim ortamı (A100/L4) |

---

## 9. JSON Veri Formatı (Tek Kare Örneği)

```json
{
  "frame_index": 1,
  "label": "agri",
  "label_index": 12,
  "landmarks": {
    "right_hand": [
      {"id": 0, "x": 0.52, "y": 0.88},
      {"id": 1, "x": 0.53, "y": 0.87},
      "... (21 nokta)"
    ],
    "left_hand": [
      {"id": 0, "x": 0.00, "y": 0.00},
      "... (el yoksa tüm değerler 0.0)"
    ],
    "pose": [
      {"id": "left_shoulder", "x": 0.45, "y": 0.22},
      {"id": "right_shoulder", "x": 0.55, "y": 0.20},
      "... (11 nokta)"
    ]
  }
}
```

### Tabular Format (Eğitim Verisi)

| Frame | RH_x0 | RH_y0 | ... | LH_x20 | LH_y20 | Pose_x0 | Pose_y0 | ... | Label |
|-------|--------|--------|-----|---------|---------|---------|---------|-----|-------|
| 1 | 0.52 | 0.88 | ... | 0.00 | 0.00 | 0.45 | 0.22 | ... | "agri" (12) |
| 2 | 0.53 | 0.87 | ... | 0.00 | 0.00 | 0.45 | 0.22 | ... | "agri" (12) |
| ... | ... | ... | ... | ... | ... | ... | ... | ... | ... |
| 60 | 0.60 | 0.80 | ... | 0.00 | 0.00 | 0.46 | 0.23 | ... | "agri" (12) |

---

## 10. Bilinen Riskler ve Çözümler

| Risk | Olasılık | Çözüm |
|------|----------|-------|
| Düşük ışıkta landmark algılama hatası | Orta | Kullanıcıya "ışık yetersiz" uyarısı + threshold kontrolü |
| Benzer işaretlerin karışması | Yüksek | Data augmentation + daha fazla eğitim verisi |
| Tek elle yapılan işaretlerde diğer elin gürültüsü | Düşük | El yoksa 0.0 değeri — model bunu öğrenir |
| TFLite dönüşümünde doğruluk kaybı | Orta | Float16 quantization tercih et, INT8'de dikkatli test et |
| Kamera FPS düşüklüğü (eski cihazlar) | Orta | Frame skipping + düşük çözünürlük modu |
| Model boyutu çok büyük (>30 MB) | Düşük | Pruning + quantization ile küçültme |
