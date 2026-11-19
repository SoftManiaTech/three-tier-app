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
}
