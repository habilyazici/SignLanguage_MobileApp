import '../entities/app_settings.dart';

abstract interface class SettingsRepository {
  /// Kayıtlı ayarları okur; kayıt yoksa varsayılanları döndürür.
  AppSettings load();

  /// Ayarları kalıcı olarak yazar.
  Future<void> save(AppSettings settings);
}
