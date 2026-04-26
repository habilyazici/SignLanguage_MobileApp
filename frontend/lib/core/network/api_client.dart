import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class UnauthorizedException implements Exception {}

extension AuthHttpClient on Ref {
  String? get _token => read(authProvider).token;

  void _on401() => read(authProvider.notifier).signOut();

  Future<http.Response> apiGet(String path) async {
    final token = _token;
    if (token == null) throw UnauthorizedException();
    final res = await http.get(
      Uri.parse('$kApiBaseUrl$path'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode == 401) { _on401(); throw UnauthorizedException(); }
    return res;
  }

  Future<http.Response> apiPost(String path, {Object? body}) async {
    final token = _token;
    if (token == null) throw UnauthorizedException();
    final res = await http.post(
      Uri.parse('$kApiBaseUrl$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body != null ? jsonEncode(body) : null,
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode == 401) { _on401(); throw UnauthorizedException(); }
    return res;
  }

  Future<http.Response> apiDelete(String path) async {
    final token = _token;
    if (token == null) throw UnauthorizedException();
    final res = await http.delete(
      Uri.parse('$kApiBaseUrl$path'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode == 401) { _on401(); throw UnauthorizedException(); }
    return res;
  }

}
