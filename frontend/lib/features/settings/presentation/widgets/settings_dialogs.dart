import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SettingsDialogs {
  static void showCacheDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        title: const Text('Önbelleği Temizle'),
        content: const Text(
          'İndirilen tüm videolar silinecek. Devam edilsin mi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              // Video oynatıcı önbelleği sistem tarafından yönetiliyor;
              // uygulama verilerini temizlemek için cihaz ayarlarını kullanın.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Bu özellik yakında eklenecek. Şimdilik uygulama önbelleği sistem tarafından yönetilmektedir.',
                  ),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 3),
                ),
              );
            },
            child: const Text(
              'Tamam',
              style: TextStyle(color: Colors.blueAccent),
            ),
          ),
        ],
      ),
    );
  }

  static void showDeleteAccountDialog(
    BuildContext context,
    bool isDark, {
    WidgetRef? ref,
  }) {
    if (ref == null) {
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
          title: const Text('Hesabı Sil'),
          content: const Text(
            'Bu işlemi gerçekleştirmek için habilyazici00@gmail.com adresine yazabilirsiniz.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Kapat'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        bool loading = false;
        String? errorMsg;
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
            title: const Text('Hesabı Sil'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tüm verileriniz (geçmiş, yer imleri) kalıcı olarak silinecek. Bu işlem geri alınamaz.',
                ),
                if (errorMsg != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorMsg!,
                    style: const TextStyle(color: AppTheme.primaryStatusRed, fontSize: 13),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: loading ? null : () => Navigator.pop(dialogCtx),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: loading
                    ? null
                    : () async {
                        setState(() { loading = true; errorMsg = null; });
                        final error = await ref.read(authProvider.notifier).deleteAccount();
                        if (error != null) {
                          setState(() { loading = false; errorMsg = error; });
                          return;
                        }
                        if (context.mounted) {
                          Navigator.pop(dialogCtx);
                          context.go('/login');
                        }
                      },
                child: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Hesabı Sil',
                        style: TextStyle(color: AppTheme.primaryStatusRed, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  static void showNumberPickerDialog({
    required BuildContext context,
    required bool isDark,
    required String title,
    required int current,
    required ValueChanged<int> onChanged,
    int min = 1,
    int max = 20,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        int tempValue = current;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Daha yüksek değerler gürültüyü azaltır ama tepki süresini uzatır. Varsayılan: 3',
                  style: TextStyle(fontSize: 12, color: AppTheme.midGrey),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: tempValue > min
                          ? () => setState(() => tempValue--)
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tempValue.toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: tempValue < max
                          ? () => setState(() => tempValue++)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () {
                  onChanged(tempValue);
                  Navigator.pop(context);
                },
                child: const Text(
                  'Kaydet',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static void showMotionThresholdDialog({
    required BuildContext context,
    required bool isDark,
    required double current,
    required ValueChanged<double> onChanged,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        double tempValue = current;
        return StatefulBuilder(
          builder: (context, setState) {
            String label;
            if (tempValue <= 0.015) {
              label = 'Çok Hassas — küçük hareketleri algılar';
            } else if (tempValue <= 0.030) {
              label = 'Normal — önerilen değer';
            } else {
              label = 'Kaba — belirgin hareketler gerekir';
            }
            return AlertDialog(
              backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
              title: const Text('Hareket Hassasiyeti'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.midGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: tempValue,
                    min: 0.005,
                    max: 0.050,
                    divisions: 9,
                    label: tempValue.toStringAsFixed(3),
                    onChanged: (v) => setState(() => tempValue = v),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Hassas', style: TextStyle(fontSize: 11, color: AppTheme.midGrey)),
                      Text('Kaba', style: TextStyle(fontSize: 11, color: AppTheme.midGrey)),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                TextButton(
                  onPressed: () {
                    onChanged(tempValue);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Kaydet',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static void showHelpDialog(
    BuildContext context,
    bool isDark,
    String title,
    String helpText,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: AppTheme.primaryBlue),
            const SizedBox(width: 10),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(helpText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anladım'),
          ),
        ],
      ),
    );
  }
}
