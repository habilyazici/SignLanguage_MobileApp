import '../entities/daily_word.dart';

abstract interface class HomeRepository {
  /// Bugünün tarihine göre deterministik olarak seçilen günün işareti
  DailyWord getDailyWord();
}
