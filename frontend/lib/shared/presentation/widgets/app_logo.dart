import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Uygulama logosu — assets/images/logo.png dosyasını gösterir.
/// Dosya henüz eklenmemişse hearing ikonu + metin fallback'i gösterir.
/// Kullanım: AppLogo() veya AppLogo(height: 32)
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.height = 24.0});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => _FallbackLogo(height: height),
    );
  }
}

class _FallbackLogo extends StatelessWidget {
  const _FallbackLogo({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.hearing_rounded, color: AppTheme.primaryBlue, size: height),
        SizedBox(width: height * 0.27),
        Text(
          'Hear Me Out',
          style: TextStyle(
            fontSize: height * 0.67,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryBlue,
          ),
        ),
      ],
    );
  }
}
