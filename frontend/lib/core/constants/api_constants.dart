import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Backend API base URL'i .env dosyasından okunur.
String get kApiBaseUrl {
  final ip = dotenv.get('BASE_IP', fallback: 'localhost');
  final port = dotenv.get('PORT', fallback: '3000');
  final protocol = port == '443' ? 'https' : 'http';
  return '$protocol://$ip${port == '443' ? '' : ':$port'}';
}

/// ngrok tüneli kullanırken tarayıcı uyarı sayfasını atlamak için gerekli header.
/// VideoPlayerController.networkUrl ve http isteklerinde kullanılır.
const kNgrokHeaders = {'ngrok-skip-browser-warning': 'true'};

/// Kısa auth işlemleri (login, register, forgot-password) için timeout.
const kAuthTimeout = Duration(seconds: 10);

/// Genel API istekleri (bookmark, history, word detail) için timeout.
const kApiTimeout = Duration(seconds: 15);

/// Büyük veri yüklemeleri (manifest, sayfalı sözlük listesi) için timeout.
const kDataTimeout = Duration(seconds: 20);
