# Hear Me Out — Sunum Slayt İçerikleri
## Veri Mimarisi · Model Eğitimi · Backend


bilinen kelimeler 
bayram 
ağaç
polis
zor
bekar
ben


---

## Slayt 1 — Veri Seti: AUTSL

**AUTSL — Ankara Üniversitesi Türk İşaret Dili Veri Seti**

- 226 farklı TİD kelimesi, 43 farklı imzacı
- **36.302 video** — ortalama ~2 saniye / video
- Microsoft Kinect v2: RGB + Derinlik kanalı, 512×512
- 20 farklı arka plan, çeşitli aydınlatma koşulları
- İmzacı profili: 10 erkek · 33 kadın · 6 TİD eğitmeni · 3 çevirmen · 1 sağır birey
- **Kullanıcı bağımsız split:** 31 eğitim / 6 doğrulama / 6 test imzacısı
- Train: 28.142 · Val: 4.418 · Test: 3.742

---

## Slayt 2 — Landmark Çıkarımı

**Ham Videodan Koordinat Verisine: MediaPipe**

- MediaPipe HandLandmarker v2.0 — her iki el, maks. 2 el
- MediaPipe PoseLandmarker (full model) — üst vücut
- Güven eşiği: 0.5 (tespit · varlık · takip)
- Her kare → normalize 2D koordinat (piksel bağımsız)
- Sağ el: 21 nokta · Sol el: 21 nokta · Pose: 11 seçili nokta
- **Toplam: 106 değer / kare**

---

## Slayt 3 — 106 Boyutlu Feature Vektörü

**Sabit Boyutlu Kare Temsili**

- `[0–41]` Sağ el — 21 landmark × (x, y)
- `[42–83]` Sol el — 21 landmark × (x, y)
- `[84–105]` Pose — burun · gözler · kulaklar · omuzlar · dirsekler · bilekler
- El görünmüyorsa slot sıfır kalır
- Her video → **60 × 106 matris**

---

## Slayt 4 — Zaman Serisi & Sequence Oluşturma

**60 Karelik Sabit Pencere**

- ~2 sn video × 30 FPS ≈ 60 kare → doğal hizalanma
- Kısa video: son kare tekrarlanarak doldurulur
- Uzun video: lineer interpolasyon ile 60 kare seçilir
- Checkpoint: her 100 videoda kayıt, kesintide devam
- Çıktı: `X.npy` (N×60×106) · `y.npy` (N,)

---

## Slayt 5 — Normalizasyon & Veri Artırma

**Konumdan & Ölçekten Bağımsız Temsil**

- El: bilek merkezleme → max-abs ölçekleme
- Pose: burun merkezleme → max-abs ölçekleme
- **4 augmentation:** ölçeklendirme · zaman kaydırma · kare maskeleme · Gaussian gürültü
- Sonuç: **veri seti 2× büyür**

---

## Slayt 6 — Model Mimarisi: BiLSTM + Self-Attention

**Giriş (60×106) → 226 Sınıf**

```
LayerNorm → BiLSTM(128) → BiLSTM(64) → Self-Attention
→ Dense(256) → Dense(128) → Dense(226, Softmax)
```

- BiLSTM: zaman serisinde çift yönlü bağımlılık
- Self-Attention: kritik karelere odaklanma
- ~500K parametre — mobil için optimize

---

## Slayt 7 — Eğitim & TFLite Dönüşümü

**Eğitim Konfigürasyonu**

- Adam (lr=0.001) · SparseCategoricalCrossentropy
- Batch: 64 · Maks epoch: 100
- EarlyStopping patience=15 · ReduceLROnPlateau factor=0.5
- En iyi val_accuracy'de checkpoint

**TFLite:**
- INT8 quantization → mobil'e uyumlu `.tflite`
- Android'de XNNPACK CPU delegate

---

## Slayt 8 — Model Çıktıları & Performans

**Kullanıcı Bağımsız Test Sonuçları**

- **Test doğruluğu: ~%87**
- 226 sınıf · eğitimde görülmemiş 6 imzacı
- Gerçek zamanlı: ~27ms / kare (Android)
- Mobil confidence eşiği: %75 (kullanıcı ayarlayabilir)

---

## Slayt 9 — Backend

**Express.js + TypeScript REST API**

- PostgreSQL + Prisma ORM
- JWT kimlik doğrulama (access + refresh token)
- `/auth` · `/users` · `/history` · `/bookmarks` · `/dictionary`
- Rate limiting · CORS · güvenli token saklama
- Tam TypeScript tip güvenliği

---

## Slayt 10 — PC Sunucu & Dağıtım

**Kendi Bilgisayarın Sunucu**

- Express lokal çalışır → **ngrok** public HTTPS tüneli açar
- Mobil → ngrok → Express → PostgreSQL
- Sıfır bulut maliyeti, anlık test
- `.env` içinde URL tanımlı, build'e gömülür

```
Uygulama → ngrok → localhost:3000 → PostgreSQL
```
