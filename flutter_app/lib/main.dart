import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_config.dart';
import 'data/datasources/product_api_service.dart';
import 'data/datasources/settings_local_storage.dart';
import 'data/datasources/splunk_rum_service.dart';
import 'data/repositories/product_repository_impl.dart';
import 'data/repositories/settings_repository_impl.dart';
import 'domain/repositories/product_repository.dart';
import 'domain/repositories/settings_repository.dart';
import 'presentation/controllers/product_controller.dart';
import 'presentation/controllers/settings_controller.dart';
import 'presentation/screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Tier 3: Data Tier instances
  final localStorage = SettingsLocalStorage();
  final apiService = ProductApiService();

  final SettingsRepository settingsRepo = SettingsRepositoryImpl(
    localStorage: localStorage,
    apiService: apiService,
  );

  final ProductRepository productRepo = ProductRepositoryImpl(
    apiService: apiService,
    settingsRepository: settingsRepo,
  );

  // Dynamic Splunk Observability Cloud parameters from persistent storage (or SSOT defaults)
  final splunkRealm = await localStorage.getSplunkRealm();
  final splunkToken = await localStorage.getSplunkRumToken();
  final splunkAppName = await localStorage.getSplunkAppName();
  final splunkEnvironment = await localStorage.getSplunkEnvironment();
  final splunkVersion = await localStorage.getSplunkAppVersion();

  // Initialize Splunk RUM dynamically with the exact requested configuration
  await SplunkRumService.initialize(
    realm: splunkRealm,
    token: splunkToken,
    appName: splunkAppName,
    environment: splunkEnvironment,
    appVersion: splunkVersion,
  );

  // Tier 1: Presentation Tier controllers
  final settingsController = SettingsController(repository: settingsRepo);
  final productController = ProductController(repository: productRepo);

  await settingsController.init();
  productController.loadData();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsController>.value(value: settingsController),
        ChangeNotifierProvider<ProductController>.value(value: productController),
      ],
      child: const ProductManagerApp(),
    ),
  );
}

class ProductManagerApp extends StatelessWidget {
  const ProductManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.cardBg,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0.5,
          scrolledUnderElevation: 0.5,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}
