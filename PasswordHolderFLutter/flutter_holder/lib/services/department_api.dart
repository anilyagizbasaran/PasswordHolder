import 'dart:convert';

import 'package:flutter_holder/utils/backend_config.dart';
import 'package:http/http.dart' as http;

class DepartmentApi {
  DepartmentApi({
    http.Client? client,
    String? baseUrl,
  })  : baseUrl = baseUrl ?? resolveDepartmentBaseUrl(),
        _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;
  String? _bearerToken;

  void attachBearerToken(String? token) {
    _bearerToken = token;
  }

  Future<List<Map<String, dynamic>>> listDepartments() async {
    final response = await _client.get(
      Uri.parse(baseUrl),
      headers: _jsonHeaders(includeAuth: true),
    );
    _throwIfNotOk(response);
    final body = jsonDecode(response.body);
    if (body is List) {
      return body
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(
              item.map(
                (key, value) => MapEntry(key.toString(), value),
              ),
            ),
          )
          .toList();
    }
    throw Exception('Departman listesi beklenen formatta değil: $body');
  }

  Future<Map<String, dynamic>> createDepartment({
    required String name,
    String? description,
  }) async {
    final response = await _client.post(
      Uri.parse(baseUrl),
      headers: _jsonHeaders(includeAuth: true),
      body: jsonEncode({
        'name': name,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
      }),
    );
    _throwIfNotOk(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateDepartment({
    required int id,
    required String name,
    String? description,
  }) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/$id'),
      headers: _jsonHeaders(includeAuth: true),
      body: jsonEncode({
        'name': name,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim()
        else
          'description': null,
      }),
    );
    _throwIfNotOk(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> deleteDepartment(int id) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/$id'),
      headers: _jsonHeaders(includeAuth: true),
    );
    _throwIfNotOk(response);
  }

  Map<String, String> _jsonHeaders({bool includeAuth = false}) {
    final headers = {'Content-Type': 'application/json; charset=utf-8'};
    if (includeAuth && _bearerToken != null) {
      headers['Authorization'] = 'Bearer $_bearerToken';
    }
    return headers;
  }

  void _throwIfNotOk(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Departman isteği başarısız: '
        '${response.statusCode} - ${response.body}',
      );
    }
  }
}


