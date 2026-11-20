import '../../domain/repositories/settings_repository.dart';
import '../datasources/product_api_service.dart';
import '../datasources/settings_local_storage.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalStorage _localStorage;
  final ProductApiService _apiService;

  SettingsRepositoryImpl({
    SettingsLocalStorage? localStorage,
    ProductApiService? apiService,
  })  : _localStorage = localStorage ?? SettingsLocalStorage(),
        _apiService = apiService ?? ProductApiService();

  @override
  Future<String> getBackendUrl() {
    return _localStorage.getBackendUrl();
  }

  @override
  Future<void> saveBackendUrl(String url) {
    return _localStorage.saveBackendUrl(url);
  }

  @override
  Future<bool> testConnection(String url) {
    return _apiService.ping(url);
  }

  @override
  Future<Map<String, String>> getSplunkConfig() async {
    final realm = await _localStorage.getSplunkRealm();
    final token = await _localStorage.getSplunkRumToken();
    final appName = await _localStorage.getSplunkAppName();
    final environment = await _localStorage.getSplunkEnvironment();
    final appVersion = await _localStorage.getSplunkAppVersion();

    return {
      'realm': realm,
      'token': token,
      'appName': appName,
      'environment': environment,
      'appVersion': appVersion,
    };
  }

  @override
  Future<void> saveSplunkConfig({
    required String realm,
    required String token,
    required String appName,
    required String environment,
    required String appVersion,
  }) async {
    await _localStorage.saveSplunkRealm(realm);
    await _localStorage.saveSplunkRumToken(token);
    await _localStorage.saveSplunkAppName(appName);
    await _localStorage.saveSplunkEnvironment(environment);
    await _localStorage.saveSplunkAppVersion(appVersion);
  }
}
