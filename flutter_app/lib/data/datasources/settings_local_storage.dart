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

  // Dynamic Splunk Observability Cloud Configuration
  Future<String> getSplunkRealm() async {
    final prefs = await _getPrefs();
    return prefs.getString(AppConfig.storageKeySplunkRealm) ?? AppConfig.defaultSplunkRealm;
  }

  Future<void> saveSplunkRealm(String realm) async {
    final prefs = await _getPrefs();
    await prefs.setString(AppConfig.storageKeySplunkRealm, realm.trim());
  }

  Future<String> getSplunkRumToken() async {
    final prefs = await _getPrefs();
    return prefs.getString(AppConfig.storageKeySplunkRumToken) ?? AppConfig.defaultSplunkRumToken;
  }

  Future<void> saveSplunkRumToken(String token) async {
    final prefs = await _getPrefs();
    await prefs.setString(AppConfig.storageKeySplunkRumToken, token.trim());
  }

  Future<String> getSplunkAppName() async {
    final prefs = await _getPrefs();
    return prefs.getString(AppConfig.storageKeySplunkAppName) ?? AppConfig.defaultSplunkAppName;
  }

  Future<void> saveSplunkAppName(String appName) async {
    final prefs = await _getPrefs();
    await prefs.setString(AppConfig.storageKeySplunkAppName, appName.trim());
  }

  Future<String> getSplunkEnvironment() async {
    final prefs = await _getPrefs();
    return prefs.getString(AppConfig.storageKeySplunkEnvironment) ?? AppConfig.defaultSplunkEnvironment;
  }

  Future<void> saveSplunkEnvironment(String env) async {
    final prefs = await _getPrefs();
    await prefs.setString(AppConfig.storageKeySplunkEnvironment, env.trim());
  }

  Future<String> getSplunkAppVersion() async {
    final prefs = await _getPrefs();
    return prefs.getString(AppConfig.storageKeySplunkAppVersion) ?? AppConfig.defaultSplunkAppVersion;
  }

  Future<void> saveSplunkAppVersion(String version) async {
    final prefs = await _getPrefs();
    await prefs.setString(AppConfig.storageKeySplunkAppVersion, version.trim());
  }
}
