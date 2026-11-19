import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../controllers/product_controller.dart';
import '../controllers/settings_controller.dart';
import 'categories_page.dart';
import 'dashboard_page.dart';
import 'products_page.dart';
import 'settings_page.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final productCtrl = context.watch<ProductController>();

    final pages = [
      DashboardPage(onNavigateToTab: _onTabChanged),
      const ProductsPage(),
      CategoriesPage(
        onSelectCategory: (cat) {
          productCtrl.setCategoryFilter(cat);
          _onTabChanged(1); // switch to products catalog
        },
      ),
      const SettingsPage(),
    ];

    final titles = [
      'Dashboard',
      'Product Catalog',
      'Categories',
      'Settings',
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.inventory_2, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    titles[_currentIndex],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: [
              // Backend URL Pill Indicator with strict constraints to prevent AppBar overflow
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _onTabChanged(3), // Jump to Settings
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.dns, size: 13, color: AppColors.primary),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 130),
                        child: Text(
                          settings.backendUrl.isNotEmpty
                              ? settings.backendUrl
                                  .replaceFirst('http://', '')
                                  .replaceFirst('https://', '')
                              : 'Configure API',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Refresh Button
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
                tooltip: 'Refresh data',
                onPressed: () {
                  productCtrl.loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Refreshing catalog and categories...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: isWide
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _currentIndex,
                      onDestinationSelected: _onTabChanged,
                      labelType: NavigationRailLabelType.all,
                      backgroundColor: Colors.white,
                      selectedIconTheme: const IconThemeData(color: AppColors.primary),
                      selectedLabelTextStyle: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      unselectedIconTheme: const IconThemeData(color: AppColors.textMuted),
                      unselectedLabelTextStyle: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.dashboard_outlined),
                          selectedIcon: Icon(Icons.dashboard),
                          label: Text('Dashboard'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.inventory_2_outlined),
                          selectedIcon: Icon(Icons.inventory_2),
                          label: Text('Catalog'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.category_outlined),
                          selectedIcon: Icon(Icons.category),
                          label: Text('Categories'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.settings_outlined),
                          selectedIcon: Icon(Icons.settings),
                          label: Text('Settings'),
                        ),
                      ],
                    ),
                    const VerticalDivider(thickness: 1, width: 1, color: AppColors.borderColor),
                    Expanded(child: pages[_currentIndex]),
                  ],
                )
              : pages[_currentIndex],
          bottomNavigationBar: isWide
              ? null
              : BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: _onTabChanged,
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Colors.white,
                  selectedItemColor: AppColors.primary,
                  unselectedItemColor: AppColors.textMuted,
                  selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
                  elevation: 8,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.dashboard_outlined),
                      activeIcon: Icon(Icons.dashboard),
                      label: 'Dashboard',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.inventory_2_outlined),
                      activeIcon: Icon(Icons.inventory_2),
                      label: 'Catalog',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.category_outlined),
                      activeIcon: Icon(Icons.category),
                      label: 'Categories',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.settings_outlined),
                      activeIcon: Icon(Icons.settings),
                      label: 'Settings',
                    ),
                  ],
                ),
        );
      },
    );
  }
}
