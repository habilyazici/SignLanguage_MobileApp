/// Sözlükteki tek bir işaret kelimesini temsil eden domain entity.
class SignEntry {
  final int id;
  final String label; // Türkçe kelime

  const SignEntry({required this.id, required this.label});
}
