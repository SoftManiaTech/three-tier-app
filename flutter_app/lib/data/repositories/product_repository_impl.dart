import '../../domain/models/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/product_api_service.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductApiService _apiService;
  final SettingsRepository settingsRepository;

  ProductRepositoryImpl({
    ProductApiService? apiService,
    required this.settingsRepository,
  }) : _apiService = apiService ?? ProductApiService();

  Future<String> _getBaseUrl() => settingsRepository.getBackendUrl();

  @override
  Future<List<Product>> getProducts({String? category}) async {
    final baseUrl = await _getBaseUrl();
    return _apiService.fetchProducts(baseUrl, category: category);
  }

  @override
  Future<List<String>> getCategories() async {
    final baseUrl = await _getBaseUrl();
    final apiCategories = await _apiService.fetchCategories(baseUrl);
    if (apiCategories.isNotEmpty) {
      return apiCategories;
    }
    // Fallback: derive categories from products
    final products = await _apiService.fetchProducts(baseUrl);
    final Set<String> extracted = {};
    for (final p in products) {
      if (p.category.trim().isNotEmpty) {
        extracted.add(p.category.trim());
      }
    }
    return extracted.toList()..sort();
  }

  @override
  Future<Product> createProduct(Product product) async {
    final baseUrl = await _getBaseUrl();
    return _apiService.addProduct(baseUrl, product);
  }

  @override
  Future<Product> updateProduct(Product product) async {
    final baseUrl = await _getBaseUrl();
    return _apiService.updateProduct(baseUrl, product);
  }

  @override
  Future<void> deleteProduct(String id) async {
    final baseUrl = await _getBaseUrl();
    return _apiService.deleteProduct(baseUrl, id);
  }
}
