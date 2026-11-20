import 'package:flutter/foundation.dart';
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';
import '../../core/constants/app_config.dart';
import '../../domain/models/dashboard_stats.dart';
import '../../domain/models/product.dart';

class SplunkRumService {
  static bool _isInstalled = false;
  static bool get isInstalled => _isInstalled;

  /// Initializes Splunk RUM dynamically
  static Future<bool> initialize({
    String realm = AppConfig.defaultSplunkRealm,
    String token = AppConfig.defaultSplunkRumToken,
    String appName = AppConfig.defaultSplunkAppName,
    String environment = AppConfig.defaultSplunkEnvironment,
    String appVersion = AppConfig.defaultSplunkAppVersion,
  }) async {
    if (_isInstalled) return true;

    // Splunk Otel Flutter mobile agent natively instruments Android & iOS
    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS)) {
      debugPrint('[Splunk RUM] Current platform ($defaultTargetPlatform) is desktop/web. Native mobile agent initialized in mock/fallback mode.');
      _isInstalled = true;
      return true;
    }

    try {
      await SplunkRum.instance.install(
        agentConfiguration: AgentConfiguration(
          endpoint: EndpointConfiguration.forRum(
            realm: realm,
            rumAccessToken: token,
          ),
          appName: appName,
          deploymentEnvironment: environment,
          appVersion: appVersion,
          enableDebugLogging: true,
        ),
      );
      _isInstalled = true;
      debugPrint('[Splunk RUM] Agent installed successfully for $appName in $environment ($realm)');
      return true;
    } catch (e) {
      debugPrint('[Splunk RUM] Failed to install agent: $e');
      return false;
    }
  }

  /// Tracks custom user events in Splunk RUM
  static Future<void> trackCustomEvent(String name, [Map<String, dynamic>? attributes]) async {
    debugPrint('[Splunk RUM] Event tracked: $name with $attributes');
    if (!_isInstalled) return;

    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      try {
        final mutableAttrs = <String, MutableAttributeValue>{};
        if (attributes != null) {
          attributes.forEach((key, val) {
            if (val is String) {
              mutableAttrs[key] = MutableAttributeString(value: val);
            } else if (val is int) {
              mutableAttrs[key] = MutableAttributeInt(value: val);
            } else if (val is double) {
              mutableAttrs[key] = MutableAttributeDouble(value: val);
            } else if (val is bool) {
              mutableAttrs[key] = MutableAttributeBool(value: val);
            }
          });
        }
        await SplunkRum.instance.customTracking.trackCustomEvent(
          name: name,
          attributes: MutableAttributes(attributes: mutableAttrs),
        );
      } catch (e) {
        debugPrint('[Splunk RUM] Error dispatching custom event: $e');
      }
    }
  }

  /// Automatically generates sample user interactions to populate Splunk RUM
  /// using dynamic runtime state from the catalog and settings
  static Future<void> generateSampleActivity({
    DashboardStats? stats,
    List<Product>? products,
    String? backendUrl,
  }) async {
    debugPrint('[Splunk RUM] Generating sample user interactions for Splunk Observability Cloud...');

    await trackCustomEvent('app_launch', {
      'screen': 'dashboard',
      'device_type': defaultTargetPlatform.name,
      'is_web': kIsWeb,
    });

    final totalProducts = stats?.totalProducts ?? products?.length ?? 0;
    final totalCategories = stats?.totalCategories ?? 0;
    final totalValue = stats?.totalInventoryValue ?? 0.0;

    await trackCustomEvent('view_dashboard_metrics', {
      'total_products': totalProducts,
      'active_categories': totalCategories,
      'total_value': totalValue,
    });

    if (products != null && products.isNotEmpty) {
      final sampleProduct = products.first;
      final categoryMatches = products.where((p) => p.category == sampleProduct.category).length;

      await trackCustomEvent('filter_category', {
        'category': sampleProduct.category,
        'results_count': categoryMatches,
      });

      await trackCustomEvent('product_interaction', {
        'action': 'view_details',
        'product_name': sampleProduct.name,
        'price': sampleProduct.price,
      });

      // Sample a second category if available
      if (products.length > 1) {
        final secondProduct = products.last;
        if (secondProduct.category != sampleProduct.category) {
          await trackCustomEvent('filter_category', {
            'category': secondProduct.category,
            'results_count': products.where((p) => p.category == secondProduct.category).length,
          });
        }
      }
    }

    if (backendUrl != null && backendUrl.isNotEmpty) {
      await trackCustomEvent('settings_accessed', {
        'backend_url': backendUrl,
        'connection_test': 'success',
      });
    }

    debugPrint('[Splunk RUM] Sample interactions generated and dispatched dynamically.');
  }
}
