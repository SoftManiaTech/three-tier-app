import '../models/product.dart';

abstract class ProductRepository {
  /// Fetches products, optionally filtered by category
  Future<List<Product>> getProducts({String? category});

  /// Fetches all active distinct categories
  Future<List<String>> getCategories();

  /// Creates a new product
  Future<Product> createProduct(Product product);

  /// Updates an existing product by ID
  Future<Product> updateProduct(Product product);

  /// Deletes a product by ID
  Future<void> deleteProduct(String id);
}
