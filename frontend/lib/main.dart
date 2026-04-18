import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'navigation/app_router.dart';
import 'core/utils/label_mapper.dart';
import 'features/settings/presentation/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TFLite etiketlerini ve SharedPreferences'ı paralel yükle — startup süresini azaltır.
  final labelsFuture = LabelMapper.loadLabels();
  final prefsFuture = SharedPreferences.getInstance();
  await labelsFuture;
  final prefs = await prefsFuture;

  // sharedPreferencesProvider'ı override ederek SettingsNotifier'ın
  // build() içinde senkron erişmesini sağla — settings flicker ortadan kalkar.
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const HearMeOutApp(),
    ),
  );
}

class HearMeOutApp extends ConsumerWidget {
  const HearMeOutApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(settingsProvider).themeMode;
    return MaterialApp.router(
      title: 'Hear Me Out',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode, // Profil sayfasındaki tema seçimini yansıtır
      routerConfig: router,
    );
  }
}
