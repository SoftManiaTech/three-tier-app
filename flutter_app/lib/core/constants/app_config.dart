/// Application Single Source of Truth (SSOT) configuration
class AppConfig {
  static const String appName = 'Product Manager';
  static const String appTagline = 'Inventory & Catalog Management';

  // Default Backend URL fallbacks
  static const String defaultBackendUrl = 'http://localhost:5000';
  static const String defaultAndroidBackendUrl = 'http://10.0.2.2:5000';
  static const String storageKeyBackendUrl = 'pm_backend_url';

  // Quick Preset URLs
  static const List<String> defaultPresets = [
    'http://localhost:5000',
    'http://localhost:8000',
    'http://10.0.2.2:5000',
    'http://127.0.0.1:3000',
  ];

  // Splunk Observability Cloud RUM Configuration
  static const String defaultSplunkRealm = 'au0';
  static const String defaultSplunkRumToken = 'Vzad6YH5sdprluV2gjLGPw';
  static const String defaultSplunkAppName = 'three-tier-product-frontend';
  static const String defaultSplunkEnvironment = 'production';
  static const String defaultSplunkAppVersion = '1.0.0';

  // Splunk Local Storage Keys
  static const String storageKeySplunkRumEnabled = 'pm_splunk_rum_enabled';
  static const String storageKeySplunkRumToken = 'pm_splunk_rum_token';
  static const String storageKeySplunkRealm = 'pm_splunk_realm';
  static const String storageKeySplunkAppName = 'pm_splunk_app_name';
  static const String storageKeySplunkEnvironment = 'pm_splunk_environment';
  static const String storageKeySplunkAppVersion = 'pm_splunk_app_version';

  // API Endpoints
  static const String productsEndpoint = '/api/products';
  static const String categoriesEndpoint = '/api/categories';

  // UI Constants
  static const String currencySymbol = '₹';
  static const Duration requestTimeout = Duration(seconds: 10);
  static const Duration testConnectionTimeout = Duration(seconds: 5);
}
