# Hear Me Out — Konu Özeti (Öğrenme Notları)

---

## 1. AUTSL Veri Seti — Nedir, Neden Bu?

### Veri Seti Nedir?
AUTSL (Ankara University Turkish Sign Language), Türk İşaret Dili'ni tanımak için kullanılan halka açık bir akademik veri setidir. ChaLearn CVPR 2021 yarışması kapsamında yayınlandı. Türkçe konuşan topluluğun işaret diline yönelik en kapsamlı veri setidir.

### Rakamlar ve Anlamları
- **226 kelime:** Modelin tanıyabileceği toplam işaret sayısı. Her kelime bir sınıf (class). Model bu 226'dan birini tahmin eder.
- **43 imzacı:** Aynı kelimeyi 43 farklı kişi işaretledi. Bu önemli çünkü herkesin el hareketi farklı — biri büyük hareketler yaparken diğeri küçük yapar. Modelin bu farklılıklara rağmen doğru sonuç vermesi gerekir.
- **36.302 video:** Toplam örnek sayısı. Her video bir kelimeyi gösteriyor.
- **~2 saniye:** Ortalama video süresi. Bu süre içinde bir işaret tamamlanıyor. Bu yüzden 60 karelik pencere seçildi (2sn × 30fps = 60 kare).

### Kullanıcı Bağımsız Split — Neden Önemli?
Normal bir veri setinde eğitim ve test aynı kişilerden gelen örnekler içerebilir. Bu durumda model o kişinin stilini "ezberlemiş" olabilir. **Kullanıcı bağımsız** split'te test seti tamamen farklı kişilerden oluşur. 31 kişi eğitim, 6 kişi doğrulama, 6 kişi test — ve bu gruplar hiç çakışmaz. Bu %87 doğruluk gerçekten anlamlıdır çünkü model daha önce hiç görmediği kişileri doğru tanıdı.

---

## 2. Landmark Çıkarımı — Ham Videodan Sayıya

### Neden Doğrudan Video Değil?
Ham video piksel verisi içerir (her kare yüzlerce bin piksel). Bunu direkt modele vermek hem yavaş hem de kameraya, ışığa, kişinin ten rengine göre çok değişir. Bunun yerine **anlamlı koordinatlar** çıkardık: elin nerede olduğu, parmakların açısı, omuzların konumu. Bu koordinatlar ışıktan, arka plandan bağımsız.

### MediaPipe Nedir?
Google'ın geliştirdiği, insan vücudunu ve ellerini gerçek zamanlı analiz eden bir kütüphane. İki modeli kullandık:

**HandLandmarker:** Her elde 21 nokta tespit eder. Bu noktalar el bileği, her parmağın 3 eklemi ve parmak uçlarından oluşur. Koordinatlar [0,1] aralığında normalize edilmiş — yani görüntünün sol üstü (0,0), sağ altı (1,1).

**PoseLandmarker:** Vücuttaki 33 noktadan sadece 11 tanesini aldık (burun, gözler, kulaklar, omuzlar, dirsekler, bilekler). Tüm vücudu almadık çünkü işaret dili ağırlıklı olarak el ve üst vücut hareketlerine dayanır, bacaklar gereksiz gürültü yaratırdı.

### Güven Eşiği 0.5 Ne Demek?
MediaPipe her tespit için bir güven skoru üretir (0.0–1.0). 0.5 altında olan tespitler güvenilmez sayılır ve atlanır. O karede o organ "görünmüyor" kabul edilir, slot sıfır kalır.

### Video Modunda Çalışma
MediaPipe'ı VIDEO modunda kullandık. Bu moddaki fark: her kare bağımsız işlenmez, önceki kare bilgisi bir sonraki kareye aktarılır (tracking). Bu daha tutarlı takip sağlar, özellikle hızlı hareket eden ellerde.

---

## 3. 106 Boyutlu Feature Vektörü — Neyin Neresinde Ne Var?

### Vektör Yapısı
Her kare için 106 sayıdan oluşan bir dizi üretilir:

```
İndeks 0–41   → SAĞ EL (21 nokta × 2 koordinat)
İndeks 42–83  → SOL EL (21 nokta × 2 koordinat)
İndeks 84–105 → POSE   (11 nokta × 2 koordinat)
```

### Neden Bu Sıra?
Eğitim sırasında da, telefondaki inference sırasında da aynı sıra kullanılmak zorunda. Bu "sözleşme" değişirse model yanlış sonuç verir. Örneğin sol elin verisi sağ el slotuna gelirse model şaşırır.

### El Görünmüyorsa?
O elin 42 değeri sıfır olarak kalır. Model eğitim sırasında bu durumu da öğrendi (bazı işaretler tek elle yapılır). Sıfır dolu slot "el yok" anlamına gelir.

### Matris Boyutu
Tek bir video → 60 kare × 106 değer = **6.360 sayı**. Tüm eğitim seti → 28.142 video × 6.360 = yaklaşık 179 milyon sayı, `.npy` dosyasına kaydedilir.

---

## 4. Zaman Serisi & Sequence Oluşturma — Neden 60 Kare?

### 60 Kare Seçiminin Mantığı
Videolar ortalama ~2 saniye. 30 FPS'de bu 60 kare eder. Modelin giriş boyutu sabit olmalı (sinir ağları değişken boyut sevmez), bu yüzden tüm videoları 60 kareye normalize ettik. 2 saniyelik videolar için bu seçim çok doğaldı.

### Kısa Video — Padding
Diyelim 40 karelik bir video. 60'a ulaşmak için son kareyi 20 kez tekrarlıyoruz. Bu "bekliyor" bilgisini modele veriyor — işaret bitti, el hâlâ orada duruyor.

### Uzun Video — İnterpolasyon
Diyelim 90 karelik bir video. `np.linspace(0, 89, 60)` ile 60 eşit aralıklı indeks seçiyoruz. Bu video hızlandırmak gibi. Hareketin genel şekli korunuyor, ayrıntı biraz kayboluyor ama model için yeterli.

### Checkpoint Sistemi
28.142 videoyu işlemek saatler sürer. Yarıda bağlantı kesilirse, bilgisayar kapanırsa sıfırdan başlamak istemezsin. Her 100 videoda bir geçici dosya kaydedilir. Kod başlarken bu dosya varsa kaldığı yerden devam eder.

### .npy Dosyaları
NumPy'ın kendi binary formatı. `X_train.npy` içinde tüm eğitim kareleri, `y_train.npy` içinde etiketler (hangi videonun hangi kelime olduğu). Bu dosyalar doğrudan modele verilir, tekrar video açmaya gerek kalmaz.

---

## 5. Normalizasyon & Veri Artırma — Modeli Genelleştirme

### Neden Normalizasyon?
MediaPipe koordinatları [0,1] arasında ama kişiye göre değişir. Biri kameranın önünde yakın durursa eli büyük görünür, uzak durursa küçük. Biri solu sağ tarafta, diğeri ortada işaret eder. Model "büyük el = farklı işaret" diye öğrenmemeli.

**Bilek merkezleme:** Sağ elin tüm koordinatlarından bilek koordinatı çıkarılır. Artık tüm el koordinatları bileğe göre görecelidir. Elin ekranda nerede olduğu önemini yitirir.

**Max-abs ölçekleme:** Merkezlenmiş koordinatların en büyük mutlak değerine bölünür. Artık tüm değerler [-1, +1] aralığında. Büyük eller ve küçük eller aynı ölçeğe gelir.

**Sonuç:** Model sadece elin *şeklini* ve *hareketini* öğrenir, konumunu ve boyutunu değil.

### 4 Augmentation Yöntemi

**1. Ölçeklendirme:** Tüm koordinatlar ×0.9 ile ×1.1 arasında rastgele çarpılır. "Biraz daha büyük/küçük el" simülasyonu.

**2. Zaman Kaydırma:** Tüm sequence ±3 kare kaydırılır. Baştan ya da sondan birkaç kare "kesilir", öbür uca sıfır eklenir. "Biraz geç/erken başlayan video" simülasyonu.

**3. Kare Maskeleme:** 1–3 rastgele kare tamamen sıfıra çekilir. "Kamera o anda el göremedi" simülasyonu. Eksik karelere dayanıklılık kazandırır.

**4. Gaussian Gürültü:** Her koordinata küçük rastgele değerler eklenir (σ=0.002). Sensör titremesi simülasyonu. Çok küçük, insan gözüyle görünmez ama modeli daha sağlam yapar.

**Neden 2× büyüme?** Her orijinal örnek için bir augmented kopya üretilir. 28.142 eğitim örneği → 56.284 örnek. Model daha çeşitli veri görür, ezberleme (overfitting) azalır.

---

## 6. BiLSTM + Self-Attention Mimarisi — Model Nasıl Çalışır?

### LSTM Nedir?
Long Short-Term Memory. Normal sinir ağları "hafızasız"dır — her girdiyi bağımsız işler. LSTM'nin bir hafızası var: önceki kareleri hatırlar. İşaret dili için bu kritik çünkü "nasılsın" işareti 60 kare boyunca farklı el pozisyonlarının birleşimi.

### BiLSTM Neden İki Yönlü?
Normal LSTM sadece ileriye (kare 1'den 60'a) gider. **Bidirectional** LSTM hem ileriye hem geriye (60'tan 1'e) gider. İkisinin çıktısı birleştirilir. Neden? Bazı hareketlerin anlamı hem başlangıca hem sona göre değişir. Geriye gitmek de bağlam sağlar.

**İlk BiLSTM(128):** 128 birim, geniş öğrenme kapasitesi. Ham koordinat dizisinden temel hareket kalıplarını öğrenir.

**İkinci BiLSTM(64):** 64 birim, daha ince özellikler. İlk katmanın öğrendiklerini soyutlaştırır.

### Self-Attention Nedir?
60 karenin hepsi eşit önemli değildir. Bazı kareler işaretin kritik anını gösterir, bazıları geçiş hareketleri. Self-Attention katmanı modelin "hangi karelere daha çok dikkat etmeli" sorusunu kendi kendine öğrenmesini sağlar.

Matematiksel olarak: her kare için bir ağırlık hesaplanır (softmax ile), sonra tüm kareler bu ağırlıklarla ağırlıklı ortalamaya alınır.

### Dense Katmanlar
BiLSTM + Attention çıktısı yüksek boyutlu bir vektör. Dense(256) ve Dense(128) bu vektörü işleyerek son sınıflandırma için hazırlar. Son Dense(226) katmanı 226 sınıfın her biri için olasılık üretir. Softmax bu olasılıkların toplamını 1 yapar.

### Dropout ve BatchNormalization
**Dropout:** Eğitim sırasında nöronların bir kısmı rastgele "kapatılır". Model ezberleyemez, genelleştirmek zorunda kalır. 0.4 = %40 nöron kapatılır.

**BatchNormalization:** Her katmanın çıktısını normalize eder. Eğitimi hızlandırır, daha kararlı yapar.

---

## 7. Eğitim Süreci & TFLite — Modeli Eğitmek ve Telefona Taşımak

### Optimizer: Adam
Adam (Adaptive Moment Estimation), en yaygın kullanılan sinir ağı optimizeri. Her parametre için ayrı öğrenme hızı tutar ve zamanla adapte eder. lr=0.001 başlangıç değeri makul bir seçim.

### EarlyStopping — Neden?
100 epoch çalıştırmak yerine: doğrulama doğruluğu 15 epoch boyunca iyileşmezse dur, en iyi ağırlıklara geri dön. Bu overfitting'i önler ve zamanı verimli kullanır.

### ReduceLROnPlateau
Öğrenme hızı çok büyükse model "optimal nokta"nın etrafında zıplar, yaklaşamaz. 5 epoch iyileşme olmazsa lr yarıya iner. Minimum lr=1e-5 — daha küçük olursa çok yavaş öğrenir.

### TFLite Dönüşümü — Neden Gerekli?
TensorFlow modeli (`best_model_v2.keras`) Python'da çalışır, telefonda değil. TFLite telefon için tasarlanmış hafif format:
- **INT8 Quantization:** Model ağırlıkları 32-bit float'tan 8-bit integer'a dönüşür. Boyut ~4× küçülür, hız artar, doğrulukta minimal kayıp.
- **Batch size = 1:** Telefon her seferinde tek kare işler, batch 1 olmak zorunda.
- **XNNPACK Delegate:** Android'de CPU'yu optimize eden hızlandırıcı. ~27ms / inference sağlar.

---

## 8. Model Performansı — Sonuçlar Ne Anlama Gelir?

### %87 Doğruluk
226 kelime içinden doğru kelimeyi tahmin etme oranı %87. Rastgele tahmin %0.44 olurdu (1/226). %87, modelin gerçekten öğrendiğini gösteriyor.

Daha da önemlisi: **kullanıcı bağımsız** test setinde bu sonuç alındı. Model eğitimde hiç görmediği 6 kişinin işaretlerini %87 doğrulukla tanıdı. Bu gerçek dünya kullanımına yakın bir ölçüm.

### 27ms Gecikme
Telefonda bir kare işlemek 27ms. Saniyede ~37 kare işlenebilir. Bu gerçek zamanlı kullanım için yeterli (30 FPS hedefi).

### Confidence Eşiği %75
Model tahminini ne kadar "emin" verirse o kadar iyi. %75 altında emin değilse kelime kabul edilmez. Kullanıcı ayarlar menüsünden bunu değiştirebilir.

---

## 9. Backend — API Katmanı

### Neden Backend Gerekli?
Mobil uygulama bazı verileri sunucuda saklamak istiyor: kullanıcı hesabı, çeviri geçmişi, yer imleri, sözlük videoları. Bunlar telefonda saklanamaz — hesap farklı cihazlardan açılabilir, video dosyaları çok büyük.

### Express.js + TypeScript
Express.js Node.js üzerinde çalışan minimal bir web framework. TypeScript ile yazınca tür hataları derleme zamanında yakalanır, büyük projede hata azalır.

### PostgreSQL + Prisma
PostgreSQL güçlü bir ilişkisel veritabanı. Prisma ORM (Object-Relational Mapper) sayesinde SQL yazmak yerine TypeScript nesneleriyle veritabanı işlemleri yapılır. Schema değişikliklerini "migration" ile yönetir.

### JWT Kimlik Doğrulama
JSON Web Token. Kullanıcı giriş yapınca sunucu bir token üretir, telefona gönderir. Sonraki her istekte telefon bu token'ı gönderir, sunucu "bu kim?" sorusunu token'dan cevaplayabiliyor. Token şifreli, sahte üretilemez. Access token (kısa ömürlü, ~15dk) + Refresh token (uzun ömürlü, ~7gün) ikili sistemi kullanıldı.

### Endpoint Yapısı
- `/api/auth` — kayıt, giriş, token yenileme, çıkış
- `/api/users` — profil bilgisi, fotoğraf güncelleme
- `/api/history` — çeviri geçmişi kaydet/listele/sil
- `/api/bookmarks` — kelime yer imi ekle/listele/sil
- `/api/dictionary` — kelime ara, video URL'si getir

---

## 10. PC Sunucu & ngrok — Dağıtım Stratejisi

### Neden Bulut Değil?
AWS, Google Cloud gibi platformlar para öder. Geliştirme ve sunum aşamasında bu gereksiz. Kendi bilgisayarında Express sunucusu çalıştırıp, ngrok ile internete açmak yeterli.

### ngrok Nasıl Çalışır?
ngrok bir "tünel" açar: `localhost:3000` adresini `https://abc123.ngrok.io` gibi public bir URL'e çevirir. Telefon bu URL'e bağlanır, ngrok isteği bilgisayarına iletir, cevabı geri gönderir. Dışarıdan bakıldığında normal bir sunucu gibi görünür.

### .env Dosyası
API URL'si uygulama koduna gömülü değil, `.env` dosyasından okunur. Build sırasında bu değer uygulamaya işlenir. URL değişince sadece `.env` güncellenir, kod değişmez.

### Gerçek Dünya Testi
ngrok + lokal sunucu sayesinde gerçek Android/iOS cihazda, gerçek veritabanıyla tam entegrasyon testi yapılabildi. Hata anında sunucu loglarına anında bakılabildi, hızlı iterasyon mümkün oldu.
