import 'package:flutter/foundation.dart';
import '../../core/errors/exceptions.dart';
import '../../data/datasources/splunk_rum_service.dart';
import '../../domain/models/dashboard_stats.dart';
import '../../domain/models/product.dart';
import '../../domain/repositories/product_repository.dart';

class ProductController extends ChangeNotifier {
  final ProductRepository repository;

  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<String> _categories = [];
  String _selectedCategory = '';
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  ProductController({required this.repository});

  List<Product> get products => _products;
  List<Product> get filteredProducts => _filteredProducts;
  List<String> get categories => _categories;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String get currentTraceId => repository.currentTraceId;

  DashboardStats get stats => DashboardStats.fromProducts(_products, _categories);

  /// Initial load or full refresh
  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetchedCategories = await repository.getCategories();
      final fetchedProducts = await repository.getProducts();

      _products = fetchedProducts;
      _categories = fetchedCategories;

      // Ensure all product categories are known
      final Set<String> catSet = Set.from(_categories);
      for (final p in _products) {
        if (p.category.trim().isNotEmpty) {
          catSet.add(p.category.trim());
        }
      }
      _categories = catSet.toList()..sort();

      _applyFilters();
    } on AppException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCategoryFilter(String category) {
    setCategoryFilterLive(category);
  }

  /// Sets category filter and triggers a live backend fetch for that category
  Future<void> setCategoryFilterLive(String category) async {
    _selectedCategory = category.trim();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    SplunkRumService.trackCustomEvent('category_filter_selected', {'category': _selectedCategory});

    try {
      final liveProducts = await repository.getProducts(
        category: _selectedCategory.isNotEmpty ? _selectedCategory : null,
      );
      if (_selectedCategory.isEmpty) {
        _products = liveProducts;
      }
      _filteredProducts = liveProducts;
      if (_searchQuery.isNotEmpty) {
        _filteredProducts = _filteredProducts.where((p) {
          final nameMatch = p.name.toLowerCase().contains(_searchQuery);
          final descMatch = p.description.toLowerCase().contains(_searchQuery);
          final catMatch = p.category.toLowerCase().contains(_searchQuery);
          return nameMatch || descMatch || catMatch;
        }).toList();
      }
    } on AppException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to fetch live data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _selectedCategory = '';
    _searchQuery = '';
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    List<Product> list = List.from(_products);

    if (_selectedCategory.isNotEmpty) {
      list = list.where((p) =>
          p.category.trim().toLowerCase() == _selectedCategory.toLowerCase()).toList();
    }

    if (_searchQuery.isNotEmpty) {
      list = list.where((p) {
        final nameMatch = p.name.toLowerCase().contains(_searchQuery);
        final descMatch = p.description.toLowerCase().contains(_searchQuery);
        final catMatch = p.category.toLowerCase().contains(_searchQuery);
        return nameMatch || descMatch || catMatch;
      }).toList();
    }

    _filteredProducts = list;
  }

  /// Create product
  Future<bool> createProduct(Product product) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final created = await repository.createProduct(product);
      _products.insert(0, created);
      SplunkRumService.trackCustomEvent('product_created', {
        'name': created.name,
        'category': created.category,
        'price': created.price,
      });
      if (!_categories.contains(created.category) && created.category.isNotEmpty) {
        _categories.add(created.category);
        _categories.sort();
      }
      _applyFilters();
      _isSaving = false;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      _isSaving = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to create product: $e';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  /// Update product
  Future<bool> updateProduct(Product product) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await repository.updateProduct(product);
      final index = _products.indexWhere((p) => p.id == updated.id);
      if (index != -1) {
        _products[index] = updated;
      } else {
        _products.insert(0, updated);
      }
      SplunkRumService.trackCustomEvent('product_updated', {
        'id': updated.id,
        'name': updated.name,
        'price': updated.price,
      });
      if (!_categories.contains(updated.category) && updated.category.isNotEmpty) {
        _categories.add(updated.category);
        _categories.sort();
      }
      _applyFilters();
      _isSaving = false;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      _isSaving = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update product: $e';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete product
  Future<bool> deleteProduct(String id) async {
    _errorMessage = null;
    try {
      await repository.deleteProduct(id);
      _products.removeWhere((p) => p.id == id);
      SplunkRumService.trackCustomEvent('product_deleted', {'id': id});
      _applyFilters();
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to delete product: $e';
      notifyListeners();
      return false;
    }
  }
}
