import 'package:flutter/foundation.dart';
import '../../core/constants/app_config.dart';
import '../../domain/repositories/settings_repository.dart';

enum ConnectionTestStatus { idle, testing, success, failure }

class SettingsController extends ChangeNotifier {
  final SettingsRepository repository;

  String _backendUrl = '';
  ConnectionTestStatus _testStatus = ConnectionTestStatus.idle;
  String? _statusMessage;
  bool _isLoading = true;

  // Dynamic Splunk RUM Configuration
  String _splunkRealm = AppConfig.defaultSplunkRealm;
  String _splunkRumToken = AppConfig.defaultSplunkRumToken;
  String _splunkAppName = AppConfig.defaultSplunkAppName;
  String _splunkEnvironment = AppConfig.defaultSplunkEnvironment;
  String _splunkAppVersion = AppConfig.defaultSplunkAppVersion;

  SettingsController({required this.repository});

  String get backendUrl => _backendUrl;
  String get currentTraceId => repository.currentTraceId;
  ConnectionTestStatus get testStatus => _testStatus;
  String? get statusMessage => _statusMessage;
  bool get isLoading => _isLoading;
  List<String> get presets => AppConfig.defaultPresets;

  String get splunkRealm => _splunkRealm;
  String get splunkRumToken => _splunkRumToken;
  String get splunkAppName => _splunkAppName;
  String get splunkEnvironment => _splunkEnvironment;
  String get splunkAppVersion => _splunkAppVersion;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    try {
      _backendUrl = await repository.getBackendUrl();
      final splunkConfig = await repository.getSplunkConfig();
      _splunkRealm = splunkConfig['realm'] ?? AppConfig.defaultSplunkRealm;
      _splunkRumToken = splunkConfig['token'] ?? AppConfig.defaultSplunkRumToken;
      _splunkAppName = splunkConfig['appName'] ?? AppConfig.defaultSplunkAppName;
      _splunkEnvironment = splunkConfig['environment'] ?? AppConfig.defaultSplunkEnvironment;
      _splunkAppVersion = splunkConfig['appVersion'] ?? AppConfig.defaultSplunkAppVersion;
    } catch (_) {
      _backendUrl = AppConfig.defaultBackendUrl;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveBackendUrl(String newUrl) async {
    final cleanUrl = newUrl.trim();
    if (cleanUrl.isEmpty) return false;
    try {
      await repository.saveBackendUrl(cleanUrl);
      _backendUrl = cleanUrl;
      _testStatus = ConnectionTestStatus.idle;
      _statusMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _statusMessage = 'Failed to save URL: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveSplunkConfig({
    required String realm,
    required String token,
    required String appName,
    required String environment,
    required String appVersion,
  }) async {
    try {
      await repository.saveSplunkConfig(
        realm: realm.trim(),
        token: token.trim(),
        appName: appName.trim(),
        environment: environment.trim(),
        appVersion: appVersion.trim(),
      );
      _splunkRealm = realm.trim();
      _splunkRumToken = token.trim();
      _splunkAppName = appName.trim();
      _splunkEnvironment = environment.trim();
      _splunkAppVersion = appVersion.trim();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[SettingsController] Failed saving Splunk config: $e');
      return false;
    }
  }

  Future<bool> testConnection(String urlToTest) async {
    final target = urlToTest.trim().isEmpty ? _backendUrl : urlToTest.trim();
    _testStatus = ConnectionTestStatus.testing;
    _statusMessage = 'Pinging $target...';
    notifyListeners();

    try {
      final success = await repository.testConnection(target);
      if (success) {
        _testStatus = ConnectionTestStatus.success;
        _statusMessage = 'Connected successfully to backend!';
      } else {
        _testStatus = ConnectionTestStatus.failure;
        _statusMessage = 'Could not connect. Ensure server is running and reachable.';
      }
      notifyListeners();
      return success;
    } catch (e) {
      _testStatus = ConnectionTestStatus.failure;
      _statusMessage = 'Connection failed: $e';
      notifyListeners();
      return false;
    }
  }

  void resetTestStatus() {
    _testStatus = ConnectionTestStatus.idle;
    _statusMessage = null;
    notifyListeners();
  }
}
