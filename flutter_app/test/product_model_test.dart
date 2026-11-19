import 'package:flutter_test/flutter_test.dart';
import 'package:product_manager/domain/models/product.dart';
import 'package:product_manager/domain/models/dashboard_stats.dart';

void main() {
  group('Product Model & Stats Tests', () {
    test('Product JSON serialization and deserialization works accurately', () {
      final json = {
        'id': '101',
        'name': 'Mechanical Keyboard',
        'category': 'Electronics',
        'price': 2499.50,
        'description': 'RGB Backlit Mechanical Keyboard',
        'created_at': '2026-11-19 14:00:00',
      };

      final product = Product.fromJson(json);

      expect(product.id, '101');
      expect(product.name, 'Mechanical Keyboard');
      expect(product.category, 'Electronics');
      expect(product.price, 2499.50);
      expect(product.description, 'RGB Backlit Mechanical Keyboard');

      final serialized = product.toJson(includeId: true);
      expect(serialized['id'], '101');
      expect(serialized['name'], 'Mechanical Keyboard');
      expect(serialized['price'], 2499.50);
    });

    test('DashboardStats computes counts, totals and category valuation correctly', () {
      final products = [
        const Product(id: '1', name: 'Item A', category: 'Tech', price: 100.0),
        const Product(id: '2', name: 'Item B', category: 'Tech', price: 200.0),
        const Product(id: '3', name: 'Item C', category: 'Books', price: 50.0),
      ];

      final stats = DashboardStats.fromProducts(products, ['Tech', 'Books', 'Clothing']);

      expect(stats.totalProducts, 3);
      expect(stats.totalCategories, 3); // Tech, Books, Clothing
      expect(stats.totalInventoryValue, 350.0);
      expect(stats.categoryCounts['Tech'], 2);
      expect(stats.categoryCounts['Books'], 1);
      expect(stats.categoryValues['Tech'], 300.0);
      expect(stats.categoryValues['Books'], 50.0);
    });
  });
}
