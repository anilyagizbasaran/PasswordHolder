import 'dart:convert';

import 'package:flutter_holder/utils/backend_config.dart';
import 'package:http/http.dart' as http;

class PasswordHolderApi {
  PasswordHolderApi({
    http.Client? client,
    String? baseUrl,
  })  : baseUrl = baseUrl ?? resolvePasswordHolderBaseUrl(),
        _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;
  String? _bearerToken;

  void attachBearerToken(String? token) {
    _bearerToken = token;
  }

  Future<List<Map<String, dynamic>>> listHolders() async {
    final response = await _client.get(
      Uri.parse(baseUrl),
      headers: _jsonHeaders(includeAuth: true),
    );
    _throwIfNotOk(response);
    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    } else if (decoded is Map<String, dynamic>) {
      final list = decoded['data'] ?? decoded['items'] ?? decoded['rows'];
      if (list is List) {
        return list
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
      }
    }
    throw Exception('Şifre kasası verisi beklenen formatta değil: $decoded');
  }

  Future<Map<String, dynamic>> createHolder({
    required String name,
    required String email,
    required String password,
    int? userId,
    List<int>? userIds,
    int? departmentId,
  }) async {
    final Map<String, dynamic> payload = {
      'name': name,
      'email': email,
      'password': password,
    };
    final filteredUserIds = userIds?.whereType<int>().toList() ?? const <int>[];
    if (departmentId != null) {
      payload['departmentId'] = departmentId;
    } else if (filteredUserIds.isNotEmpty) {
      payload['userIds'] = filteredUserIds;
    } else if (userId != null) {
      payload['userId'] = userId;
    }
    final response = await _client.post(
      Uri.parse(baseUrl),
      headers: _jsonHeaders(includeAuth: true),
      body: jsonEncode(payload),
    );
    _throwIfNotOk(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateHolder({
    required int id,
    required String name,
    required String email,
    required String password,
    int? userId,
    List<int>? userIds,
    int? departmentId,
  }) async {
    final Map<String, dynamic> payload = {
      'name': name,
      'email': email,
      'password': password,
    };
    final filteredUserIds = userIds?.whereType<int>().toList() ?? const <int>[];
    if (departmentId != null) {
      payload['departmentId'] = departmentId;
    } else if (filteredUserIds.isNotEmpty) {
      payload['userIds'] = filteredUserIds;
    } else if (userId != null) {
      payload['userId'] = userId;
    }
    final response = await _client.put(
      Uri.parse('$baseUrl/$id'),
      headers: _jsonHeaders(includeAuth: true),
      body: jsonEncode(payload),
    );
    _throwIfNotOk(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> deleteHolder(int id) async {
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
        'Şifre kasası isteği başarısız: '
        '${response.statusCode} - ${response.body}',
      );
    }
  }
}

