import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import '../providers/recognition_provider.dart';

class RecognitionScreen extends ConsumerWidget {
  const RecognitionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Saniyede bir güncellenen global beyini buraya bağlıyoruz
    final state = ref.watch(recognitionProvider);

    return Scaffold(
      backgroundColor: Colors.black, // Kamera yüklenene kadar siyah arka plan
      body: Stack(
        children: [
          // 1. Zemin: Şeffaf Kamera Vizörü (Tam Ekran)
          _buildCameraPreview(state),

          // 2. Üst Kısım: Basit Şeffaf Başlık
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Canlı Çeviri (AI)',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    shadows: [
                      const Shadow(color: Colors.black54, blurRadius: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Alt Kısım: Glassmorphism (Buzlu Cam) Tahmin Çubuğu
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: _buildGlassmorphismBottomBar(context, state),
          ),
        ],
      ),
    );
  }

  // Kamerayı veya Loading animasyonunu ekrana sığdırır
  Widget _buildCameraPreview(RecognitionState state) {
    if (state.isError) {
      return const Center(
        child: Text(
          'Kameraya erişilemedi veya yapay zeka yüklenemedi.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    if (!state.isReady || state.cameraController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final cameraController = state.cameraController!;

    // Kamera en-boy oranını hesaplayıp tüm ekrana boşluksuz FittedBox ile sığdırır
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: cameraController.value.previewSize?.height ?? 1,
          height: cameraController.value.previewSize?.width ?? 1,
          child: CameraPreview(cameraController),
        ),
      ),
    );
  }

  // Glassmorphism tasarımlı metin kutusu
  Widget _buildGlassmorphismBottomBar(
    BuildContext context,
    RecognitionState state,
  ) {
    // Confidence (Güven Skoru) UI Renk Mantığı (TFLite -> Arayüz Adaptasyonu)
    Color scoreColor = Colors.grey;
    if (state.confidenceScore >= 0.90) {
      scoreColor = const Color(0xFF22C55E); // Success Green
    } else if (state.confidenceScore >= 0.80) {
      scoreColor = const Color(0xFFF59E0B); // Warning Yellow
    } else if (state.confidenceScore >= 0.70) {
      scoreColor = const Color(0xFFEF4444); // Error Kırmızı
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 10,
          sigmaY: 10,
        ), // Buzlu cam bulanıklık seviyesi
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0x1AFFFFFF), // %10 saydam beyaz
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ), // Klasik Apple/Dribbble cam dokusu
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Modelin Tahmin Ettiği Kelime String'i
              Text(
                state.predictedWord,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  shadows: [
                    const Shadow(color: Colors.black45, blurRadius: 5),
                  ], // Olası parlak yüzlerde yazının okunabilirliği artar
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // İndikatör (Progress Bar)
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: state
                            .confidenceScore, // 0.0 - 1.0 skalasında modelin emin olma oranı
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          scoreColor,
                        ), // Skor rengi devrede!
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Numerik Oran (%85 vs)
                  Text(
                    '%${(state.confidenceScore * 100).toInt()}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scoreColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
