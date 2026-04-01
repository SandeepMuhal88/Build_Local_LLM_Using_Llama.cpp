import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/chat_session.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final sessions = provider.sessions;
        return Scaffold(
          backgroundColor: AppTheme.bgDark,
          appBar: AppBar(
            backgroundColor: AppTheme.bgDark,
            title: Text('Chat History',
                style: GoogleFonts.outfit(
                    fontSize: 22, fontWeight: FontWeight.w700)),
            actions: [
              if (sessions.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined,
                      color: AppTheme.textSecondary),
                  tooltip: 'Clear all history',
                  onPressed: () => _confirmClearAll(context, provider),
                ),
            ],
          ),
          body: sessions.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: sessions.length,
                  itemBuilder: (context, i) =>
                      _SessionCard(session: sessions[i], provider: provider),
                ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline_rounded,
              size: 64, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          Text('No chat history yet',
              style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Text('Start a conversation in the Chat tab',
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Clear All History?',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        content: Text('This will permanently delete all chat sessions.',
            style:
                GoogleFonts.inter(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoogleFonts.inter(
                      color: AppTheme.textSecondary))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              for (final s in List.from(provider.sessions)) {
                provider.deleteSession(s.id);
              }
            },
            child: Text('Clear All',
                style: GoogleFonts.inter(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final ChatSession session;
  final AppProvider provider;

  const _SessionCard({required this.session, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isSelected = provider.currentSession?.id == session.id;
    final lastMsg = session.messages.isNotEmpty
        ? session.messages.last.content
        : 'Empty conversation';
    final dateStr =
        DateFormat('MMM d, HH:mm').format(session.updatedAt);

    return GestureDetector(
      onTap: () {
        provider.selectSession(session);
        // Switch to chat tab via index
        DefaultTabController.of(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.1)
              : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary.withValues(alpha: 0.4)
                : AppTheme.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary.withValues(alpha: 0.2)
                    : AppTheme.bgElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.chat_outlined,
                color: isSelected ? AppTheme.primary : AppTheme.textMuted,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    lastMsg,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppTheme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(dateStr,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppTheme.textMuted)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.bgElevated,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${session.messages.length} msgs',
                    style: GoogleFonts.inter(
                        fontSize: 10, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppTheme.textMuted, size: 16),
              onPressed: () => provider.deleteSession(session.id),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
