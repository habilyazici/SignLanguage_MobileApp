import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class UnauthorizedException implements Exception {}

extension AuthHttpClient on Ref {
  String? get _token => read(authProvider).token;

  void _on401() => read(authProvider.notifier).signOut();

  /// Tüm API istekleri için varsayılan başlıklar
  Map<String, String> _getHeaders({bool isJson = false}) {
    final headers = {
      'bypass-tunnel-reminder': 'true',
      if (_token != null) 'Authorization': 'Bearer $_token',
      if (isJson) 'Content-Type': 'application/json',
    };
    return headers;
  }

  Future<http.Response> apiGet(String path) async {
    final res = await http.get(
      Uri.parse('$kApiBaseUrl$path'),
      headers: _getHeaders(),
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode == 401) {
      _on401();
      throw UnauthorizedException();
    }
    return res;
  }

  Future<http.Response> apiPost(String path, {Object? body}) async {
    final res = await http.post(
      Uri.parse('$kApiBaseUrl$path'),
      headers: _getHeaders(isJson: true),
      body: body != null ? jsonEncode(body) : null,
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode == 401) {
      _on401();
      throw UnauthorizedException();
    }
    return res;
  }

  Future<http.Response> apiDelete(String path) async {
    final res = await http.delete(
      Uri.parse('$kApiBaseUrl$path'),
      headers: _getHeaders(),
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode == 401) {
      _on401();
      throw UnauthorizedException();
    }
    return res;
  }
}
