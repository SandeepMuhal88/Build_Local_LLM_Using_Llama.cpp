import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/api_llm_service.dart';

class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _apiKeyController;
  late TextEditingController _baseUrlController;
  late TextEditingController _customModelController;
  late AnimationController _pulseController;
  ApiProvider _selectedProvider = ApiProvider.openAI;
  String _selectedModel = 'gpt-4o-mini';
  bool _isTestingConnection = false;
  bool? _connectionTestResult;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    _selectedProvider = provider.currentApiProvider;
    _selectedModel = provider.apiModel;
    _apiKeyController = TextEditingController(text: provider.apiKey);
    _baseUrlController = TextEditingController(text: provider.apiBaseUrl);
    _customModelController = TextEditingController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _customModelController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppTheme.bgDark,
          appBar: AppBar(
            backgroundColor: AppTheme.bgDark,
            title: Text(
              'API Configuration',
              style: GoogleFonts.outfit(
                  fontSize: 20, fontWeight: FontWeight.w700),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Connection status card
              _buildConnectionStatusCard(provider),
              const SizedBox(height: 20),

              // Provider selector
              _buildSectionHeader('Provider', Icons.cloud_outlined),
              _buildProviderSelector(),
              const SizedBox(height: 20),

              // API Key
              _buildSectionHeader('API Key', Icons.key_outlined),
              _buildApiKeyField(),
              const SizedBox(height: 20),

              // Base URL (for custom)
              if (_selectedProvider == ApiProvider.custom) ...[
                _buildSectionHeader('Base URL', Icons.link_outlined),
                _buildBaseUrlField(),
                const SizedBox(height: 20),
              ],

              // Model selector
              _buildSectionHeader('Model', Icons.smart_toy_outlined),
              _buildModelSelector(),
              const SizedBox(height: 32),

              // Action buttons
              _buildSaveButton(provider),
              const SizedBox(height: 12),
              _buildTestButton(provider),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConnectionStatusCard(AppProvider provider) {
    final isConfigured = provider.isApiConfigured;
    final isApiMode = provider.backend == LlmBackend.api;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final glowOpacity = isApiMode && isConfigured
            ? 0.1 + (_pulseController.value * 0.1)
            : 0.0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isConfigured
                  ? [
                      AppTheme.secondary.withValues(alpha: glowOpacity + 0.1),
                      AppTheme.primary.withValues(alpha: glowOpacity + 0.05),
                    ]
                  : [AppTheme.bgCard, AppTheme.bgCard],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isConfigured
                  ? AppTheme.secondary.withValues(alpha: 0.4)
                  : AppTheme.divider,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isConfigured ? AppTheme.secondary : AppTheme.textMuted)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isConfigured
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_off_outlined,
                  color: isConfigured ? AppTheme.secondary : AppTheme.textMuted,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConfigured ? 'API Connected' : 'Not Configured',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isConfigured
                            ? AppTheme.secondary
                            : AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      isConfigured
                          ? '${provider.currentApiProvider.label} → ${provider.apiModel}'
                          : 'Add your API key to get started',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isApiMode && isConfigured)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Active',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accent,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.secondary, size: 16),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: ApiProvider.values.map((p) {
          final isSelected = _selectedProvider == p;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedProvider = p;
                _baseUrlController.text = p.defaultBaseUrl;
                // Pick first model of the provider
                final models = ApiProviderDefaults.models[p] ?? [];
                if (models.isNotEmpty) {
                  _selectedModel = models.first;
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.secondary : AppTheme.bgElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color:
                      isSelected ? AppTheme.secondary : AppTheme.divider,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color:
                              AppTheme.secondary.withValues(alpha: 0.3),
                          blurRadius: 8,
                        )
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getProviderIcon(p),
                    size: 14,
                    color: isSelected
                        ? Colors.white
                        : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    p.label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getProviderIcon(ApiProvider p) {
    switch (p) {
      case ApiProvider.openAI:
        return Icons.auto_awesome;
      case ApiProvider.groq:
        return Icons.bolt;
      case ApiProvider.together:
        return Icons.group;
      case ApiProvider.openRouter:
        return Icons.router;
      case ApiProvider.custom:
        return Icons.settings;
    }
  }

  Widget _buildApiKeyField() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: TextField(
        controller: _apiKeyController,
        obscureText: _obscureKey,
        style: GoogleFonts.firaCode(fontSize: 13, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'sk-... or gsk_... (paste your key)',
          hintStyle: GoogleFonts.firaCode(
              fontSize: 13, color: AppTheme.textMuted),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureKey ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AppTheme.textMuted,
              size: 18,
            ),
            onPressed: () => setState(() => _obscureKey = !_obscureKey),
          ),
        ),
      ),
    );
  }

  Widget _buildBaseUrlField() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: TextField(
        controller: _baseUrlController,
        style: GoogleFonts.firaCode(fontSize: 13, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'https://api.example.com/v1',
          hintStyle:
              GoogleFonts.firaCode(fontSize: 13, color: AppTheme.textMuted),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildModelSelector() {
    final models = ApiProviderDefaults.models[_selectedProvider] ?? [];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (models.isNotEmpty) ...[
            Text(
              'Popular Models',
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            ...models.map((model) {
              final isSelected = _selectedModel == model;
              return GestureDetector(
                onTap: () => setState(() => _selectedModel = model),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.secondary.withValues(alpha: 0.1)
                        : AppTheme.bgElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.secondary.withValues(alpha: 0.5)
                          : AppTheme.divider,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: isSelected
                            ? AppTheme.secondary
                            : AppTheme.textMuted,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          model,
                          style: GoogleFonts.firaCode(
                            fontSize: 12,
                            color: isSelected
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            const Divider(color: AppTheme.divider),
            const SizedBox(height: 8),
          ],
          Text(
            'Or enter a custom model name:',
            style: GoogleFonts.inter(
                fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customModelController,
                  style: GoogleFonts.firaCode(
                      fontSize: 12, color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'e.g. llama-3.1-70b',
                    hintStyle: GoogleFonts.firaCode(
                        fontSize: 12, color: AppTheme.textMuted),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    filled: true,
                    fillColor: AppTheme.bgElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: AppTheme.secondary, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final custom = _customModelController.text.trim();
                  if (custom.isNotEmpty) {
                    setState(() => _selectedModel = custom);
                    _customModelController.clear();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                ),
                child: Text('Use',
                    style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(AppProvider provider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _apiKeyController.text.trim().isEmpty
            ? null
            : () => _saveConfig(provider),
        icon: const Icon(Icons.save_outlined, size: 18),
        label: Text(
          'Save & Activate API',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.secondary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppTheme.bgElevated,
          disabledForegroundColor: AppTheme.textMuted,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _buildTestButton(AppProvider provider) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isTestingConnection || !provider.isApiConfigured
            ? null
            : () => _testConnection(provider),
        icon: _isTestingConnection
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.secondary))
            : Icon(
                _connectionTestResult == null
                    ? Icons.network_check_outlined
                    : (_connectionTestResult!
                        ? Icons.check_circle_outline
                        : Icons.error_outline),
                size: 18,
                color: _connectionTestResult == null
                    ? AppTheme.secondary
                    : (_connectionTestResult!
                        ? AppTheme.accent
                        : AppTheme.error),
              ),
        label: Text(
          _isTestingConnection
              ? 'Testing...'
              : (_connectionTestResult == true
                  ? 'Connection Successful ✓'
                  : (_connectionTestResult == false
                      ? 'Test Failed — Retry'
                      : 'Test Connection')),
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            color: _connectionTestResult == null
                ? AppTheme.secondary
                : (_connectionTestResult!
                    ? AppTheme.accent
                    : AppTheme.error),
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: _connectionTestResult == null
                ? AppTheme.secondary
                : (_connectionTestResult!
                    ? AppTheme.accent
                    : AppTheme.error),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Future<void> _saveConfig(AppProvider provider) async {
    await provider.configureApi(
      provider: _selectedProvider,
      apiKey: _apiKeyController.text.trim(),
      baseUrl: _selectedProvider == ApiProvider.custom
          ? _baseUrlController.text.trim()
          : null,
      model: _selectedModel,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'API configured: ${_selectedProvider.label} → $_selectedModel',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppTheme.secondary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _testConnection(AppProvider provider) async {
    setState(() {
      _isTestingConnection = true;
      _connectionTestResult = null;
    });

    final result = await provider.testApiConnection();

    if (mounted) {
      setState(() {
        _isTestingConnection = false;
        _connectionTestResult = result;
      });

      if (!result) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Connection failed: ${provider.errorMessage ?? "Unknown error"}',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}
