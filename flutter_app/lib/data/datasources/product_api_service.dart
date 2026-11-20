import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../../core/constants/app_config.dart';
import '../../core/errors/exceptions.dart';
import '../../domain/models/product.dart';

class ProductApiService {
  final http.Client _client;
  final Random _random = Random();
  String _currentTraceId = '';

  String get currentTraceId => _currentTraceId;

  ProductApiService({http.Client? client}) : _client = client ?? http.Client() {
    _currentTraceId = _generateTraceId();
  }

  String _generateTraceId() {
    return List.generate(32, (_) => _random.nextInt(16).toRadixString(16)).join();
  }

  String _generateSpanId() {
    return List.generate(16, (_) => _random.nextInt(16).toRadixString(16)).join();
  }

  Uri _buildUri(String baseUrl, String path, [Map<String, String>? queryParams]) {
    final cleanBase = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final cleanPath = path.trim().replaceAll(RegExp(r'^/+'), '');
    final fullUrl = '$cleanBase/$cleanPath';
    final uri = Uri.parse(fullUrl);
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  Map<String, String> _headers(String traceId) => {
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=UTF-8',
        'ngrok-skip-browser-warning': 'true',
        'traceparent': '00-$traceId-${_generateSpanId()}-01',
      };

  void _updateTraceContext(http.Response response, String sentTraceId) {
    final headerTrace = response.headers['traceparent'];
    if (headerTrace != null && headerTrace.isNotEmpty) {
      final parts = headerTrace.split('-');
      if (parts.length >= 4 && parts[1].length == 32) {
        _currentTraceId = parts[1];
        return;
      }
    }
    _currentTraceId = sentTraceId;
  }

  /// Tests connectivity to the backend
  Future<bool> ping(String baseUrl) async {
    final traceId = _generateTraceId();
    try {
      final uri = _buildUri(baseUrl, AppConfig.productsEndpoint);
      final response = await _client
          .get(uri, headers: _headers(traceId))
          .timeout(AppConfig.testConnectionTimeout);
      _updateTraceContext(response, traceId);
      return response.statusCode >= 200 && response.statusCode < 400;
    } catch (_) {
      _currentTraceId = traceId;
      return false;
    }
  }

  /// GET /api/products (optional category filter)
  Future<List<Product>> fetchProducts(String baseUrl, {String? category}) async {
    final traceId = _generateTraceId();
    try {
      final queryParams = (category != null && category.trim().isNotEmpty)
          ? {'category': category.trim()}
          : null;
      final uri = _buildUri(baseUrl, AppConfig.productsEndpoint, queryParams);

      final response = await _client
          .get(uri, headers: _headers(traceId))
          .timeout(AppConfig.requestTimeout);
      _updateTraceContext(response, traceId);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> list;
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map<String, dynamic> && decoded['products'] is List) {
          list = decoded['products'] as List;
        } else {
          list = [];
        }
        return list
            .map((item) => Product.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw ApiException(
          'Failed to load products: ${response.reasonPhrase ?? 'Server error'}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException catch (e) {
      _currentTraceId = traceId;
      throw NetworkException('Network error: Cannot reach server at $baseUrl (${e.message})');
    } on http.ClientException catch (e) {
      _currentTraceId = traceId;
      throw NetworkException('Connection failed: ${e.message}');
    } catch (e) {
      _currentTraceId = traceId;
      if (e is AppException) rethrow;
      throw ApiException('Unexpected error while fetching products: $e');
    }
  }

  /// GET /api/categories
  Future<List<String>> fetchCategories(String baseUrl) async {
    final traceId = _generateTraceId();
    try {
      final uri = _buildUri(baseUrl, AppConfig.categoriesEndpoint);
      final response = await _client
          .get(uri, headers: _headers(traceId))
          .timeout(AppConfig.requestTimeout);
      _updateTraceContext(response, traceId);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> list;
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map<String, dynamic> && decoded['categories'] is List) {
          list = decoded['categories'] as List;
        } else {
          list = [];
        }

        return list.map((item) {
          if (item is Map<String, dynamic>) {
            return (item['category'] ?? item['name'] ?? '').toString();
          }
          return item.toString();
        }).where((name) => name.trim().isNotEmpty).toList();
      } else {
        return [];
      }
    } catch (_) {
      _currentTraceId = traceId;
      return [];
    }
  }

  /// POST /api/products
  Future<Product> addProduct(String baseUrl, Product product) async {
    final traceId = _generateTraceId();
    try {
      final uri = _buildUri(baseUrl, AppConfig.productsEndpoint);
      final response = await _client
          .post(
            uri,
            headers: _headers(traceId),
            body: jsonEncode(product.toJson()),
          )
          .timeout(AppConfig.requestTimeout);
      _updateTraceContext(response, traceId);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          if (decoded['product'] is Map<String, dynamic>) {
            return Product.fromJson(decoded['product'] as Map<String, dynamic>);
          }
          if (decoded.containsKey('id')) {
            return Product.fromJson(decoded);
          }
        }
        return product;
      } else {
        throw ApiException(
          'Failed to add product: ${response.body.isNotEmpty ? response.body : response.reasonPhrase}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException catch (e) {
      _currentTraceId = traceId;
      throw NetworkException('Network error: Cannot reach server at $baseUrl (${e.message})');
    } catch (e) {
      _currentTraceId = traceId;
      if (e is AppException) rethrow;
      throw ApiException('Error creating product: $e');
    }
  }

  /// PUT /api/products/:id
  Future<Product> updateProduct(String baseUrl, Product product) async {
    final traceId = _generateTraceId();
    try {
      final uri = _buildUri(baseUrl, '${AppConfig.productsEndpoint}/${product.id}');
      final response = await _client
          .put(
            uri,
            headers: _headers(traceId),
            body: jsonEncode(product.toJson()),
          )
          .timeout(AppConfig.requestTimeout);
      _updateTraceContext(response, traceId);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          if (decoded['product'] is Map<String, dynamic>) {
            return Product.fromJson(decoded['product'] as Map<String, dynamic>);
          }
          if (decoded.containsKey('id')) {
            return Product.fromJson(decoded);
          }
        }
        return product;
      } else {
        throw ApiException(
          'Failed to update product: ${response.body.isNotEmpty ? response.body : response.reasonPhrase}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException catch (e) {
      _currentTraceId = traceId;
      throw NetworkException('Network error: Cannot reach server at $baseUrl (${e.message})');
    } catch (e) {
      _currentTraceId = traceId;
      if (e is AppException) rethrow;
      throw ApiException('Error updating product: $e');
    }
  }

  /// DELETE /api/products/:id
  Future<void> deleteProduct(String baseUrl, String id) async {
    final traceId = _generateTraceId();
    try {
      final uri = _buildUri(baseUrl, '${AppConfig.productsEndpoint}/$id');
      final response = await _client
          .delete(uri, headers: _headers(traceId))
          .timeout(AppConfig.requestTimeout);
      _updateTraceContext(response, traceId);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          'Failed to delete product: ${response.body.isNotEmpty ? response.body : response.reasonPhrase}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException catch (e) {
      _currentTraceId = traceId;
      throw NetworkException('Network error: Cannot reach server at $baseUrl (${e.message})');
    } catch (e) {
      _currentTraceId = traceId;
      if (e is AppException) rethrow;
      throw ApiException('Error deleting product: $e');
    }
  }
}
