import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/datasources/splunk_rum_service.dart';
import '../controllers/product_controller.dart';
import '../controllers/settings_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _urlController;
  late TextEditingController _appNameController;
  late TextEditingController _environmentController;
  late TextEditingController _versionController;
  late TextEditingController _realmController;
  late TextEditingController _tokenController;

  bool _isEditingSplunk = false;
  bool _hasLoadedFromSettings = false;
  String? _urlErrorText;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsController>();
    _urlController = TextEditingController(text: settings.backendUrl);
    _appNameController = TextEditingController(text: settings.splunkAppName);
    _environmentController = TextEditingController(text: settings.splunkEnvironment);
    _versionController = TextEditingController(text: settings.splunkAppVersion);
    _realmController = TextEditingController(text: settings.splunkRealm);
    _tokenController = TextEditingController(text: settings.splunkRumToken);

    if (settings.backendUrl.isNotEmpty) {
      _hasLoadedFromSettings = true;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _appNameController.dispose();
    _environmentController.dispose();
    _versionController.dispose();
    _realmController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    // Initialize once when settings load asynchronously, without overwriting user clear actions
    if (!_hasLoadedFromSettings && settings.backendUrl.isNotEmpty) {
      _urlController.text = settings.backendUrl;
      _appNameController.text = settings.splunkAppName;
      _environmentController.text = settings.splunkEnvironment;
      _versionController.text = settings.splunkAppVersion;
      _realmController.text = settings.splunkRealm;
      _tokenController.text = settings.splunkRumToken;
      _hasLoadedFromSettings = true;
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

                      // URL Input Field with Full Clear State & Validation Support
                      TextField(
                        controller: _urlController,
                        onChanged: (val) {
                          if (_urlErrorText != null && val.trim().isNotEmpty) {
                            setState(() {
                              _urlErrorText = null;
                            });
                          }
                          settings.resetTestStatus();
                        },
                        decoration: InputDecoration(
                          hintText: 'e.g. http://localhost:5000',
                          errorText: _urlErrorText,
                          prefixIcon: const Icon(Icons.dns_outlined, color: AppColors.textMuted),
                          suffixIcon: _urlController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  tooltip: 'Clear input field',
                                  onPressed: () {
                                    _urlController.clear();
                                    settings.resetTestStatus();
                                    setState(() {
                                      _urlErrorText = null;
                                    });
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

                      // Quick Preset Chips (SSOT)
                      const Text(
                        'Quick Presets:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: settings.presets.map((preset) {
                          final isCurrent = _urlController.text.trim() == preset;
                          return ChoiceChip(
                            label: Text(preset, style: const TextStyle(fontSize: 11.5)),
                            selected: isCurrent,
                            selectedColor: AppColors.primaryLight,
                            onSelected: (_) {
                              setState(() {
                                _urlController.text = preset;
                                _urlErrorText = null;
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

                      // Actions: Test Connection & Save with Zero Overlap Layout
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 420;

                          final testBtn = OutlinedButton.icon(
                            onPressed: settings.testStatus == ConnectionTestStatus.testing
                                ? null
                                : () {
                                    final url = _urlController.text.trim();
                                    if (url.isEmpty) {
                                      setState(() {
                                        _urlErrorText = 'Please enter a URL to test.';
                                      });
                                      return;
                                    }
                                    setState(() {
                                      _urlErrorText = null;
                                    });
                                    settings.testConnection(url);
                                  },
                            icon: const Icon(Icons.wifi_tethering, size: 18),
                            label: const Text('Test Connection'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          );

                          final saveBtn = ElevatedButton.icon(
                            onPressed: () async {
                              final url = _urlController.text.trim();
                              if (url.isEmpty) {
                                setState(() {
                                  _urlErrorText = 'Backend API URL cannot be empty. Enter a valid URL or select a preset.';
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter a backend URL before saving.'),
                                    backgroundColor: AppColors.danger,
                                  ),
                                );
                                return;
                              }
                              setState(() {
                                _urlErrorText = null;
                              });

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
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          );

                          if (isNarrow) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                testBtn,
                                const SizedBox(height: 10),
                                saveBtn,
                              ],
                            );
                          } else {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                testBtn,
                                const SizedBox(width: 12),
                                saveBtn,
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Splunk Observability Cloud RUM Card (Zero Overlap & Responsive)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                      // Header with Zero-Overlap Layout
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.radar, color: Color(0xFFE11D48), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Splunk RUM',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF1F2),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: const Color(0xFFFECDD3)),
                                      ),
                                      child: Text(
                                        'Realm: ${settings.splunkRealm}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFBE123C),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Real User Monitoring',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFE11D48),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Real-time client telemetry streaming directly to Splunk Observability Cloud. Monitors page renders, UI interactions, and API latency.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 14),

                      if (_isEditingSplunk) ...[
                        // Editable Form Fields
                        _buildInputField('Application Name', _appNameController, 'e.g. three-tier-product-frontend'),
                        const SizedBox(height: 10),
                        _buildInputField('Deployment Environment', _environmentController, 'e.g. production, dev'),
                        const SizedBox(height: 10),
                        _buildInputField('Application Version', _versionController, 'e.g. 1.0.0'),
                        const SizedBox(height: 10),
                        _buildInputField('Splunk Realm', _realmController, 'e.g. au0'),
                        const SizedBox(height: 10),
                        _buildInputField('RUM Access Token', _tokenController, 'e.g. Vzad6YH5sdprluV2gjLGPw', obscure: true),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isEditingSplunk = false;
                                  _appNameController.text = settings.splunkAppName;
                                  _environmentController.text = settings.splunkEnvironment;
                                  _versionController.text = settings.splunkAppVersion;
                                  _realmController.text = settings.splunkRealm;
                                  _tokenController.text = settings.splunkRumToken;
                                });
                              },
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final ok = await settings.saveSplunkConfig(
                                  realm: _realmController.text,
                                  token: _tokenController.text,
                                  appName: _appNameController.text,
                                  environment: _environmentController.text,
                                  appVersion: _versionController.text,
                                );
                                if (mounted && ok) {
                                  setState(() {
                                    _isEditingSplunk = false;
                                  });
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Splunk RUM configuration updated!'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('Save Telemetry Config'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE11D48),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Dynamic Display Container
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.borderColor),
                          ),
                          child: Column(
                            children: [
                              _buildRumDetailRow('Application Name', settings.splunkAppName),
                              const Divider(height: 14),
                              _buildRumDetailRow('Environment', settings.splunkEnvironment),
                              const Divider(height: 14),
                              _buildRumDetailRow('App Version', settings.splunkAppVersion),
                              const Divider(height: 14),
                              _buildRumDetailRow('Splunk Realm', settings.splunkRealm),
                              const Divider(height: 14),
                              _buildRumDetailRow(
                                'RUM Access Token',
                                settings.splunkRumToken.length > 8
                                    ? '${settings.splunkRumToken.substring(0, 6)}... (Active)'
                                    : 'Configured',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Action Buttons with Zero Overlap Responsive Layout
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 440;

                            final editButton = OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isEditingSplunk = true;
                                });
                              },
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              label: const Text('Edit Telemetry Config', overflow: TextOverflow.ellipsis),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            );

                            final generateButton = ElevatedButton.icon(
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final productCtrl = context.read<ProductController>();
                                await SplunkRumService.generateSampleActivity(
                                  stats: productCtrl.stats,
                                  products: productCtrl.products,
                                  backendUrl: settings.backendUrl,
                                );
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Dispatched live dynamic telemetry events to Splunk RUM!'),
                                    backgroundColor: Color(0xFFE11D48),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.bolt, size: 18),
                              label: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('Generate RUM Activity', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE11D48),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            );

                            if (isNarrow) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  editButton,
                                  const SizedBox(height: 10),
                                  generateButton,
                                ],
                              );
                            } else {
                              return Row(
                                children: [
                                  Expanded(child: editButton),
                                  const SizedBox(width: 12),
                                  Expanded(child: generateButton),
                                ],
                              );
                            }
                          },
                        ),
                      ],
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
                          Expanded(
                            child: Text(
                              '3-Tier Architecture Overview',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
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

  Widget _buildInputField(String label, TextEditingController controller, String hint, {bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRumDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
