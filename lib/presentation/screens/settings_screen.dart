import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import 'api_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _systemPromptController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    _systemPromptController =
        TextEditingController(text: provider.systemPrompt);
  }

  @override
  void dispose() {
    _systemPromptController.dispose();
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
            title: Text('Settings',
                style: GoogleFonts.outfit(
                    fontSize: 22, fontWeight: FontWeight.w700)),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ─── Backend Mode Toggle ─────────────────────────────────
              const _SectionHeader(
                  title: 'LLM Backend', icon: Icons.swap_horiz_rounded),
              _buildBackendToggle(provider),
              const SizedBox(height: 24),

              // ─── API Configuration ───────────────────────────────────
              const _SectionHeader(
                  title: 'Cloud API', icon: Icons.cloud_outlined),
              _buildApiCard(provider),
              const SizedBox(height: 24),

              // ─── Active Model Status ─────────────────────────────────
              const _SectionHeader(
                  title: 'Active Model', icon: Icons.memory_rounded),
              _buildModelStatus(provider),
              const SizedBox(height: 24),

              // Inference Parameters
              const _SectionHeader(
                  title: 'Inference Parameters',
                  icon: Icons.tune_rounded),
              _buildInferenceSettings(provider),
              const SizedBox(height: 24),

              // Prompt Template (only for local)
              if (provider.backend == LlmBackend.local) ...[
                const _SectionHeader(
                    title: 'Prompt Template',
                    icon: Icons.article_outlined),
                _buildTemplateSelector(provider),
                const SizedBox(height: 24),
              ],

              // System Prompt
              const _SectionHeader(
                  title: 'System Prompt',
                  icon: Icons.manage_history_rounded),
              _buildSystemPrompt(provider),
              const SizedBox(height: 24),

              // Hardware Settings (only for local)
              if (provider.backend == LlmBackend.local) ...[
                const _SectionHeader(
                    title: 'Hardware', icon: Icons.developer_board_rounded),
                _buildHardwareSettings(provider),
                const SizedBox(height: 40),
              ],

              // Reset button
              OutlinedButton.icon(
                onPressed: () => _resetDefaults(provider),
                icon: const Icon(Icons.restore_rounded,
                    color: AppTheme.warning),
                label: Text('Reset to Defaults',
                    style: GoogleFonts.inter(color: AppTheme.warning)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.warning),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  // ─── Backend Toggle ──────────────────────────────────────────────────────

  Widget _buildBackendToggle(AppProvider provider) {
    return _Card(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _BackendOption(
                  title: 'Local (Offline)',
                  subtitle: 'Runs on-device via Llama.cpp',
                  icon: Icons.smartphone_outlined,
                  isSelected: provider.backend == LlmBackend.local,
                  color: AppTheme.accent,
                  onTap: () => provider.setBackend(LlmBackend.local),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BackendOption(
                  title: 'Cloud API',
                  subtitle: 'OpenAI, Groq, etc.',
                  icon: Icons.cloud_outlined,
                  isSelected: provider.backend == LlmBackend.api,
                  color: AppTheme.secondary,
                  onTap: () => provider.setBackend(LlmBackend.api),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.bgElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  provider.backend == LlmBackend.api
                      ? Icons.info_outline_rounded
                      : Icons.lock_outline_rounded,
                  size: 14,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    provider.backend == LlmBackend.api
                        ? 'Cloud mode sends data to the API provider'
                        : 'All data stays on your device — 100% private',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppTheme.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── API Card ────────────────────────────────────────────────────────────

  Widget _buildApiCard(AppProvider provider) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ApiSettingsScreen()),
        );
      },
      child: _Card(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (provider.isApiConfigured
                        ? AppTheme.secondary
                        : AppTheme.textMuted)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                provider.isApiConfigured
                    ? Icons.cloud_done_outlined
                    : Icons.cloud_off_outlined,
                color: provider.isApiConfigured
                    ? AppTheme.secondary
                    : AppTheme.textMuted,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.isApiConfigured
                        ? '${provider.currentApiProvider.label} — ${provider.apiModel}'
                        : 'Configure API',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    provider.isApiConfigured
                        ? 'Tap to change provider or model'
                        : 'Tap to add your API key',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: AppTheme.textMuted, size: 16),
          ],
        ),
      ),
    );
  }

  // ─── Model Status ────────────────────────────────────────────────────────

  Widget _buildModelStatus(AppProvider provider) {
    return _Card(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (provider.isModelLoaded
                      ? (provider.backend == LlmBackend.api
                          ? AppTheme.secondary
                          : AppTheme.accent)
                      : AppTheme.textMuted)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              provider.isModelLoaded
                  ? Icons.check_circle_rounded
                  : Icons.error_outline_rounded,
              color: provider.isModelLoaded
                  ? (provider.backend == LlmBackend.api
                      ? AppTheme.secondary
                      : AppTheme.accent)
                  : AppTheme.textMuted,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.isModelLoaded
                      ? provider.activeBackendName
                      : 'No model active',
                  style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  provider.backend == LlmBackend.api
                      ? 'Cloud API'
                      : (provider.selectedModel?.sizeString ?? 'Local Llama.cpp'),
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInferenceSettings(AppProvider provider) {
    return _Card(
      child: Column(
        children: [
          _SliderRow(
            label: 'Max Tokens',
            value: provider.maxTokens.toDouble(),
            min: 64,
            max: 4096,
            divisions: 63,
            displayValue: provider.maxTokens.toString(),
            onChanged: (v) => provider.updateSettings(maxTokens: v.toInt()),
          ),
          const Divider(color: AppTheme.divider, height: 24),
          _SliderRow(
            label: 'Temperature',
            value: provider.temperature,
            min: 0.0,
            max: 2.0,
            divisions: 40,
            displayValue: provider.temperature.toStringAsFixed(2),
            onChanged: (v) => provider.updateSettings(temperature: v),
            tooltip:
                'Higher = more creative, Lower = more deterministic',
          ),
          const Divider(color: AppTheme.divider, height: 24),
          _SliderRow(
            label: 'Top-P',
            value: provider.topP,
            min: 0.1,
            max: 1.0,
            divisions: 18,
            displayValue: provider.topP.toStringAsFixed(2),
            onChanged: (v) => provider.updateSettings(topP: v),
            tooltip: 'Nucleus sampling threshold',
          ),
          if (provider.backend == LlmBackend.local) ...[
            const Divider(color: AppTheme.divider, height: 24),
            _SliderRow(
              label: 'Repeat Penalty',
              value: provider.repeatPenalty,
              min: 1.0,
              max: 2.0,
              divisions: 20,
              displayValue: provider.repeatPenalty.toStringAsFixed(2),
              onChanged: (v) => provider.updateSettings(repeatPenalty: v),
              tooltip: 'Penalizes repetition (1.0 = disabled)',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTemplateSelector(AppProvider provider) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select the template matching your model family',
            style: GoogleFonts.inter(
                fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.promptTemplates.keys.map((template) {
              final isSelected = provider.selectedTemplate == template;
              return GestureDetector(
                onTap: () =>
                    provider.updateSettings(selectedTemplate: template),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.bgElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.divider,
                    ),
                  ),
                  child: Text(
                    template,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemPrompt(AppProvider provider) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customize the AI\'s behavior and persona',
            style: GoogleFonts.inter(
                fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _systemPromptController,
            maxLines: 5,
            style: GoogleFonts.inter(
                fontSize: 13, color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter system prompt...',
              hintStyle:
                  GoogleFonts.inter(color: AppTheme.textMuted),
              filled: true,
              fillColor: AppTheme.bgElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppTheme.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppTheme.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: AppTheme.primary, width: 1.5),
              ),
            ),
            onChanged: (v) =>
                provider.updateSettings(systemPrompt: v),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                _systemPromptController.text =
                    AppConstants.defaultSystemPrompt;
                provider.updateSettings(
                    systemPrompt: AppConstants.defaultSystemPrompt);
              },
              child: Text('Reset Prompt',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppTheme.textMuted)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHardwareSettings(AppProvider provider) {
    return _Card(
      child: Column(
        children: [
          _SliderRow(
            label: 'CPU Threads',
            value: provider.nThreads.toDouble(),
            min: 1,
            max: 8,
            divisions: 7,
            displayValue: provider.nThreads.toString(),
            onChanged: (v) =>
                provider.updateSettings(nThreads: v.toInt()),
            tooltip:
                'More threads = faster on multi-core devices (4 recommended)',
          ),
          const Divider(color: AppTheme.divider, height: 24),
          _SliderRow(
            label: 'GPU Layers',
            value: provider.nGpuLayers.toDouble(),
            min: 0,
            max: 50,
            divisions: 50,
            displayValue: provider.nGpuLayers.toString(),
            onChanged: (v) =>
                provider.updateSettings(nGpuLayers: v.toInt()),
            tooltip:
                '0 = CPU only. Higher = more GPU acceleration (if supported)',
          ),
          const Divider(color: AppTheme.divider, height: 24),
          _SliderRow(
            label: 'Context Length',
            value: provider.contextLength.toDouble(),
            min: 512,
            max: 8192,
            divisions: 15,
            displayValue: provider.contextLength.toString(),
            onChanged: (v) =>
                provider.updateSettings(contextLength: v.toInt()),
            tooltip: 'Max tokens in context window (higher = more RAM)',
          ),
        ],
      ),
    );
  }

  void _resetDefaults(AppProvider provider) {
    _systemPromptController.text = AppConstants.defaultSystemPrompt;
    provider.updateSettings(
      systemPrompt: AppConstants.defaultSystemPrompt,
      maxTokens: AppConstants.defaultMaxTokens,
      temperature: AppConstants.defaultTemperature,
      topP: AppConstants.defaultTopP,
      repeatPenalty: AppConstants.defaultRepeatPenalty,
      contextLength: AppConstants.defaultContextLength,
      nGpuLayers: AppConstants.defaultNGpuLayers,
      nThreads: AppConstants.defaultNThreads,
      selectedTemplate: 'ChatML',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings reset to defaults'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

// ─── Reusable Widgets ──────────────────────────────────────────────────────

class _BackendOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _BackendOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.12)
              : AppTheme.bgElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.5)
                : AppTheme.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: isSelected ? color : AppTheme.textMuted, size: 22),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : AppTheme.textSecondary,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 16),
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
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: child,
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String displayValue;
  final ValueChanged<double> onChanged;
  final String? tooltip;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.displayValue,
    required this.onChanged,
    this.divisions,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (tooltip != null) ...[
                  const SizedBox(width: 4),
                  Tooltip(
                    message: tooltip!,
                    child: const Icon(Icons.info_outline_rounded,
                        size: 14, color: AppTheme.textMuted),
                  ),
                ],
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                displayValue,
                style: GoogleFonts.firaCode(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppTheme.primary,
            inactiveTrackColor: AppTheme.bgElevated,
            thumbColor: AppTheme.primary,
            overlayColor: AppTheme.primary.withValues(alpha: 0.1),
            trackHeight: 3,
            thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
