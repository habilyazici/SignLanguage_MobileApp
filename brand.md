# 🏷️ HEAR ME OUT — Marka ve Kurumsal Kimlik

## 1. Marka Kimliği

| Alan | Bilgi |
|------|-------|
| **Marka Adı** | Hear Me Out |
| **Amaç** | İşaret dilini gerçek zamanlı olarak metne çevirerek iletişim bariyerlerini kaldırmak |
| **Vizyon** | Herkesin eşit şekilde anlaşılabildiği bir dünya |

### Değerler

| Değer | Anlamı |
|-------|--------|
| **Erişilebilirlik** | Herkes için kullanılabilir, engelsiz tasarım |
| **Sadelik** | Karmaşıklıktan uzak, anlaşılır arayüz |
| **Güven** | Kullanıcı verisi güvende, on-device gizlilik |
| **Teknoloji + İnsan Odağı** | Teknoloji araç, insan merkez |

---

## 2. Logo

> **Logo dosyası buraya eklenecek**
> Habil logoyu bu repo'ya ekleyince aşağıdaki satır güncellenecek:
>
> `![Hear Me Out Logo](./assets/logo.png)`

---

## 3. Renk Paleti (Design System)

### Ana Renkler

| Renk | HEX | Kullanım | Hissiyat |
|------|-----|----------|----------|
| **Primary** | `#1E3A5F` | Ana butonlar, seçili tab'lar, AppBar | Lacivert — güven, teknoloji |
| **Secondary** | `#4DA8DA` | Vurgu, linkler, aktif göstergeler | Açık mavi — erişilebilirlik, sakinlik |
| **Soft Grey** | `#F2F4F7` | Light mode arka plan, kart arka planı | Hafif, temiz |
| **Mid Grey** | `#8A94A6` | İkincil metin, placeholder, ikonlar | Nötr, okunaklı |

### Dark Mode

| Renk | HEX | Kullanım |
|------|-----|----------|
| **Background** | `#0F172A` | Ana arka plan |
| **Card / Surface** | `#1E293B` | Kart, panel, modal arka planı |
| **Text Primary** | `#FFFFFF` | Ana metin |
| **Text Secondary** | `#8A94A6` | Alt metin, etiketler |

### Light Mode

| Renk | HEX | Kullanım |
|------|-----|----------|
| **Background** | `#F2F4F7` | Ana arka plan |
| **Card / Surface** | `#FFFFFF` | Kart arka planı |
| **Text Primary** | `#1E3A5F` | Ana metin (primary ile uyumlu) |
| **Text Secondary** | `#8A94A6` | Alt metin |

### Özel Renkler

| Renk | HEX | Kullanım |
|------|-----|----------|
| **Success** | `#22C55E` | Başarılı tanıma, confidence >80% |
| **Warning** | `#F59E0B` | Orta confidence, dikkat uyarısı |
| **Error / Emergency** | `#EF4444` | Hata, düşük confidence, acil durum butonu |

### Genel Hissiyat
> **"tech + calm + accessible"** — Teknolojik ama sakin, güven veren, herkes için erişilebilir.

---

## 4. Tipografi

| Stil | Font | Ağırlık | Boyut | Kullanım |
|------|------|---------|-------|----------|
| **H1** | Poppins | Bold | 28px | Ekran başlıkları |
| **H2** | Poppins | SemiBold | 22px | Bölüm başlıkları |
| **H3** | Poppins | SemiBold | 18px | Kart başlıkları |
| **Body** | Montserrat | Regular | 16px | Genel metin (minimum bu!) |
| **Body Medium** | Montserrat | Medium | 16px | Vurgulu gövde metin |
| **Body Small** | Montserrat | Regular | 14px | Alt açıklamalar |
| **Button** | Poppins | SemiBold | 16px | Buton metinleri |
| **Caption** | Montserrat | Regular | 12px | Tarihler, etiketler |

### Tipografi Kuralları
- ✅ **Minimum 16px** gövde metin (erişilebilirlik)
- ✅ Büyük puntolar tercih edilir
- ✅ **Yüksek kontrast** — metin/arka plan oranı WCAG AA standardında
- ✅ Başlıklarda **Poppins**, gövde metinde **Montserrat** — tutarlılık

### Flutter Tanımı
```dart
// pubspec.yaml
dependencies:
  google_fonts: ^latest

// theme/text_styles.dart
import 'package:google_fonts/google_fonts.dart';

final headingStyle = GoogleFonts.poppins(
  fontSize: 28,
  fontWeight: FontWeight.bold,
  color: Color(0xFF1E3A5F),
);

final bodyStyle = GoogleFonts.montserrat(
  fontSize: 16,
  fontWeight: FontWeight.w400,
  color: Color(0xFF1E3A5F),
);
```

---

## 5. UI Stil Kılavuzu

### Genel Prensipler
| Prensip | Uygulama |
|---------|----------|
| **Minimal & temiz** | Gereksiz eleman yok, beyaz alan bol |
| **Rounded corners** | Border radius: **16px** (tüm kartlar, butonlar) |
| **Flat design + hafif shadow** | Gölge var ama abartısız (elevation: 2-4) |
| **Büyük butonlar** | Min yükseklik 56px, erişilebilirlik için geniş dokunma alanı |
| **Icon + text birlikte** | Sadece ikon yetmez, yanında metin de olmal (anlaşılabilirlik) |

### Buton Stilleri

```
┌───────────────────────────────────────┐
│  Primary Button (Filled)              │
│  Background: #1E3A5F                  │
│  Text: #FFFFFF (Poppins SemiBold 16)  │
│  Height: 56px                         │
│  Radius: 16px                         │
│  Shadow: 0px 4px 12px rgba(0,0,0,0.1)│
└───────────────────────────────────────┘

┌───────────────────────────────────────┐
│  Secondary Button (Outlined)          │
│  Border: 2px solid #4DA8DA           │
│  Text: #4DA8DA                        │
│  Height: 56px                         │
│  Radius: 16px                         │
│  Background: transparent              │
└───────────────────────────────────────┘

┌───────────────────────────────────────┐
│  Emergency Button (Filled, Pulsing)   │
│  Background: #EF4444                  │
│  Text: #FFFFFF                        │
│  Height: 64px                         │
│  Radius: 16px                         │
│  Animation: Pulsing glow (1.5s loop)  │
└───────────────────────────────────────┘
```

### Kart Stili

```
┌───────────────────────────────────────┐
│  Card (Light Mode)                    │
│  Background: #FFFFFF                  │
│  Radius: 16px                         │
│  Shadow: 0px 2px 8px rgba(0,0,0,0.06)│
│  Padding: 16px                        │
│  Gap between cards: 12px              │
└───────────────────────────────────────┘

┌───────────────────────────────────────┐
│  Card (Dark Mode)                     │
│  Background: #1E293B                  │
│  Radius: 16px                         │
│  Border: 1px solid rgba(255,255,255,0.05) │
│  Shadow: none                         │
│  Padding: 16px                        │
└───────────────────────────────────────┘
```

### İkon Kullanımı
- **Stil**: Outlined (material icons outlined set)
- **Boyut**: 24px (normal), 32px (navigasyon), 48px (acil durum)
- **Renk**: Primary (#1E3A5F) veya Secondary (#4DA8DA)
- **Kural**: Her ikon yanında açıklayıcı metin olmalı (erişilebilirlik)

---

## 6. Flutter Tema Tanımı

```dart
// core/theme/app_colors.dart
class AppColors {
  // Primary
  static const primary = Color(0xFF1E3A5F);
  static const secondary = Color(0xFF4DA8DA);
  
  // Neutrals
  static const softGrey = Color(0xFFF2F4F7);
  static const midGrey = Color(0xFF8A94A6);
  
  // Dark Mode
  static const darkBackground = Color(0xFF0F172A);
  static const darkCard = Color(0xFF1E293B);
  
  // Semantic
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
}

// core/theme/app_theme.dart
ThemeData lightTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: Colors.white,
      background: AppColors.softGrey,
      error: AppColors.error,
    ),
    textTheme: GoogleFonts.montserratTextTheme(),
    cardTheme: CardTheme(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

ThemeData darkTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: AppColors.secondary,
      secondary: AppColors.secondary,
      surface: AppColors.darkCard,
      background: AppColors.darkBackground,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.darkBackground,
    textTheme: GoogleFonts.montserratTextTheme(ThemeData.dark().textTheme),
    cardTheme: CardTheme(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: AppColors.darkCard,
    ),
  );
}
```
