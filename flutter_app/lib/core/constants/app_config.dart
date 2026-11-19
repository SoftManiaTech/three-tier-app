/// Application Single Source of Truth (SSOT) configuration
class AppConfig {
  static const String appName = 'Product Manager';
  static const String appTagline = 'Inventory & Catalog Management';

  // Default Backend URL fallbacks
  static const String defaultBackendUrl = 'http://localhost:5000';
  static const String defaultAndroidBackendUrl = 'http://10.0.2.2:5000';
  static const String storageKeyBackendUrl = 'pm_backend_url';

  // API Endpoints
  static const String productsEndpoint = '/api/products';
  static const String categoriesEndpoint = '/api/categories';

  // UI Constants
  static const String currencySymbol = '₹';
  static const Duration requestTimeout = Duration(seconds: 10);
  static const Duration testConnectionTimeout = Duration(seconds: 5);
}
