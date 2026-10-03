import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'api_exception.dart';

/// One page of a paginated list endpoint (`{success, data: [...], pagination: {...}}`).
class ApiPage {
  final List<dynamic> items;
  final int page;
  final int totalPages;
  final int total;

  const ApiPage({required this.items, this.page = 1, this.totalPages = 1, this.total = 0});

  bool get hasMore => page < totalPages;
}

class ApiClient {
  final http.Client _client;
  final String _baseUrl;

  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceAll(RegExp(r'/+$'), '');

  String get baseUrl => _baseUrl;

  Uri _uri(String path, [Map<String, dynamic>? queryParams]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$_baseUrl$cleanPath';
    final uri = Uri.parse(fullUrl);
    if (queryParams != null && queryParams.isNotEmpty) {
      final sanitizedParams = <String, String>{};
      for (final entry in queryParams.entries) {
        if (entry.value != null && entry.value.toString().isNotEmpty) {
          sanitizedParams[entry.key] = entry.value.toString();
        }
      }
      return uri.replace(queryParameters: sanitizedParams);
    }
    return uri;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  dynamic _processResponse(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      body = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body is Map && body.containsKey('data')) {
        return body['data'];
      }
      return body;
    }

    String message = 'HTTP ${response.statusCode}';
    String? code;
    List<dynamic>? details;

    if (body is Map && body.containsKey('error')) {
      final err = body['error'];
      if (err is Map) {
        message = err['message']?.toString() ?? message;
        code = err['code']?.toString();
        if (err['details'] is List) {
          details = err['details'] as List<dynamic>;
        }
      } else {
        message = err.toString();
      }
    }

    throw ApiException(
      message: message,
      statusCode: response.statusCode,
      code: code,
      details: details,
    );
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParams, Duration timeout = const Duration(seconds: 15)}) async {
    try {
      final uri = _uri(path, queryParams);
      final res = await _client.get(uri, headers: _headers).timeout(timeout);
      return _processResponse(res);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Connection failed: $e');
    }
  }

  /// GET a paginated list and keep the pagination metadata that [get] discards.
  /// Also accepts the legacy `{data: {items: [...]}}` shape.
  Future<ApiPage> getPage(String path,
      {Map<String, dynamic>? queryParams, Duration timeout = const Duration(seconds: 20)}) async {
    try {
      final res = await _client.get(_uri(path, queryParams), headers: _headers).timeout(timeout);
      final data = _processResponse(res);
      Map<String, dynamic> pagination = const {};
      try {
        final body = jsonDecode(utf8.decode(res.bodyBytes));
        if (body is Map && body['pagination'] is Map) {
          pagination = Map<String, dynamic>.from(body['pagination'] as Map);
        }
      } catch (_) {}
      final items = data is List ? data : (data is Map && data['items'] is List ? data['items'] as List : const []);
      int asInt(dynamic v, int fallback) => v is num ? v.toInt() : int.tryParse('$v') ?? fallback;
      return ApiPage(
        items: items,
        page: asInt(pagination['page'], 1),
        totalPages: asInt(pagination['totalPages'], 1),
        total: asInt(pagination['total'], items.length),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Connection failed: $e');
    }
  }

  Future<dynamic> post(String path, {dynamic body, Duration timeout = const Duration(seconds: 20)}) async {
    try {
      final uri = _uri(path);
      final res = await _client
          .post(uri, headers: _headers, body: body != null ? jsonEncode(body) : null)
          .timeout(timeout);
      return _processResponse(res);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Connection failed: $e');
    }
  }

  Future<dynamic> patch(String path, {dynamic body, Duration timeout = const Duration(seconds: 20)}) async {
    try {
      final uri = _uri(path);
      final res = await _client
          .patch(uri, headers: _headers, body: body != null ? jsonEncode(body) : null)
          .timeout(timeout);
      return _processResponse(res);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Connection failed: $e');
    }
  }

  Future<dynamic> delete(String path, {Duration timeout = const Duration(seconds: 15)}) async {
    try {
      final uri = _uri(path);
      final res = await _client.delete(uri, headers: _headers).timeout(timeout);
      return _processResponse(res);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Connection failed: $e');
    }
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});
