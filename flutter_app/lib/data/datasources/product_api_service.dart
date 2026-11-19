import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/constants/app_config.dart';
import '../../core/errors/exceptions.dart';
import '../../domain/models/product.dart';

class ProductApiService {
  final http.Client _client;

  ProductApiService({http.Client? client}) : _client = client ?? http.Client();

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

  Map<String, String> _headers() => {
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=UTF-8',
        'ngrok-skip-browser-warning': 'true',
      };

  /// Tests connectivity to the backend
  Future<bool> ping(String baseUrl) async {
    try {
      final uri = _buildUri(baseUrl, AppConfig.productsEndpoint);
      final response = await _client
          .get(uri, headers: _headers())
          .timeout(AppConfig.testConnectionTimeout);
      return response.statusCode >= 200 && response.statusCode < 400;
    } catch (_) {
      return false;
    }
  }

  /// GET /api/products (optional category filter)
  Future<List<Product>> fetchProducts(String baseUrl, {String? category}) async {
    try {
      final queryParams = (category != null && category.trim().isNotEmpty)
          ? {'category': category.trim()}
          : null;
      final uri = _buildUri(baseUrl, AppConfig.productsEndpoint, queryParams);

      final response = await _client
          .get(uri, headers: _headers())
          .timeout(AppConfig.requestTimeout);

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
      throw NetworkException('Network error: Cannot reach server at $baseUrl (${e.message})');
    } on http.ClientException catch (e) {
      throw NetworkException('Connection failed: ${e.message}');
    } catch (e) {
      if (e is AppException) rethrow;
      throw ApiException('Unexpected error while fetching products: $e');
    }
  }

  /// GET /api/categories
  Future<List<String>> fetchCategories(String baseUrl) async {
    try {
      final uri = _buildUri(baseUrl, AppConfig.categoriesEndpoint);
      final response = await _client
          .get(uri, headers: _headers())
          .timeout(AppConfig.requestTimeout);

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
      // If categories endpoint is not implemented, return empty and let repository fallback
      return [];
    }
  }

  /// POST /api/products
  Future<Product> addProduct(String baseUrl, Product product) async {
    try {
      final uri = _buildUri(baseUrl, AppConfig.productsEndpoint);
      final response = await _client
          .post(
            uri,
            headers: _headers(),
            body: jsonEncode(product.toJson()),
          )
          .timeout(AppConfig.requestTimeout);

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
        // Fallback: return product with generated or returned ID
        return product;
      } else {
        throw ApiException(
          'Failed to add product: ${response.body.isNotEmpty ? response.body : response.reasonPhrase}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException catch (e) {
      throw NetworkException('Network error: Cannot reach server at $baseUrl (${e.message})');
    } catch (e) {
      if (e is AppException) rethrow;
      throw ApiException('Error creating product: $e');
    }
  }

  /// PUT /api/products/:id
  Future<Product> updateProduct(String baseUrl, Product product) async {
    try {
      final uri = _buildUri(baseUrl, '${AppConfig.productsEndpoint}/${product.id}');
      final response = await _client
          .put(
            uri,
            headers: _headers(),
            body: jsonEncode(product.toJson()),
          )
          .timeout(AppConfig.requestTimeout);

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
      throw NetworkException('Network error: Cannot reach server at $baseUrl (${e.message})');
    } catch (e) {
      if (e is AppException) rethrow;
      throw ApiException('Error updating product: $e');
    }
  }

  /// DELETE /api/products/:id
  Future<void> deleteProduct(String baseUrl, String id) async {
    try {
      final uri = _buildUri(baseUrl, '${AppConfig.productsEndpoint}/$id');
      final response = await _client
          .delete(uri, headers: _headers())
          .timeout(AppConfig.requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          'Failed to delete product: ${response.body.isNotEmpty ? response.body : response.reasonPhrase}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException catch (e) {
      throw NetworkException('Network error: Cannot reach server at $baseUrl (${e.message})');
    } catch (e) {
      if (e is AppException) rethrow;
      throw ApiException('Error deleting product: $e');
    }
  }
}
