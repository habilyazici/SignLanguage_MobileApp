import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'navigation/app_router.dart';
import 'core/utils/label_mapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TFLite etiketlerini cihaz hafızasına ilk saniyede alır
  await LabelMapper.loadLabels();

  // Tüm uygulamayı Riverpod beynine (ProviderScope) bağladık
  runApp(const ProviderScope(child: HearMeOutApp()));
}

class HearMeOutApp extends StatelessWidget {
  const HearMeOutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Hear Me Out',
      debugShowCheckedModeBanner: false, // Debug bandını kaldırır
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Kullanıcının cihaz temasına otomatik uyar
      routerConfig: router, // Sayfa yönlendirmelerini (GoRouter) devreye sokar
    );
  }
}
