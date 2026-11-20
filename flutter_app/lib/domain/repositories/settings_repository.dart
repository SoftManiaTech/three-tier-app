abstract class SettingsRepository {
  /// Current W3C OpenTelemetry Trace ID
  String get currentTraceId;

  /// Retrieves the saved backend base URL
  Future<String> getBackendUrl();

  /// Saves a new backend base URL to persistent storage
  Future<void> saveBackendUrl(String url);

  /// Tests connectivity to a given backend base URL
  Future<bool> testConnection(String url);

  /// Retrieves dynamic Splunk RUM configuration map
  Future<Map<String, String>> getSplunkConfig();

  /// Saves dynamic Splunk RUM configuration parameters
  Future<void> saveSplunkConfig({
    required String realm,
    required String token,
    required String appName,
    required String environment,
    required String appVersion,
  });
}
