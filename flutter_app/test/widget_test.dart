import 'package:flutter_test/flutter_test.dart';
import 'package:product_manager/core/constants/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('SharedPreferences mock setup test', () async {
    SharedPreferences.setMockInitialValues({
      AppConfig.storageKeyBackendUrl: AppConfig.defaultBackendUrl,
    });
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(AppConfig.storageKeyBackendUrl), AppConfig.defaultBackendUrl);
  });
}
