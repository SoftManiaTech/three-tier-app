import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../controllers/product_controller.dart';
import '../controllers/settings_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _urlController;

  final List<String> _presets = [
    'http://localhost:5000',
    'http://localhost:8000',
    'http://10.0.2.2:5000',
    'http://127.0.0.1:3000',
  ];

  @override
  void initState() {
    super.initState();
    final current = context.read<SettingsController>().backendUrl;
    _urlController = TextEditingController(text: current);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    // Keep controller in sync if settings loaded asynchronously
    if (_urlController.text.isEmpty && settings.backendUrl.isNotEmpty) {
      _urlController.text = settings.backendUrl;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Backend Connection Settings',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Configure the API server location for this Flutter application. The data layer communicates with this address.',
                  style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),

                // Settings Card
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
                      const Text(
                        'API Base URL',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // URL Input Field
                      TextField(
                        controller: _urlController,
                        onChanged: (_) => settings.resetTestStatus(),
                        decoration: InputDecoration(
                          hintText: 'e.g. http://localhost:5000',
                          prefixIcon: const Icon(Icons.dns_outlined, color: AppColors.textMuted),
                          suffixIcon: _urlController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _urlController.clear();
                                    settings.resetTestStatus();
                                    setState(() {});
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Quick Preset Chips
                      const Text(
                        'Quick Presets:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _presets.map((preset) {
                          final isCurrent = _urlController.text.trim() == preset;
                          return ChoiceChip(
                            label: Text(preset, style: const TextStyle(fontSize: 11.5)),
                            selected: isCurrent,
                            selectedColor: AppColors.primaryLight,
                            onSelected: (_) {
                              setState(() {
                                _urlController.text = preset;
                              });
                              settings.resetTestStatus();
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Connection Test Result Badge
                      if (settings.testStatus != ConnectionTestStatus.idle) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: settings.testStatus == ConnectionTestStatus.success
                                ? const Color(0xFFECFDF5)
                                : settings.testStatus == ConnectionTestStatus.testing
                                    ? AppColors.primaryLight
                                    : const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: settings.testStatus == ConnectionTestStatus.success
                                  ? const Color(0xFFA7F3D0)
                                  : settings.testStatus == ConnectionTestStatus.testing
                                      ? const Color(0xFFC7D2FE)
                                      : const Color(0xFFFECACA),
                            ),
                          ),
                          child: Row(
                            children: [
                              if (settings.testStatus == ConnectionTestStatus.testing)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                )
                              else if (settings.testStatus == ConnectionTestStatus.success)
                                const Icon(Icons.check_circle, color: AppColors.success, size: 20)
                              else
                                const Icon(Icons.error, color: AppColors.danger, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  settings.statusMessage ?? '',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: settings.testStatus == ConnectionTestStatus.success
                                        ? const Color(0xFF065F46)
                                        : settings.testStatus == ConnectionTestStatus.testing
                                            ? AppColors.primaryDark
                                            : const Color(0xFF991B1B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Actions: Test Connection & Save
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: settings.testStatus == ConnectionTestStatus.testing
                                ? null
                                : () => settings.testConnection(_urlController.text),
                            icon: const Icon(Icons.wifi_tethering, size: 18),
                            label: const Text('Test Connection'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final url = _urlController.text.trim();
                              if (url.isEmpty) return;
                              final productCtrl = context.read<ProductController>();
                              final messenger = ScaffoldMessenger.of(context);
                              final ok = await settings.saveBackendUrl(url);
                              if (!mounted) return;
                              if (ok) {
                                await productCtrl.loadData();
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Settings saved & catalog refreshed!'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.save, size: 18),
                            label: const Text('Save & Apply'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Educational Architecture Guide Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.layers_outlined, color: AppColors.primary, size: 22),
                          SizedBox(width: 8),
                          Text(
                            '3-Tier Architecture Overview',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTierRow(
                        tier: 'Tier 1: Presentation',
                        desc: 'Flutter screens (Dashboard, Catalog, Categories, Settings) & ChangeNotifier state management.',
                        color: AppColors.primary,
                      ),
                      const Divider(height: 20),
                      _buildTierRow(
                        tier: 'Tier 2: Business Logic / Domain',
                        desc: 'Product & DashboardStats entities, repository interfaces, and catalog calculation logic.',
                        color: AppColors.secondary,
                      ),
                      const Divider(height: 20),
                      _buildTierRow(
                        tier: 'Tier 3: Data Tier',
                        desc: 'HTTP REST API Service connecting to /api/products & SharedPreferences local settings.',
                        color: AppColors.success,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTierRow({required String tier, required String desc, required Color color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tier,
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: color),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
