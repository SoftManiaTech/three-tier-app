import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../controllers/product_controller.dart';
import '../widgets/delete_confirm_dialog.dart';
import '../widgets/product_card.dart';
import 'product_form_page.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProductController>();
    final products = controller.filteredProducts;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => controller.loadData(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Top Controls Bar (Search & Filter)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => controller.setSearchQuery(val),
                      decoration: InputDecoration(
                        hintText: 'Search products by name or category...',
                        hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                        prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  controller.setSearchQuery('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.cardBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Horizontal Category Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('All Categories'),
                            selected: controller.selectedCategory.isEmpty,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: controller.selectedCategory.isEmpty ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                            ),
                            backgroundColor: AppColors.cardBg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: controller.selectedCategory.isEmpty ? AppColors.primary : AppColors.borderColor,
                              ),
                            ),
                            onSelected: (selected) {
                              if (selected) controller.setCategoryFilter('');
                            },
                          ),
                          const SizedBox(width: 8),
                          ...controller.categories.map((cat) {
                            final isSelected = controller.selectedCategory.toLowerCase() == cat.toLowerCase();
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(cat),
                                selected: isSelected,
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.5,
                                ),
                                backgroundColor: AppColors.cardBg,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected ? AppColors.primary : AppColors.borderColor,
                                  ),
                                ),
                                onSelected: (selected) {
                                  controller.setCategoryFilter(selected ? cat : '');
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Showing count & active filters indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Showing ${products.length} ${products.length == 1 ? 'product' : 'products'}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFA7F3D0)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.circle, color: AppColors.success, size: 7),
                                  SizedBox(width: 4),
                                  Text(
                                    'Live Data',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF065F46),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (controller.selectedCategory.isNotEmpty || controller.searchQuery.isNotEmpty)
                          TextButton.icon(
                            onPressed: () {
                              _searchController.clear();
                              controller.clearFilters();
                            },
                            icon: const Icon(Icons.close, size: 14),
                            label: const Text('Clear Filters', style: TextStyle(fontSize: 12.5)),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Products Grid Content
            if (controller.isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (products.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.primary),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Products Found',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          controller.searchQuery.isNotEmpty || controller.selectedCategory.isNotEmpty
                              ? 'No products matched your search or category filter.'
                              : 'Your catalog is currently empty.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => ProductFormPage.navigate(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Product'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.crossAxisExtent;
                    final crossAxisCount = width > 900
                        ? 3
                        : width > 600
                            ? 2
                            : 1;

                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 240,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = products[index];
                          return ProductCard(
                            product: product,
                            onEdit: () => ProductFormPage.navigate(context, product: product),
                            onDelete: () async {
                              final confirmed = await DeleteConfirmDialog.show(context, product.name);
                              if (confirmed == true) {
                                final success = await controller.deleteProduct(product.id);
                                if (context.mounted && success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Deleted "${product.name}"')),
                                  );
                                }
                              }
                            },
                          );
                        },
                        childCount: products.length,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ProductFormPage.navigate(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Product', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
