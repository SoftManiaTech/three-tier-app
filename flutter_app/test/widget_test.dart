import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:product_manager/core/constants/app_config.dart';
import 'package:product_manager/data/datasources/product_api_service.dart';
import 'package:product_manager/data/datasources/settings_local_storage.dart';
import 'package:product_manager/data/repositories/product_repository_impl.dart';
import 'package:product_manager/data/repositories/settings_repository_impl.dart';
import 'package:product_manager/presentation/controllers/product_controller.dart';
import 'package:product_manager/presentation/controllers/settings_controller.dart';
import 'package:product_manager/presentation/screens/main_navigation_screen.dart';
import 'package:provider/provider.dart';
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

  testWidgets('Zero layout overlap on narrow mobile screen (320px)', (tester) async {
    SharedPreferences.setMockInitialValues({
      AppConfig.storageKeyBackendUrl: AppConfig.defaultBackendUrl,
    });

    final localStorage = SettingsLocalStorage();
    final apiService = ProductApiService();
    final settingsRepo = SettingsRepositoryImpl(localStorage: localStorage, apiService: apiService);
    final productRepo = ProductRepositoryImpl(apiService: apiService, settingsRepository: settingsRepo);
    final settingsCtrl = SettingsController(repository: settingsRepo);
    final productCtrl = ProductController(repository: productRepo);

    // Set tight mobile screen size: 320x640
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsController>.value(value: settingsCtrl),
          ChangeNotifierProvider<ProductController>.value(value: productCtrl),
        ],
        child: const MaterialApp(
          home: MainNavigationScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify trace ID pill is rendered
    expect(find.textContaining('trace:'), findsOneWidget);

    // Verify SoftMania learning icon is rendered
    expect(find.byIcon(Icons.school_rounded), findsWidgets);

    // Verify no RenderFlex overflow error occurred
    expect(tester.takeException(), isNull);
  });
}
