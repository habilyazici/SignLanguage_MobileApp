# 🧠 HEAR ME OUT — Yapay Zeka ve Makine Öğrenmesi

## 1. Genel Bakış

| Alan | Bilgi |
|------|-------|
| **Amaç** | Gerçek zamanlı, video tabanlı Türk İşaret Dili (TİD) tanıma |
| **Referans Model** | Bidirectional LSTM + Self-Attention mimarisi |
| **Veri Seti** | AUTSL (Ankara Üniversitesi Türk İşaret Dili Veri Seti) |
| **Sınıf Sayısı** | 226 kelime |
| **Video Sayısı** | ~36.302 video |
| **Başarı Hedefi** | %94 ve üzeri doğruluk |
| **Model Boyutu** | ~587 KB (TFLite Dynamic Range Quantization) |
| **Eğitim Ortamı** | Google Colab (GPU: A100/L4) |
| **Deployment** | TensorFlow Lite — cihaz üzerinde (on-device) |

---

## 2. Veri Pipeline (Data Processing)

### 2.1. AUTSL Veri Seti
- **Kaynak**: Ankara Üniversitesi
- **İçerik**: Türk İşaret Dili videolarından oluşan geniş kapsamlı veri seti
- **226 sınıf** (kelime): Sağlık, günlük hayat, duygular, sayılar vb.
- **~36.302 video**: Farklı kişiler, açılar ve ışık koşullarında çekilmiş
  - Eğitim: ~28.142 video
  - Doğrulama: ~4.418 video
  - Test: ~3.742 video
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

**Örnek:** 120 karelik video + window=60 + stride=30 → **3 farklı eğitim örneği** elde edilir (overlap ile veri zenginleştirme).

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
Confidence → bkz. Bölüm 9 Confidence Eşik Standardı
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

- Her pencere: `(60, 106)` → 60 kare × 106 koordinat
- Eğitim seti: `(N_train, 60, 106)`, etiketler: `(N_train,)` → 0-225 sınıf indeksi
- `.npy` formatında kaydedilir — hızlı yükleme, düşük disk kullanımı

### 2.5. Veri Akış Şeması

```
AUTSL Video (.mp4)
        ↓
OpenCV: Kare kare okuma (frame extraction)
        ↓
MediaPipe Holistic: Her karede 53 landmark çıkarma
  └─ Konfigürasyon: model_complexity=1, min_detection=0.5, min_tracking=0.5
        ↓
Kare sayısı sabitleme (her video için 60 kare):
  ├─ Kısa video (< 60 kare) → Son kare tekrarlanır (Padding)
  └─ Uzun video (> 60 kare) → linspace ile eşit aralıklı örnekleme (Sampling)
        ↓
Koordinat dizisi: (60, 106) her video için
        ↓
Normalizasyon (bilek / burun referanslı + ölçeklendirme):
  ├─ Sağ/Sol el → Bilek noktası (0, 0) yapılır, sonra `max(abs)` ile ölçeklenir
  └─ Pose → Burun noktası (0, 0) yapılır, sonra `max(abs)` ile ölçeklenir
        ↓
NumPy array olarak kaydetme (.npy)
  X_train.npy, X_val.npy, X_test.npy
  y_train.npy, y_val.npy, y_test.npy
```

---

## 3. Model Mimarisi

### 3.1. Bidirectional LSTM + Self-Attention

Gerçek mimari (`model_training.py`):

```
Input: (batch_size, 60, 106)
        ↓
┌───────────────────────────┐
│ LayerNormalization        │  ← Giriş verisini stabilize eder
└─────────────┬─────────────┘
              ↓
┌───────────────────────────┐
│ BiLSTM (128, recurrentDP=0)│  ← TFLite uyumlu
│ BatchNormalization        │
│ Dropout (0.4)             │
└─────────────┬─────────────┘
              ↓
┌───────────────────────────┐
│ BiLSTM (64, recurrentDP=0) │
│ BatchNormalization        │
│ Dropout (0.4)             │
└─────────────┬─────────────┘
              ↓
┌───────────────────────────┐
│ SelfAttention (Custom)    │  ← 60 kare içinde kritik anlara odaklan
└─────────────┬─────────────┘
              ↓
┌───────────────────────────┐
│ Dense (256, relu)         │
│ BatchNormalization        │
│ Dropout (0.3)             │
│ Dense (128, relu)         │
│ BatchNormalization        │
│ Dense (226, softmax)      │  ← 226 kelime sınıfı
└───────────────────────────┘
              ↓
Output: Tahmin edilen kelime + Confidence Score
```

#### Neden Bidirectional LSTM?
- İşaret dili **zaman serisidir** — elin A noktasından B noktasına hareketi anlamlıdır
- **Bidirectional**: İleri (baştan sona) ve geri (sondan başa) aynı anda analiz — bağlamı daha iyi yakalar
- Örnek: "Ağrı" işaretinde elin göğüse dokunup geri çekilmesi iki yönlü analiz ile daha net algılanır

#### Neden Self-Attention?
- 60 kare içinde her kare eşit önemde değildir
- Attention mekanizması "hangi karelere odaklanmalıyım?" sorusunu öğrenir
- Custom `SelfAttention` layer: tanh + softmax ile ağırlıklı toplam

---

## 4. Eğitim Stratejisi

### 4.1. Data Augmentation (Veri Artırma)

Eğitim verisi **2 katına** çıkarılır: orijinal + gürültülü kopya birleştirilir.

| Teknik | Açıklama | Parametre |
|--------|----------|-----------|
| **Noise (Jitter)** | Koordinatlara çok küçük rastgele gürültü | σ = 0.002 (normalizasyonu bozmayacak düşük) |
| **Scaling** | İşareti yapan kişinin el büyüklüğünü simüle eder | × 0.95 ile 1.05 arası rastgele |

> **Not**: Piksel bazlı augmentation (döndürme, flip) yapılmaz çünkü girdi piksel değil, koordinattır. Bu bir avantajdır — augmentation çok daha hızlı ve kontrollüdür.

### 4.2. Eğitim Parametreleri

| Parametre | Değer |
|-----------|-------|
| Optimizer | Adam (lr=0.001) |
| Learning Rate | ReduceLROnPlateau: factor=0.5, patience=5, min=1e-5 |
| Batch Size | 64 |
| Epochs | Maks. 100 (EarlyStopping patience=15 ile erken durabilir) |
| Loss Function | Sparse Categorical Crossentropy |
| Metrics | Accuracy |
| Regularization | Dropout 0.4 (LSTM sonrası), 0.3 (Dense sonrası) + BatchNormalization |
| Checkpoint | En iyi `val_accuracy` Drive'a kaydedilir (`best_model.keras`) |
| Platform | Google Colab Pro (A100/L4 GPU) |

### 4.3. Başarı Metrikleri

| Metrik | Hedef | Açıklama |
|--------|-------|----------|
| **Top-1 Accuracy** | ≥ %94 | En yüksek olasılıklı tahmin doğruluğu |
| **Top-5 Accuracy** | ≥ %99 | İlk 5 tahmin içinde doğru sınıf olma oranı |
| **F1-Score (Macro)** | ≥ %90 | Tüm sınıflar için dengeli başarı |
| **Inference Time** | < 50ms | Mobil cihazda tek tahmin süresi |
| **Model Size** | ~587 KB | Gerçek dosya boyutu: `sign_language_model.tflite` |

---

## 5. TFLite Dönüşümü (Model → Mobil)

Eğitilen TensorFlow modeli doğrudan mobil cihazda çalışamaz. TensorFlow Lite (TFLite) ile optimize edilir:

### 5.1. Dönüşüm Pipeline

```
TensorFlow Model (best_model.keras)
        ↓
TFLite Converter
   ├── Quantization: DEFAULT (Dynamic Range INT8)
   ├── TFLITE_BUILTINS + SELECT_TF_OPS  ← Custom LSTM ops için zorunlu
   └── Graph Optimization
        ↓
sign_language_model.tflite
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
| Dynamic Range (INT8) | **~587 KB** | Hızlı | <%1 | ✅ Kullanılan (beklenenden küçük çıkmış) |
| Full Integer (INT8) | ~10 MB | Çok hızlı | <%2 | ⚠️ Alternatif |

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

## 9. Confidence Eşik Standardı

> **Bu tablo tüm proje için canonical kaynaktır.** UI, Flutter ve backend bu değerleri referans alır.

| Seviye | Aralık | Renk | UI Davranışı |
|--------|--------|------|--------------|
| **Garbage** | < %70 | — | Hiçbir şey gösterilmez, kelime atılır |
| **Düşük** | %70 – %80 | 🔴 Kırmızı | Kelime gösterilir + uyarı ikonu |
| **Orta** | %80 – %90 | 🟡 Sarı | Kelime gösterilir |
| **Yüksek** | ≥ %90 | 🟢 Yeşil | Kelime gösterilir + haptic feedback |

**Flutter implementasyonu:**
```dart
// recognition_provider.dart
if (confidence < 0.70) return; // garbage filter — sessiz kal
if (confidence >= 0.90) ConfidenceLevel.high;   // yeşil
if (confidence >= 0.80) ConfidenceLevel.medium; // sarı
else                    ConfidenceLevel.low;    // kırmızı
```

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
