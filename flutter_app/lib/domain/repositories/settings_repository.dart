abstract class SettingsRepository {
  /// Retrieves the saved backend base URL
  Future<String> getBackendUrl();

  /// Saves a new backend base URL to persistent storage
  Future<void> saveBackendUrl(String url);

  /// Tests connectivity to a given backend base URL
  Future<bool> testConnection(String url);
}
