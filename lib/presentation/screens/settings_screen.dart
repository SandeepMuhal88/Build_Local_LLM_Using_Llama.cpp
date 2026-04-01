import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

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
              // Model Status Header
              const _SectionHeader(title: 'Active Model', icon: Icons.memory_rounded),
              _buildModelStatus(provider),
              const SizedBox(height: 24),

              // Inference Parameters
              const _SectionHeader(
                  title: 'Inference Parameters',
                  icon: Icons.tune_rounded),
              _buildInferenceSettings(provider),
              const SizedBox(height: 24),

              // Prompt Template
              const _SectionHeader(
                  title: 'Prompt Template',
                  icon: Icons.article_outlined),
              _buildTemplateSelector(provider),
              const SizedBox(height: 24),

              // System Prompt
              const _SectionHeader(
                  title: 'System Prompt',
                  icon: Icons.manage_history_rounded),
              _buildSystemPrompt(provider),
              const SizedBox(height: 24),

              // Hardware Settings
              const _SectionHeader(
                  title: 'Hardware', icon: Icons.developer_board_rounded),
              _buildHardwareSettings(provider),
              const SizedBox(height: 40),

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

  Widget _buildModelStatus(AppProvider provider) {
    return _Card(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (provider.isModelLoaded ? AppTheme.accent : AppTheme.textMuted)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              provider.isModelLoaded
                  ? Icons.check_circle_rounded
                  : Icons.error_outline_rounded,
              color: provider.isModelLoaded
                  ? AppTheme.accent
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
                      ? provider.selectedModel?.name ?? 'Unknown'
                      : 'No model loaded',
                  style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (provider.isModelLoaded)
                  Text(
                    provider.selectedModel?.sizeString ?? '',
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
            max: 2048,
            divisions: 31,
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
