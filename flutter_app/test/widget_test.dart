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
import 'package:product_manager/presentation/screens/settings_page.dart';
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

  testWidgets('Settings page: URL input field clears to empty state and validates empty input', (tester) async {
    SharedPreferences.setMockInitialValues({
      AppConfig.storageKeyBackendUrl: AppConfig.defaultBackendUrl,
    });

    final localStorage = SettingsLocalStorage();
    final apiService = ProductApiService();
    final settingsRepo = SettingsRepositoryImpl(localStorage: localStorage, apiService: apiService);
    final productRepo = ProductRepositoryImpl(apiService: apiService, settingsRepository: settingsRepo);
    final settingsCtrl = SettingsController(repository: settingsRepo);
    final productCtrl = ProductController(repository: productRepo);
    await settingsCtrl.init();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsController>.value(value: settingsCtrl),
          ChangeNotifierProvider<ProductController>.value(value: productCtrl),
        ],
        child: const MaterialApp(
          home: SettingsPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify initial text matches default backend URL
    final initialTextField = tester.widget<TextField>(find.byType(TextField).first);
    expect(initialTextField.controller!.text, AppConfig.defaultBackendUrl);

    // 2. Tap clear button (suffix icon)
    final clearBtn = find.byTooltip('Clear input field');
    expect(clearBtn, findsOneWidget);
    await tester.tap(clearBtn);
    await tester.pumpAndSettle();

    // 3. Verify input field is now empty and does NOT restore automatically
    final textFieldFinder = find.byType(TextField).first;
    final textFieldWidget = tester.widget<TextField>(textFieldFinder);
    expect(textFieldWidget.controller!.text, isEmpty);

    // 4. Tap 'Save & Apply' with empty text to validate error handling
    final saveBtn = find.widgetWithText(ElevatedButton, 'Save & Apply');
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();

    // 5. Verify error validation message is displayed
    expect(find.textContaining('Backend API URL cannot be empty'), findsOneWidget);
  });

  testWidgets('Settings page: Splunk RUM card has zero overlap on narrow 320px mobile viewport', (tester) async {
    SharedPreferences.setMockInitialValues({
      AppConfig.storageKeyBackendUrl: AppConfig.defaultBackendUrl,
    });

    final localStorage = SettingsLocalStorage();
    final apiService = ProductApiService();
    final settingsRepo = SettingsRepositoryImpl(localStorage: localStorage, apiService: apiService);
    final productRepo = ProductRepositoryImpl(apiService: apiService, settingsRepository: settingsRepo);
    final settingsCtrl = SettingsController(repository: settingsRepo);
    final productCtrl = ProductController(repository: productRepo);
    await settingsCtrl.init();

    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsController>.value(value: settingsCtrl),
          ChangeNotifierProvider<ProductController>.value(value: productCtrl),
        ],
        child: const MaterialApp(
          home: SettingsPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Splunk RUM Card elements are visible
    expect(find.textContaining('Splunk RUM'), findsOneWidget);
    expect(find.textContaining('Realm: au0'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Edit Telemetry Config'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Generate RUM Activity'), findsOneWidget);

    // Verify zero RenderFlex overflow occurred
    expect(tester.takeException(), isNull);
  });

  testWidgets('Settings page: RUM card and action buttons have zero overlap across multiple device viewports (320, 360, 390, 412, 768px)', (tester) async {
    SharedPreferences.setMockInitialValues({
      AppConfig.storageKeyBackendUrl: AppConfig.defaultBackendUrl,
    });

    final localStorage = SettingsLocalStorage();
    final apiService = ProductApiService();
    final settingsRepo = SettingsRepositoryImpl(localStorage: localStorage, apiService: apiService);
    final productRepo = ProductRepositoryImpl(apiService: apiService, settingsRepository: settingsRepo);
    final settingsCtrl = SettingsController(repository: settingsRepo);
    final productCtrl = ProductController(repository: productRepo);
    await settingsCtrl.init();

    final testWidths = [320.0, 360.0, 390.0, 412.0, 768.0];

    for (final width in testWidths) {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SettingsController>.value(value: settingsCtrl),
            ChangeNotifierProvider<ProductController>.value(value: productCtrl),
          ],
          child: const MaterialApp(
            home: SettingsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'Failed with overflow at width $width');
      expect(find.text('Splunk RUM'), findsOneWidget);
      expect(find.text('Realm: au0'), findsOneWidget);
      expect(find.text('Generate RUM Activity'), findsOneWidget);
    }

    tester.view.resetPhysicalSize();
  });
}
