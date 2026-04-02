import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/model_info.dart';

class ModelsScreen extends StatelessWidget {
  const ModelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppTheme.bgDark,
          appBar: AppBar(
            title: Text('Models',
                style: GoogleFonts.outfit(
                    fontSize: 22, fontWeight: FontWeight.w700)),
            backgroundColor: AppTheme.bgDark,
            actions: [
              IconButton(
                icon: const Icon(Icons.help_outline_rounded,
                    color: AppTheme.textSecondary),
                onPressed: () => _showModelHelp(context),
              ),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              // Status Card
              SliverToBoxAdapter(
                child: _StatusCard(provider: provider),
              ),

              // Loaded Models Section
              if (provider.models.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Installed Models',
                      style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final model = provider.models[index];
                      return _ModelCard(
                        model: model,
                        isSelected:
                            provider.selectedModel?.id == model.id,
                        isLoading: provider.isLoading,
                        provider: provider,
                      );
                    },
                    childCount: provider.models.length,
                  ),
                ),
              ],

              // Recommended Models
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    'Recommended Models',
                    style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final rec = AppConstants.recommendedModels[i];
                    return _RecommendedModelCard(model: rec);
                  },
                  childCount: AppConstants.recommendedModels.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          floatingActionButton: _AddModelFab(provider: provider),
        );
      },
    );
  }

  void _showModelHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('How to Add Models',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text(
          '1. Download a .gguf model from Hugging Face\n'
          '   → Use Q4_K_M quantization for best balance\n\n'
          '2. Tap the + button below\n\n'
          '3. Select your .gguf file\n\n'
          '4. Tap "Load" to activate the model\n\n'
          'Recommended: Start with Phi-3 Mini (2.2GB) or\n'
          'Llama 3.2 1B (800MB) for fast devices.',
          style: GoogleFonts.inter(
              fontSize: 14, color: AppTheme.textSecondary, height: 1.7),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it!',
                style: GoogleFonts.inter(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final AppProvider provider;
  const _StatusCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: provider.isModelLoaded
            ? LinearGradient(
                colors: [
                  AppTheme.accent.withValues(alpha: 0.2),
                  AppTheme.primary.withValues(alpha: 0.1)
                ],
              )
            : const LinearGradient(colors: [
                AppTheme.bgCard,
                AppTheme.bgCard,
              ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: provider.isModelLoaded
              ? AppTheme.accent.withValues(alpha: 0.4)
              : AppTheme.divider,
        ),
      ),
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
                  ? Icons.check_circle_outline_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: provider.isModelLoaded
                  ? AppTheme.accent
                  : AppTheme.textMuted,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.isModelLoaded ? 'Model Active' : 'No Model Loaded',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: provider.isModelLoaded
                        ? AppTheme.accent
                        : AppTheme.textSecondary,
                  ),
                ),
                Text(
                  provider.isModelLoaded
                      ? provider.selectedModel?.name ?? ''
                      : 'Add a .gguf model to start chatting',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppTheme.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (provider.isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  color: AppTheme.primary, strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}

class _ModelCard extends StatelessWidget {
  final ModelInfo model;
  final bool isSelected;
  final bool isLoading;
  final AppProvider provider;

  const _ModelCard({
    required this.model,
    required this.isSelected,
    required this.isLoading,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.primary.withValues(alpha: 0.1)
            : AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.5) : AppTheme.divider,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.memory_rounded,
                      color: AppTheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.name,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          _Tag(text: model.sizeString, color: AppTheme.secondary),
                          const SizedBox(width: 6),
                          _Tag(text: model.templateName, color: AppTheme.primary),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isSelected)
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
                          color: AppTheme.accent),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoChip(
                    icon: Icons.timer_outlined,
                    label: 'ctx: ${model.contextLength}'),
                const SizedBox(width: 8),
                _InfoChip(
                    icon: Icons.developer_board_outlined,
                    label: 'GPU: ${model.nGpuLayers}'),
                const SizedBox(width: 8),
                _InfoChip(
                    icon: Icons.memory_outlined,
                    label: '${model.nThreads}T'),
                const Spacer(),
                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppTheme.textMuted, size: 18),
                  onPressed: () => _confirmDelete(context),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 12),
                // Load button
                if (!isSelected)
                  ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () => provider.loadModel(model),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                      textStyle: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Load'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Model?',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        content: Text('This will permanently delete "${model.name}".',
            style: GoogleFonts.inter(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteModel(model.id);
            },
            child: Text('Delete',
                style: GoogleFonts.inter(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w500, color: color),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppTheme.textMuted, size: 12),
        const SizedBox(width: 3),
        Text(label,
            style:
                GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }
}

class _RecommendedModelCard extends StatelessWidget {
  final Map<String, String> model;
  const _RecommendedModelCard({required this.model});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.download_outlined,
                color: AppTheme.secondary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model['name']!,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary),
                ),
                Row(
                  children: [
                    _Tag(
                        text: model['ram']!,
                        color: AppTheme.warning),
                    const SizedBox(width: 6),
                    _Tag(
                        text: model['quality']!,
                        color: AppTheme.accent),
                  ],
                ),
              ],
            ),
          ),
          Text(
            'Hugging Face',
            style: GoogleFonts.inter(
                fontSize: 11, color: AppTheme.primary),
          ),
        ],
      ),
    );
  }
}

class _AddModelFab extends StatelessWidget {
  final AppProvider provider;
  const _AddModelFab({required this.provider});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: provider.isLoading ? null : () => provider.addModel(),
      backgroundColor: AppTheme.primary,
      icon: provider.isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.add_rounded, color: Colors.white),
      label: Text(
        provider.isLoading ? 'Adding...' : 'Add Model (.gguf)',
        style: GoogleFonts.inter(
            fontWeight: FontWeight.w600, color: Colors.white),
      ),
    );
  }
}
