# İşaretlerin Dijital Yolculuğu: AI Pipeline Sistem Mimarisi

İşaret dili, doğası gereği durağan bir resimden ziyade, zaman içinde süzülen karmaşık bir koreografidir. Bu doküman, kameranızın yakaladığı ham piksellerin, yapay zekanın derinliklerinde nasıl işlenip anlamlı bir kelimeye dönüştüğünü bir "yolculuk" perspektifiyle ele alır.

## 1. Piksellerden Kemiklere: Dijital İskeletin İnşası
Sürecin ilk adımı, kameradan saniyede 30 kez gelen ham görüntü akışını anlamlandırmaktır. Sistem, her kareyi bir fotoğraf olarak değil, matematiksel koordinatlardan oluşan bir **Landmark (İşaretleme Noktası)** seti olarak görür. Bu noktalar, insan iskeletindeki kritik eklem yerlerini temsil eden dijital "çiviler" gibidir. Google MediaPipe altyapısı kullanılarak, kullanıcının o anki duruşu 106 kritik noktaya indirgenir. Bu noktaların 84 tanesi (sağ ve sol el için 21'er nokta) parmak boğumlarının ve bileğin ince hareketlerini takip ederken, geri kalan 22 nokta vücudun (omuz, dirsek, bilek) genel pozisyonunu, yani **Pose (Duruş)** verisini belirler.

Buradaki asıl sihir **Normalizasyon** katmanında gerçekleşir. Normalizasyon, farklı ölçeklerdeki verilerin ortak bir paydada buluşturulması işlemidir. Yapay zeka, noktaların ekrandaki koordinatlarına (örneğin 500. piksel) bakmak yerine, bu noktaların elin merkezine olan mesafesine odaklanır. Bu sayede, telefonunuzu ister yakında tutun ister uzakta, AI için işaretin büyüklüğü ve merkezi her zaman aynı standartta kalır; sistem boyuta değil, "biçime" odaklanır.

## 2. Zamanın Örneklenmesi: 2 Saniyelik Hafıza
İşaret dili hareketleri genellikle 1.5 ile 3 saniye arasında tamamlanır. Bu yüzden sistemimiz anlık görüntüyü değil, sürekli akan bir **Sliding Window (Kayan Pencere)** sistemini kullanır. Kayan pencere, akan bir nehir üzerinde sürekli belli bir mesafeyi takip eden bir çerçeve gibidir; sistem her zaman hafızasında son **2000 milisaniyelik (2 saniye)** bir geçmişi canlı tutar. Yeni bir kare geldiğinde, 2 saniye öncesine ait en eski kare bellekten silinir.

Ancak yapay zeka modelimiz (TFLite), girişte sabit olarak tam **60 karelik** (frame) bir veri bekler. Bu noktada **Resampling (Yeniden Örnekleme)** devreye girer. Resampling, verinin "yoğunluğunu" değiştirmek demektir. Kullanıcı bir işareti çok hızlı (örneğin 1 saniyede) yaparsa, sistem bu 1 saniyelik veriyi **Interpolation (Ara Değerleme)** yöntemiyle esneterek 60 kareye yayar. Hareketi yavaş yaparsa da bu veriyi 60 kareye sığacak şekilde sıkıştırır. Bu sayede AI, hareketi yapan kişinin hızından bağımsız olarak, işaretin "karakteristiğine" odaklanabilir.

## 3. Akıllı Bekçi: Hareket Kapısı (Motion Gate)
Sürekli olarak AI modelini çalıştırmak, telefonun işlemcisini yorar ve cihazın ısınmasına neden olur. Daha da önemlisi, kullanıcı hiçbir hareket yapmadığında AI'nın boşta duran elden yanlış kelimeler tahmin etmesini (hallucination) istemeyiz. Bu sorunu çözmek için **Motion Threshold (Hareket Eşiği)** mekanizmasını kullanıyoruz. Sistem, ardışık kareler arasındaki değişim miktarını hesaplar. Eğer eldeki toplam değişim 0.008'lik hassas bir eşiğin altındaysa, sistem "kullanıcı şu an durağan" kabul eder ve **Inference (Çıkarım Başlatma)** işlemini çalıştırmaz. Ne zaman ki el belirgin bir şekilde hareket etmeye başlar, sistem saniyeler içinde uyanır ve tahmine başlar.

## 4. Karar Anı: Sinirsel Konsensüs ve Kararlılık
Model, kendisine gelen 60 karelik paketi inceleyip bir **Inference (Bilişsel Çıkarım)** süreciyle olasılık listesi çıkarır (Örn: %95 "Merhaba", %3 "Nasılsın"). Ancak yapay zekalar bazen anlık gürültülerden dolayı yanıltıcı sonuçlar üretebilir. Bu kırılganlığı gidermek için **Temporal Smoothing (Zaman İçinde Yumuşatma)** katmanını uyguluyoruz.

Bir kelimenin ekranda belirmesi için modelin o kelimeyi **ardışık olarak 3 ile 10 kez** (kullanıcı ayarlı) onaylaması gerekir. Buna bir nevi "Yapay Zeka Meclisi" diyebiliriz; tüm oylar üst üste aynı kelime için çıkana kadar bekliyoruz. Bu süreç, anlık sıçramaları temizler ve ekranda sadece kullanıcının gerçekten yapmak istediği, "kararlı" hale gelmiş kelimelerin akmasını sağlar.

## 5. Sesten Kelimeye: Nihai İletişim
Bir kelime başarıyla onaylandığında süreç teknik dünyadan kullanıcı dünyasına geçer. Onaylanan kelime, anında bir cümle havuzuna eklenir. Kelime onaylandığı an, **TTS (Text-to-Speech - Metinden Sese)** motoru tetiklenir ve uygulama kelimeyi sesli olarak seslendirir. Eğer güven skoru çok yüksekse (%90+), kullanıcıya **Haptic Feedback (Dokunsal Geri Bildirim)**, yani hafif bir titreşim verilerek "İşaret anlaşıldı!" sinyali gönderilir.

Eğer kullanıcı 4 saniye boyunca yeni bir hareket yapmazsa, sistem yavaşça "konuşmanın bittiğini" varsayar ve ekranı yeni bir etkileşim için taze tutar. 

---
*Bu mimari, karmaşık bir yapay zeka sürecini kullanıcı için basit, hızlı ve kusursuz bir "doğal konuşma" deneyimine dönüştürmek için tasarlanmıştır.*
