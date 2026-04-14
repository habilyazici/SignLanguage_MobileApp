# 🏷️ HEAR ME OUT — Marka ve UI Spesifikasyonu

## 1. Renk Paleti

| Değişken       | HEX Kodu | Kullanım Alanı            |
|----------------|----------|---------------------------|
| **Primary**    | `#1E3A5F` | AppBar, Fill butonlar, App ana rengi. |
| **Secondary**  | `#4DA8DA` | Outline butonlar, vurgular, linkler. |
| **Soft Grey**  | `#F2F4F7` | Light Mode arka planları. |
| **Mid Grey**   | `#8A94A6` | Placeholder, secondary caption. |
| **Success**    | `#22C55E` | Model Prediction > %90 |
| **Warning**    | `#F59E0B` | Model Prediction > %80 |
| **Error/Emc**  | `#EF4444` | Model Prediction > %70 & Acil durum buton stili. |
| **Dark Bg**    | `#0F172A` | Dark Mode temel katman arka plan. |
| **Dark Surface**|`#1E293B` | Dark Mode panel/card arka planları. |

## 2. Tipografi Kuralları
Google Fonts üzerinden konfigüre edilmeli:
- **Başlık (H1-H3):** Poppins (Kuvvetli, modern yapı)
- **Metin (Body):** Montserrat (Min 14px, hedef 16px font okunabilirlik kurallarına uygun olarak)

## 3. UI Standartları
- **Kart Kalıpları:** Padding: 16px. Border Radius: `16px`. Elevation (Light: 2, Dark: 0 / Borderline).
- **Butonlar:** Target touch-size Minimum 48x48. Primary buton yükseklik hedefleri 56px.
- **Görsel Asset:** Outlined icon yapısı. (İkon + Metin mutlaka birleşik tasarımsal olarak kullanılmalı). 
- **Glassmorphism:** AI tanıma panelinde camera overflow üzeri Blur (sigma 10,10) filtresi kullanılacak.
