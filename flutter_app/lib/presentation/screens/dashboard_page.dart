import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../controllers/product_controller.dart';
import '../widgets/category_badge.dart';
import '../widgets/delete_confirm_dialog.dart';
import '../widgets/product_card.dart';
import '../widgets/stat_card.dart';
import 'product_form_page.dart';

class DashboardPage extends StatelessWidget {
  final Function(int) onNavigateToTab;

  const DashboardPage({
    super.key,
    required this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProductController>();
    final stats = controller.stats;

    return RefreshIndicator(
      onRefresh: () => controller.loadData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Banner Card
            _buildHeroBanner(context),
            const SizedBox(height: 24),

            // Metrics / Stats Bar
            _buildStatsBar(stats),
            const SizedBox(height: 32),

            // Quick Category Overview
            _buildCategoriesOverview(context, controller),
            const SizedBox(height: 32),

            // Recent Products Section
            _buildRecentProducts(context, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(108, 99, 255, 0.25),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.school, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'SOFTMANIA LEARNING',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Product Manager',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Real-time inventory, catalog management, and stats in Flutter.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: () => ProductFormPage.navigate(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Product'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => onNavigateToTab(1), // Navigate to Catalog
                icon: const Icon(Icons.grid_view, size: 18),
                label: const Text('View Catalog'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(dynamic stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        final card1 = StatCard(
          icon: Icons.inventory_2_outlined,
          label: 'Total Products',
          value: stats.totalProducts.toString(),
          iconColor: AppColors.primary,
          iconBgColor: AppColors.primaryLight,
        );
        final card2 = StatCard(
          icon: Icons.category_outlined,
          label: 'Active Categories',
          value: stats.totalCategories.toString(),
          iconColor: AppColors.secondary,
          iconBgColor: const Color(0xFFFFECEF),
        );
        final card3 = StatCard(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Total Inventory Value',
          value: Formatters.formatCurrency(stats.totalInventoryValue),
          iconColor: AppColors.success,
          iconBgColor: const Color(0xFFE8F8F2),
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(child: card1),
              const SizedBox(width: 16),
              Expanded(child: card2),
              const SizedBox(width: 16),
              Expanded(child: card3),
            ],
          );
        } else {
          return Column(
            children: [
              card1,
              const SizedBox(height: 12),
              card2,
              const SizedBox(height: 12),
              card3,
            ],
          );
        }
      },
    );
  }

  Widget _buildCategoriesOverview(BuildContext context, ProductController controller) {
    final stats = controller.stats;
    if (stats.categoryCounts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Categories Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => onNavigateToTab(2), // Navigate to Categories
              child: const Text('View All Categories'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: stats.categoryCounts.entries.map((entry) {
            final cat = entry.key;
            final count = entry.value;
            return InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                controller.setCategoryFilter(cat);
                onNavigateToTab(1); // Go to catalog with this filter
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CategoryBadge(category: cat, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2)),
                    const SizedBox(width: 8),
                    Text(
                      '$count items',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecentProducts(BuildContext context, ProductController controller) {
    // Show only the top 3 items on the dashboard overview as requested
    final recent = controller.products.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Products',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Showing latest ${recent.length} of ${controller.products.length} products',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => onNavigateToTab(1), // Catalog
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: Text('See All (${controller.products.length})'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (controller.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (recent.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Column(
              children: [
                const Icon(Icons.inbox_outlined, size: 48, color: AppColors.textMuted),
                const SizedBox(height: 12),
                const Text(
                  'No products found',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Start adding products to populate your inventory dashboard.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ProductFormPage.navigate(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Your First Product'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 900
                  ? 3
                  : constraints.maxWidth > 600
                      ? 2
                      : 1;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recent.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 240,
                ),
                itemBuilder: (ctx, index) {
                  final p = recent[index];
                  return ProductCard(
                    product: p,
                    onEdit: () => ProductFormPage.navigate(context, product: p),
                    onDelete: () async {
                      final confirmed = await DeleteConfirmDialog.show(context, p.name);
                      if (confirmed == true) {
                        await controller.deleteProduct(p.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Deleted "${p.name}"')),
                          );
                        }
                      }
                    },
                  );
                },
              );
            },
          ),
      ],
    );
  }
}
