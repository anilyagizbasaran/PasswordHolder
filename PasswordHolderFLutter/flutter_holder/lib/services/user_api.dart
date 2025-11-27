import 'dart:convert';

import 'package:flutter_holder/utils/backend_config.dart';
import 'package:http/http.dart' as http;

class UserApi {
  UserApi({
    http.Client? client,
    String? baseUrl,
  })  : baseUrl = baseUrl ?? resolveUserApiBaseUrl(),
        _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;
  String? _jwtToken;
  String? _department;
  String? _email;
  int? _userId;

  String? get jwtToken => _jwtToken;
  String? get department => _department;
  int? get userId => _userId;
  String? get email => _email;
  http.Client get client => _client;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/login'),
      headers: _jsonHeaders(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    _throwIfNotOk(response);
    final body = jsonDecode(response.body);
    if (body is Map<String, dynamic>) {
      _persistJwtToken(body);
      _persistDepartment(body);
      _persistEmail(body);
      _persistUserId(body);
      return body;
    }
    throw Exception('Beklenmeyen login yanıtı formatı: $body');
  }

  Future<void> logout() async {
    final response = await _client.post(
      Uri.parse('$baseUrl/logout'),
      headers: _jsonHeaders(includeAuth: true),
    );
    _throwIfNotOk(response);
    _jwtToken = null;
    _department = null;
    _email = null;
    _userId = null;
  }

  Future<Map<String, dynamic>> createUser({
    required String name,
    required String email,
    required String password,
    int? departmentId,
  }) async {
    final response = await _client.post(
      Uri.parse(baseUrl),
      headers: _jsonHeaders(includeAuth: true),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        if (departmentId != null) 'departmentId': departmentId,
      }),
    );
    _throwIfNotOk(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getUser(String email) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/$email'),
      headers: _jsonHeaders(includeAuth: true),
    );
    _throwIfNotOk(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> listUsers() async {
    final response = await _client.get(
      Uri.parse(baseUrl),
      headers: _jsonHeaders(includeAuth: true),
    );
    _throwIfNotOk(response);
    final body = jsonDecode(response.body);
    if (body is List) {
      return body
          .whereType<Map>()
          .map<Map<String, dynamic>>(
            (item) => Map<String, dynamic>.from(
              item.map(
                (key, value) => MapEntry(
                  key.toString(),
                  value,
                ),
              ),
            ),
          )
          .toList();
    }
    if (body is Map && body.values.any((value) => value is List)) {
      final listValue = body.values.firstWhere(
        (value) => value is List,
      ) as List;
      return listValue
          .whereType<Map>()
          .map<Map<String, dynamic>>(
            (item) => Map<String, dynamic>.from(
              item.map(
                (key, value) => MapEntry(
                  key.toString(),
                  value,
                ),
              ),
            ),
          )
          .toList();
    }
    throw Exception('Beklenmeyen kullanıcı listeleme yanıtı: $body');
  }

  Future<Map<String, dynamic>> updateUser({
    required int id,
    required String name,
    required String email,
    required String password,
    int? departmentId,
  }) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/$id'),
      headers: _jsonHeaders(includeAuth: true),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        if (departmentId != null) 'departmentId': departmentId,
      }),
    );
    _throwIfNotOk(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> deleteUser(int id) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/$id'),
      headers: _jsonHeaders(includeAuth: true),
    );
    _throwIfNotOk(response);
  }

  void dispose() {
    _client.close();
  }

  Map<String, String> _jsonHeaders({bool includeAuth = false}) {
    final headers = {'Content-Type': 'application/json; charset=utf-8'};
    if (includeAuth && _jwtToken != null) {
      headers['Authorization'] = 'Bearer $_jwtToken';
    }
    return headers;
  }

  void _persistJwtToken(Map<String, dynamic> body) {
    final token = _extractToken(body);
    if (token != null && token.isNotEmpty) {
      _jwtToken = token;
      return;
    }
    throw Exception('JWT token login yanıtında bulunamadı: $body');
  }

  void _persistDepartment(Map<String, dynamic> body) {
    final departmentValue = _extractDepartment(body);
    if (departmentValue != null && departmentValue.isNotEmpty) {
      _department = departmentValue;
      return;
    }
    throw Exception('Departman bilgisi login yanıtında bulunamadı: $body');
  }

  void _persistEmail(Map<String, dynamic> body) {
    final emailValue = _extractEmail(body);
    if (emailValue != null && emailValue.isNotEmpty) {
      _email = emailValue;
      return;
    }
    throw Exception('E-posta bilgisi login yanıtında bulunamadı: $body');
  }

  void _persistUserId(Map<String, dynamic> body) {
    final idValue = _extractUserId(body);
    if (idValue != null) {
      _userId = idValue;
      return;
    }
    throw Exception('Kullanıcı kimliği login yanıtında bulunamadı: $body');
  }

  String? _extractToken(dynamic source) {
    if (source is String) {
      return source;
    }
    if (source is Map) {
      for (final entry in source.entries) {
        final key = entry.key.toString().toLowerCase();
        final value = entry.value;
        if (value is String && value.isNotEmpty) {
          if (key.contains('token') || key.contains('jwt')) {
            return value;
          }
        } else {
          final nested = _extractToken(value);
          if (nested != null && nested.isNotEmpty) {
            return nested;
          }
        }
      }
    } else if (source is Iterable) {
      for (final item in source) {
        final nested = _extractToken(item);
        if (nested != null && nested.isNotEmpty) {
          return nested;
        }
      }
    }
    return null;
  }

  String? _extractDepartment(dynamic source) {
    if (source is String) {
      return source;
    }
    if (source is Map) {
      for (final entry in source.entries) {
        final key = entry.key.toString().toLowerCase();
        final value = entry.value;
        if (value is String && value.isNotEmpty) {
          if (key.contains('department')) {
            return value;
          }
        } else {
          final nested = _extractDepartment(value);
          if (nested != null && nested.isNotEmpty) {
            return nested;
          }
        }
      }
    } else if (source is Iterable) {
      for (final item in source) {
        final nested = _extractDepartment(item);
        if (nested != null && nested.isNotEmpty) {
          return nested;
        }
      }
    }
    return null;
  }

  String? _extractEmail(dynamic source) {
    if (source is String && source.contains('@')) {
      return source;
    }
    if (source is Map) {
      for (final entry in source.entries) {
        final key = entry.key.toString().toLowerCase();
        final value = entry.value;
        if (value is String && value.contains('@')) {
          if (key.contains('email') || key.contains('username')) {
            return value;
          }
        } else {
          final nested = _extractEmail(value);
          if (nested != null && nested.isNotEmpty) {
            return nested;
          }
        }
      }
    } else if (source is Iterable) {
      for (final item in source) {
        final nested = _extractEmail(item);
        if (nested != null && nested.isNotEmpty) {
          return nested;
        }
      }
    }
    return null;
  }

  int? _extractUserId(dynamic source) {
    if (source is int) {
      return source;
    }
    if (source is String) {
      return int.tryParse(source);
    }
    if (source is Map) {
      for (final entry in source.entries) {
        final key = entry.key.toString().toLowerCase();
        final value = entry.value;
        if (key == 'id' || key.endsWith('_id')) {
          final parsed = _extractUserId(value);
          if (parsed != null) {
            return parsed;
          }
        } else {
          final nested = _extractUserId(value);
          if (nested != null) {
            return nested;
          }
        }
      }
    } else if (source is Iterable) {
      for (final item in source) {
        final nested = _extractUserId(item);
        if (nested != null) {
          return nested;
        }
      }
    }
    return null;
  }

  void _throwIfNotOk(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'İstek başarısız: ${response.statusCode} - ${response.body}',
      );
    }
  }
}

