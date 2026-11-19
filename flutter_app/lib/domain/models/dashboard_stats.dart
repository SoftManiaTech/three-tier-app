import 'product.dart';

class DashboardStats {
  final int totalProducts;
  final int totalCategories;
  final double totalInventoryValue;
  final Map<String, int> categoryCounts;
  final Map<String, double> categoryValues;

  const DashboardStats({
    required this.totalProducts,
    required this.totalCategories,
    required this.totalInventoryValue,
    required this.categoryCounts,
    required this.categoryValues,
  });

  factory DashboardStats.empty() {
    return const DashboardStats(
      totalProducts: 0,
      totalCategories: 0,
      totalInventoryValue: 0.0,
      categoryCounts: {},
      categoryValues: {},
    );
  }

  factory DashboardStats.fromProducts(
    List<Product> products,
    List<String> knownCategories,
  ) {
    final Set<String> categoriesSet = {};
    final Map<String, int> counts = {};
    final Map<String, double> values = {};
    double totalVal = 0.0;

    for (final cat in knownCategories) {
      if (cat.trim().isNotEmpty) {
        categoriesSet.add(cat.trim());
        counts[cat.trim()] = 0;
        values[cat.trim()] = 0.0;
      }
    }

    for (final p in products) {
      final cat = p.category.trim().isEmpty ? 'General' : p.category.trim();
      categoriesSet.add(cat);
      counts[cat] = (counts[cat] ?? 0) + 1;
      values[cat] = (values[cat] ?? 0.0) + p.price;
      totalVal += p.price;
    }

    return DashboardStats(
      totalProducts: products.length,
      totalCategories: categoriesSet.length,
      totalInventoryValue: totalVal,
      categoryCounts: counts,
      categoryValues: values,
    );
  }
}
