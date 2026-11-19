import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('SharedPreferences mock setup test', () async {
    SharedPreferences.setMockInitialValues({'pm_backend_url': 'http://localhost:5000'});
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('pm_backend_url'), 'http://localhost:5000');
  });
}
