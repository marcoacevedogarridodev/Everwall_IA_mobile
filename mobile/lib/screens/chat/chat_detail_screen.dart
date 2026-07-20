import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/message_model.dart';
import '../../providers/chat_provider.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/loading_widget.dart';

/// Pixel Chat Detail (spec sección 6): header con imagen del píxel,
/// mensajes en burbujas estilo WhatsApp, input para responder (público o
/// privado).
class ChatDetailScreen extends StatefulWidget {
  final ChatSummaryModel chat;
  const ChatDetailScreen({super.key, required this.chat});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sendPrivately = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().openChat(widget.chat.pixelId);
    });
  }

  @override
  void dispose() {
    context.read<ChatProvider>().closeChat();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    _textController.clear();
    final success = await context
        .read<ChatProvider>()
        .sendMessage(text, isPrivate: _sendPrivately);
    if (success && mounted) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: widget.chat.pixelImageUrl,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 36,
                  height: 36,
                  color: AppColors.surface,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.chat.pixelOwnerName,
                style: AppTextStyles.title,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chat, _) {
                switch (chat.threadStatus) {
                  case ChatThreadStatus.loading:
                    return const LoadingWidget();
                  case ChatThreadStatus.error:
                    return AppErrorWidget(
                      message:
                          chat.threadError ?? 'No se pudieron cargar los mensajes',
                      onRetry: () => chat.openChat(widget.chat.pixelId),
                    );
                  case ChatThreadStatus.loaded:
                    if (chat.messages.isEmpty) {
                      return const Center(
                        child: Text(
                          'Aún no hay mensajes. ¡Escribe el primero!',
                          style: AppTextStyles.bodySecondary,
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: chat.messages.length,
                      itemBuilder: (context, index) {
                        return _MessageBubble(message: chat.messages[index]);
                      },
                    );
                }
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    final isSending = context.watch<ChatProvider>().isSending;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Switch(
                  value: _sendPrivately,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) => setState(() => _sendPrivately = v),
                ),
                Text(
                  _sendPrivately ? 'Mensaje privado' : 'Mensaje público',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _textController,
                      minLines: 1,
                      maxLines: 4,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Escribe un mensaje…',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: isSending ? null : _send,
                  style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                  icon: isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMine)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  message.senderName,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Text(
              message.message,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            if (message.isPrivate) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline,
                      size: 11, color: Colors.white.withValues(alpha: 0.6)),
                  const SizedBox(width: 3),
                  Text(
                    'Privado',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
