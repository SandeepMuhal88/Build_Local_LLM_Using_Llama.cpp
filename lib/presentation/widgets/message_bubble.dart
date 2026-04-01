import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/chat_message.dart';

class MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isStreaming;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    this.isStreaming = false,
    this.onLongPress,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: Offset(widget.message.role == MessageRole.user ? 0.3 : -0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  bool get _isUser => widget.message.role == MessageRole.user;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment:
                _isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!_isUser) _buildAvatar(),
              if (!_isUser) const SizedBox(width: 8),
              Flexible(
                child: GestureDetector(
                  onLongPress: widget.onLongPress,
                  child: _buildBubble(),
                ),
              ),
              if (_isUser) const SizedBox(width: 8),
              if (_isUser) _buildUserAvatar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.auto_awesome_rounded,
          color: Colors.white, size: 16),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppTheme.bgElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.divider),
      ),
      child: const Icon(Icons.person_outline_rounded,
          color: AppTheme.textSecondary, size: 16),
    );
  }

  Widget _buildBubble() {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.78,
      ),
      decoration: BoxDecoration(
        color: _isUser ? AppTheme.userBubble : AppTheme.aiBubble,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(_isUser ? 16 : 4),
          bottomRight: Radius.circular(_isUser ? 4 : 16),
        ),
        border: Border.all(
          color: _isUser
              ? AppTheme.primary.withValues(alpha: 0.3)
              : AppTheme.divider,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: _isUser
                ? _buildUserContent()
                : _buildAIContent(),
          ),
          // Footer
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildUserContent() {
    return Text(
      widget.message.content,
      style: GoogleFonts.inter(
        fontSize: 14,
        color: AppTheme.textPrimary,
        height: 1.5,
      ),
    );
  }

  Widget _buildAIContent() {
    return MarkdownBody(
      data: widget.message.content.isEmpty ? '▋' : widget.message.content,
      styleSheet: MarkdownStyleSheet(
        p: GoogleFonts.inter(
          fontSize: 14,
          color: AppTheme.textPrimary,
          height: 1.6,
        ),
        code: GoogleFonts.firaCode(
          fontSize: 13,
          color: AppTheme.secondary,
          backgroundColor: AppTheme.bgDark,
        ),
        codeblockDecoration: BoxDecoration(
          color: AppTheme.bgDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.divider),
        ),
        blockquote: GoogleFonts.inter(
          fontSize: 14,
          color: AppTheme.textSecondary,
          fontStyle: FontStyle.italic,
        ),
        blockquoteDecoration: const BoxDecoration(
          border: Border(
              left: BorderSide(color: AppTheme.primary, width: 3)),
          color: Color(0xFF1A1040),
        ),
        h1: GoogleFonts.outfit(
            fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        h2: GoogleFonts.outfit(
            fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
        h3: GoogleFonts.outfit(
            fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
        strong: GoogleFonts.inter(
            fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        em: GoogleFonts.inter(
            fontStyle: FontStyle.italic, color: AppTheme.textSecondary),
        listBullet: GoogleFonts.inter(
            fontSize: 14, color: AppTheme.primary),
        tableBorder: TableBorder.all(color: AppTheme.divider, width: 1),
        tableHead: GoogleFonts.inter(
            fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
        tableBody:
            GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
      ),
      selectable: true,
      onTapLink: (text, href, title) {},
    );
  }

  Widget _buildFooter() {
    final timeStr = DateFormat('HH:mm').format(widget.message.timestamp);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            timeStr,
            style: GoogleFonts.inter(
                fontSize: 10, color: AppTheme.textMuted),
          ),
          if (!_isUser && widget.message.inferenceTimeMs != null) ...[
            const SizedBox(width: 6),
            Text(
              '· ${(widget.message.inferenceTimeMs! / 1000).toStringAsFixed(1)}s',
              style: GoogleFonts.inter(
                  fontSize: 10, color: AppTheme.textMuted),
            ),
          ],
          if (widget.isStreaming) ...[
            const SizedBox(width: 6),
            _StreamingDot(),
          ],
          if (!_isUser && !widget.isStreaming && widget.message.content.isNotEmpty) ...[
            const Spacer(),
            InkWell(
              onTap: () => Clipboard.setData(
                  ClipboardData(text: widget.message.content)),
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.copy_outlined,
                    size: 12, color: AppTheme.textMuted),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StreamingDot extends StatefulWidget {
  @override
  State<_StreamingDot> createState() => _StreamingDotState();
}

class _StreamingDotState extends State<_StreamingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: const DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.secondary,
        ),
        child: SizedBox(width: 6, height: 6),
      ),
    );
  }
}
