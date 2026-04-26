import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Backend API base URL'i .env dosyasından okunur.
String get kApiBaseUrl {
  final ip = dotenv.get('BASE_IP', fallback: 'localhost');
  final port = dotenv.get('PORT', fallback: '3000');
  final protocol = port == '443' ? 'https' : 'http';
  final url = '$protocol://$ip${port == '443' ? '' : ':$port'}';
  
  // DEBUG: Uygulamanın hangi adrese gittiğini görelim
  debugPrint('DEBUG: Flutter is connecting to -> $url');
  
  return url;
}
