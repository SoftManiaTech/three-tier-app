import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_config.dart';

class SettingsLocalStorage {
  final SharedPreferences? _prefs;

  SettingsLocalStorage([this._prefs]);

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  String getDefaultUrl() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return AppConfig.defaultAndroidBackendUrl;
    }
    return AppConfig.defaultBackendUrl;
  }

  Future<String> getBackendUrl() async {
    final prefs = await _getPrefs();
    final saved = prefs.getString(AppConfig.storageKeyBackendUrl);
    if (saved != null && saved.trim().isNotEmpty) {
      return saved.trim();
    }
    return getDefaultUrl();
  }

  Future<void> saveBackendUrl(String url) async {
    final prefs = await _getPrefs();
    await prefs.setString(AppConfig.storageKeyBackendUrl, url.trim());
  }
}
