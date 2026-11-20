import 'package:flutter_test/flutter_test.dart';
import 'package:product_manager/core/constants/app_config.dart';
import 'package:product_manager/core/utils/formatters.dart';
import 'package:product_manager/data/repositories/product_repository_impl.dart';
import 'package:product_manager/data/repositories/settings_repository_impl.dart';
import 'package:product_manager/domain/models/dashboard_stats.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Live Local Backend Integration Test (Dynamic Port/Config)', () {
    const String testBackendUrl = AppConfig.defaultBackendUrl;

    setUp(() {
      SharedPreferences.setMockInitialValues({
        AppConfig.storageKeyBackendUrl: testBackendUrl,
      });
    });

    test('1. Test Connection (Ping) succeeds against live backend', () async {
      final settingsRepo = SettingsRepositoryImpl();
      final isOnline = await settingsRepo.testConnection(testBackendUrl);
      expect(isOnline, isTrue, reason: 'Backend on $testBackendUrl should respond to ping');
    });

    test('2. Fetch categories returns live active categories', () async {
      final settingsRepo = SettingsRepositoryImpl();
      final productRepo = ProductRepositoryImpl(settingsRepository: settingsRepo);

      final categories = await productRepo.getCategories();
      expect(categories, isNotEmpty);
      expect(categories, contains('Electronics'));
    });

    test('3. Fetch products parses real data & computes accurate inventory stats', () async {
      final settingsRepo = SettingsRepositoryImpl();
      final productRepo = ProductRepositoryImpl(settingsRepository: settingsRepo);

      final products = await productRepo.getProducts();
      expect(products, isNotEmpty);
      expect(products.length, greaterThanOrEqualTo(1));

      final firstProduct = products.firstWhere((p) => p.name.contains('Gaming Monitor'));
      expect(firstProduct.category, 'Electronics');
      expect(firstProduct.price, greaterThan(0));

      final categories = await productRepo.getCategories();
      final stats = DashboardStats.fromProducts(products, categories);

      expect(stats.totalProducts, products.length);
      expect(stats.totalCategories, greaterThanOrEqualTo(1));
      expect(stats.totalInventoryValue, greaterThan(0));

      final formattedTotal = Formatters.formatCurrency(stats.totalInventoryValue);
      expect(formattedTotal, contains(AppConfig.currencySymbol));
    });
  });
}
