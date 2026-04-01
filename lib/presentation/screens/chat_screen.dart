import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/chat_message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _sendBtnAnimController;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _sendBtnAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _inputController.addListener(() {
      final hasText = _inputController.text.isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
        if (hasText) {
          _sendBtnAnimController.forward();
        } else {
          _sendBtnAnimController.reverse();
        }
      }
    });

    // Create new session if none exists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppProvider>();
      if (provider.currentSession == null) {
        provider.createNewSession();
      }
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _sendBtnAnimController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _inputController.clear();
    _scrollToBottom();

    await context.read<AppProvider>().sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final session = provider.currentSession;
        final messages = session?.messages ?? [];

        // Auto-scroll when new messages arrive
        if (messages.isNotEmpty || provider.isGenerating) {
          _scrollToBottom();
        }

        return Scaffold(
          backgroundColor: AppTheme.bgDark,
          appBar: _buildAppBar(provider),
          body: Column(
            children: [
              // Model status bar
              if (!provider.isModelLoaded) _buildNoModelBanner(context),

              // Error bar
              if (provider.errorMessage != null)
                _buildErrorBanner(provider.errorMessage!),

              // Messages
              Expanded(
                child: messages.isEmpty && !provider.isGenerating
                    ? _buildEmptyState(provider)
                    : _buildMessageList(messages, provider),
              ),

              // Input area
              _buildInputArea(provider),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(AppProvider provider) {
    return AppBar(
      backgroundColor: AppTheme.bgDark,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            provider.currentSession?.title ?? 'New Chat',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: provider.isModelLoaded
                      ? AppTheme.accent
                      : AppTheme.textMuted,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                provider.isModelLoaded
                    ? (provider.selectedModel?.name ?? 'Model Loaded')
                    : 'No model loaded',
                style: GoogleFonts.inter(
                    fontSize: 11, color: AppTheme.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (provider.isGenerating)
          IconButton(
            icon: const Icon(Icons.stop_circle_outlined,
                color: AppTheme.error, size: 22),
            tooltip: 'Stop generation',
            onPressed: provider.stopGeneration,
          ),
        IconButton(
          icon: const Icon(Icons.add_comment_outlined,
              color: AppTheme.textSecondary, size: 20),
          tooltip: 'New Chat',
          onPressed: () => provider.createNewSession(),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildNoModelBanner(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Go to the Models tab to load a GGUF model!'),
            backgroundColor: AppTheme.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: AppTheme.warning.withValues(alpha: 0.15),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppTheme.warning, size: 16),
            const SizedBox(width: 8),
            Text(
              'No model loaded — tap Models tab to add a GGUF file',
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppTheme.warning),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.error.withValues(alpha: 0.15),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.error),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glowing AI orb
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Local AI Assistant',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '100% Offline • Privacy First\nPowered by Llama.cpp on-device',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            // Quick suggestions
            ..._buildSuggestions(provider),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSuggestions(AppProvider provider) {
    final suggestions = [
      ('Explain quantum computing simply', Icons.science_outlined),
      ('Write a Python function to sort a list', Icons.code_outlined),
      ('Give me 5 productivity tips', Icons.tips_and_updates_outlined),
      ('Translate: "Hello World" to French', Icons.translate_outlined),
    ];

    return suggestions
        .map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: provider.isModelLoaded
                    ? () {
                        _inputController.text = s.$1;
                        _send();
                      }
                    : null,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Row(
                    children: [
                      Icon(s.$2,
                          color: AppTheme.primary, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s.$1,
                          style: GoogleFonts.inter(
                              fontSize: 13, color: AppTheme.textSecondary),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          color: AppTheme.textMuted, size: 14),
                    ],
                  ),
                ),
              ),
            ))
        .toList();
  }

  Widget _buildMessageList(
      List<ChatMessage> messages, AppProvider provider) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: messages.length + (provider.isGenerating ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length) {
          // Streaming response
          return provider.streamingResponse.isNotEmpty
              ? MessageBubble(
                  message: ChatMessage(
                    content: provider.streamingResponse,
                    role: MessageRole.assistant,
                  ),
                  isStreaming: true,
                )
              : const Padding(
                  padding: EdgeInsets.all(16),
                  child: TypingIndicator(),
                );
        }
        return MessageBubble(
          message: messages[index],
          onLongPress: () => _copyMessage(messages[index].content),
        );
      },
    );
  }

  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied!'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildInputArea(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: const Border(top: BorderSide(color: AppTheme.divider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.bgElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: TextField(
                  controller: _inputController,
                  maxLines: 5,
                  minLines: 1,
                  enabled: provider.isModelLoaded,
                  style: GoogleFonts.inter(
                      color: AppTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: provider.isModelLoaded
                        ? 'Ask anything...'
                        : 'Load a model first...',
                    hintStyle: GoogleFonts.inter(
                        color: AppTheme.textMuted, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (val) {
                    if (!provider.isGenerating) _send();
                  },
                  textInputAction: TextInputAction.send,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Send / Stop button
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: provider.isGenerating
                  ? GestureDetector(
                      onTap: provider.stopGeneration,
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppTheme.error,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.stop_rounded,
                            color: Colors.white, size: 22),
                      ),
                    )
                  : GestureDetector(
                      onTap: _hasText && provider.isModelLoaded ? _send : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: _hasText && provider.isModelLoaded
                              ? AppTheme.primaryGradient
                              : null,
                          color: _hasText && provider.isModelLoaded
                              ? null
                              : AppTheme.bgElevated,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: Icon(
                          Icons.send_rounded,
                          color: _hasText && provider.isModelLoaded
                              ? Colors.white
                              : AppTheme.textMuted,
                          size: 20,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
