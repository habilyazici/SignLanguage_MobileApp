### 1- Mac'i Hazırlayalım
Öncelikle Mac bilgisayarında bazı programların kurulu olması şart.
- **Flutter** (Uygulamanın çalışması için şart. Eğer Mac'inde yüklü değilse şu linke git ve hemen kur: https://docs.flutter.dev/get-started/install)
- **Xcode** (Bunu Mac App Store'a girip aratarak ücretsiz indirebilirsin).
- **CocoaPods** (Mac'te "Terminal" programını aç ve ekrana şunu yaz: `sudo gem install cocoapods` Sonra Enter tuşuna basıp kurmasını bekle).

### 2- Kodları Hazırlama Vakti (Terminal Kullanımı)
Uygulama klasörünü bir şekilde (flash bellek veya internet) Mac bilgisayarının içine attın. Diyelim ki Masaüstünde duruyor. githubdan aldıysan zipten çıkar. o klasörü vs veya antigravitiy ile aç
2. Terminale cd flutter yaz
3. Şimdi hiçbir yeri kapatmadan kopyala-yapıştır yaparak şu komutları sırasıyla girip hep Enter'a bas:
   - flutter clean (Yaz ve Enter'a bas, bitmesini bekle. Sistemi temizler)
   - flutter pub get (Yaz ve Enter'a bas, kütüphaneleri indirecek bekle)
   - cd ios (Yaz ve Enter'a bas. Artık iOS klasörüne girdik).
   - pod install (Yaz ve Enter'a bas. Eğer bu adımda "arch" ile ilgili bir hata alırsan "arch -x86_64 pod install" yazmayı dene).
   - cd .. (Yaz ve Enter'a basıp geri ana yere çık).
Şimdi terminali küçültebilirsin, işimiz bitti!

### 3- Xcode ile Uygulamayı Açma
Sıra geldi projeyi Xcode ile başlatıp Apple'a hesabımızı kanıtlamaya.
1. Yeni indirdiğin uygulama klasörünün (frontend) içine gir, oradan **"ios"** klasörüne çift tıkla.
2. Oradaki dosyalar içinden beyaz renkli **Runner.xcworkspace** adlı dosyaya çift tıkla. (DİKKAT: Sakın mavi renkli Runner.xcodeproj olanı açma!).
3. Xcode programı açılınca, en sol tarafta tepede duran mavi renkli klasör içindeki **Runner** yazısına tıkla.
4. Ortadaki dev ekranda en üstteki sekmelerden **"Signing & Capabilities"** yazan sekmeye gir.
5. "Team" yazan yerde hiçbir şey seçili değildir. **Add Account** deyip normal, senin veya arkadaşının Apple ID (iCloud vs) mailin ve şifrenle giriş yap. (Developer hesabı şart değil). Sonra o menüye dönüp Team kısmından eklediğin kendi ismini seç.
(Eğer hemen altındaki "Bundle Identifier" yazısı kırmızı yanarsa, oradaki "com.hearmeout.frontend" yazısının sonuna klavyeden 1 veya 2 gibi sayılar ekle, hata kendiliğinden gider).

### 4- iPhone'a Gönderme İşlemi
Her şey harika gidiyor, şimdi telefonu bağlayacağız!
1. Kendi iPhone'unu sağlam bir kabloyla Mac'e tak. Telefon ekranında izin isterse "Bu bilgisayara güven" diyip telefon şifreni gir.
2. Xcode penceresinin en üstünde, ortada bir cihaz ismi yazar (iPhone 15 Simulator falan). Oraya tıkla, farenin tekerini en yukarı kaydırıp oradan **Kendi Gerçek iPhone Cihazını** seç.
3. ÇOK ÖNEMLİ: Ekranın en sol üstündeki Apple (Finder / Product) çubuk menüsüne gel: **Product > Scheme > Edit Scheme**'e tıkla. Açılan pencerede sol menüden *Run* sekmesini seç ve ortadaki Build Configuration yazan yeri "Debug" seçeneğinden **Release** seçeneğine çevir. (Bunu yapmazsak uygulama aşırı yavaşlar!).
4. Sol üst köşedeki o devasa oynatma tuşuna (**Play düğmesine**) bas. Başka bir şey yapma, hata vermezse saniyeler sonra uygulama telefonuna yüklenecektir.

### 5- Güvenlik Kilidini Açma
Uygulama telefonuna geldi ama tıklarsan "Güvenilmez Geliştirici" hatası vereceği için açılmayacak.
- Telefondan **Ayarlar > Genel > VPN ve Aygıt Yönetimi** sekmesini aç.
- Karşına çıkan Mac'e yazdığımız mail adresine tıkla.
- "Güven" tuşuna bas ve onay ver.

İşte bu kadar! Uygulama artık tam hızlı ve internetsiz haliyle iPhone cihazında hazır çalışıyor. Unutma, bedava hesapla yaptığımız için 7 gün sonra telefon güvenlik amaçlı bunu de-aktif eder. Tıklarsın ama açılmaz. O zaman yine yapman gereken tek şey onu o Mac'e kabloyu takıp sadece "Play" tuşuna tekrar basmaktır. Güle güle kullan!
