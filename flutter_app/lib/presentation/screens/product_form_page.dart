import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_config.dart';
import '../../domain/models/product.dart';
import '../controllers/product_controller.dart';

class ProductFormPage extends StatefulWidget {
  final Product? productToEdit;

  const ProductFormPage({super.key, this.productToEdit});

  static Future<bool?> navigate(BuildContext context, {Product? product}) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (ctx) => ProductFormPage(productToEdit: product),
      ),
    );
  }

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _priceController;
  late TextEditingController _descController;

  bool get isEdit => widget.productToEdit != null;

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _nameController = TextEditingController(text: p?.name ?? '');
    _categoryController = TextEditingController(text: p?.category ?? '');
    _priceController = TextEditingController(
      text: p != null ? p.price.toStringAsFixed(2) : '',
    );
    _descController = TextEditingController(text: p?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<ProductController>();
    final name = _nameController.text.trim();
    final category = _categoryController.text.trim().isEmpty
        ? 'General'
        : _categoryController.text.trim();
    final price = double.parse(_priceController.text.trim());
    final description = _descController.text.trim();

    bool success;
    if (isEdit) {
      final updated = widget.productToEdit!.copyWith(
        name: name,
        category: category,
        price: price,
        description: description,
      );
      success = await controller.updateProduct(updated);
    } else {
      final newProduct = Product(
        id: '',
        name: name,
        category: category,
        price: price,
        description: description,
      );
      success = await controller.createProduct(newProduct);
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit ? 'Product "$name" updated!' : 'Product "$name" created!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      final errorMsg = controller.errorMessage ?? 'Failed to save product.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProductController>();
    final categories = controller.categories;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Product' : 'Add New Product',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Form Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderColor),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.04),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name Field
                        _buildFieldLabel('Product Name', required: true),
                        TextFormField(
                          controller: _nameController,
                          maxLength: 100,
                          decoration: InputDecoration(
                            hintText: 'e.g. Wireless Noise-Cancelling Headphones',
                            prefixIcon: const Icon(Icons.tag, size: 20, color: AppColors.textMuted),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.borderColor),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Product name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Category & Price Responsive Row
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isMobile = constraints.maxWidth < 450;
                            final categoryWidget = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Category', required: true),
                                TextFormField(
                                  controller: _categoryController,
                                  decoration: InputDecoration(
                                    hintText: 'e.g. Electronics',
                                    prefixIcon: const Icon(Icons.category_outlined, size: 20, color: AppColors.textMuted),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: AppColors.borderColor),
                                    ),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Category is required';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            );

                            final priceWidget = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Price (${AppConfig.currencySymbol})', required: true),
                                TextFormField(
                                  controller: _priceController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                  ],
                                  decoration: InputDecoration(
                                    hintText: '0.00',
                                    prefixIcon: const Icon(Icons.currency_rupee, size: 20, color: AppColors.textMuted),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: AppColors.borderColor),
                                    ),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Price is required';
                                    }
                                    final num = double.tryParse(val.trim());
                                    if (num == null || num <= 0) {
                                      return 'Enter a price > 0';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            );

                            if (isMobile) {
                              return Column(
                                children: [
                                  categoryWidget,
                                  const SizedBox(height: 16),
                                  priceWidget,
                                ],
                              );
                            } else {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: categoryWidget),
                                  const SizedBox(width: 16),
                                  Expanded(child: priceWidget),
                                ],
                              );
                            }
                          },
                        ),

                        // Category suggestions chips
                        if (categories.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: categories.take(6).map((cat) {
                              return ActionChip(
                                label: Text(cat, style: const TextStyle(fontSize: 11)),
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  _categoryController.text = cat;
                                },
                              );
                            }).toList(),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Description Field
                        _buildFieldLabel('Description'),
                        TextFormField(
                          controller: _descController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Provide product details, specifications, and features...',
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.borderColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Actions: Cancel & Submit Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: controller.isSaving
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          side: const BorderSide(color: AppColors.borderColor),
                        ),
                        child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                      const SizedBox(width: 14),
                      ElevatedButton.icon(
                        onPressed: controller.isSaving ? null : _submitForm,
                        icon: controller.isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check, size: 18),
                        label: Text(
                          controller.isSaving
                              ? (isEdit ? 'Updating...' : 'Saving...')
                              : (isEdit ? 'Update Product' : 'Save Product'),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (required)
            const Text(
              ' *',
              style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}
