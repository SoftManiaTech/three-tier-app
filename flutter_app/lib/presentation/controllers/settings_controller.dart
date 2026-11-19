import 'package:flutter/foundation.dart';
import '../../domain/repositories/settings_repository.dart';

enum ConnectionTestStatus { idle, testing, success, failure }

class SettingsController extends ChangeNotifier {
  final SettingsRepository repository;

  String _backendUrl = '';
  ConnectionTestStatus _testStatus = ConnectionTestStatus.idle;
  String? _statusMessage;
  bool _isLoading = true;

  SettingsController({required this.repository});

  String get backendUrl => _backendUrl;
  ConnectionTestStatus get testStatus => _testStatus;
  String? get statusMessage => _statusMessage;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    try {
      _backendUrl = await repository.getBackendUrl();
    } catch (_) {
      _backendUrl = 'http://localhost:5000';
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
