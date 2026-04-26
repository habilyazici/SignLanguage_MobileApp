import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'navigation/app_router.dart';
import 'core/utils/label_mapper.dart';
import 'features/settings/presentation/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);

  // TFLite etiketlerini ve SharedPreferences'ı paralel yükle — startup süresini azaltır.
  final labelsFuture = LabelMapper.loadLabels();
  final prefsFuture = SharedPreferences.getInstance();
  await labelsFuture;
  final prefs = await prefsFuture;

  // sharedPreferencesProvider'ı override ederek SettingsNotifier'ın
  // build() içinde senkron erişmesini sağla — settings flicker ortadan kalkar.
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const HearMeOutApp(),
    ),
  );
}

class HearMeOutApp extends ConsumerWidget {
  const HearMeOutApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final themeMode = settings.themeMode;
    final textSize = settings.textSize;

    return MaterialApp.router(
      title: 'Hear Me Out',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        // Metin boyutu ayarını tüm uygulamaya uygula
        final double scaleFactor = switch (textSize) {
          AppTextSize.standard => 1.0,
          AppTextSize.large => 1.15,
          AppTextSize.extraLarge => 1.3,
        };

        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scaleFactor)),
          child: child!,
        );
      },
    );
  }
}
