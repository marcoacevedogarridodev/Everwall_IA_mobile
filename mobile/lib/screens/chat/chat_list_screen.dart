import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/storage_service.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/loading_widget.dart';

/// Chat List Screen (spec sección 6): conversaciones activas, cada una con
/// thumbnail del píxel, último mensaje, fecha y contador de no leídos.
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final user = context.read<AuthProvider>().user;
    final token = await StorageService.instance.getAccessToken();
    if (user != null && token != null && mounted) {
      context.read<ChatProvider>().configure(userId: user.id, accessToken: token);
    }
    if (mounted) context.read<ChatProvider>().loadChatList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Mensajes'),
      body: Consumer<ChatProvider>(
        builder: (context, chat, _) {
          switch (chat.listStatus) {
            case ChatListStatus.loading:
              return const LoadingWidget();
            case ChatListStatus.error:
              return AppErrorWidget(
                message: chat.listError ?? 'No se pudieron cargar tus mensajes',
                onRetry: chat.loadChatList,
              );
            case ChatListStatus.empty:
              return const EmptyStateWidget(
                icon: Icons.chat_bubble_outline,
                title: 'Sin conversaciones',
                subtitle:
                    'Cuando alguien te escriba sobre un píxel, aparecerá aquí',
              );
            case ChatListStatus.loaded:
              return RefreshIndicator(
                color: Colors.white,
                onRefresh: chat.loadChatList,
                child: ListView.separated(
                  itemCount: chat.chats.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: AppColors.divider, height: 1),
                  itemBuilder: (context, index) {
                    final summary = chat.chats[index];
                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: summary.pixelImageUrl,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            width: 52,
                            height: 52,
                            color: AppColors.surface,
                            child: const Icon(Icons.image_outlined,
                                color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                      title: Text(
                        summary.pixelOwnerName,
                        style: AppTextStyles.body,
                      ),
                      subtitle: Text(
                        summary.lastMessage,
                        style: AppTextStyles.bodySecondary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (summary.lastMessageAt != null)
                            Text(
                              Formatters.timeAgo(summary.lastMessageAt!),
                              style: AppTextStyles.caption,
                            ),
                          if (summary.unreadCount > 0) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${summary.unreadCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      onTap: () => Navigator.of(context).pushNamed(
                        AppRoutes.chatDetail,
                        arguments: summary,
                      ),
                    );
                  },
                ),
              );
          }
        },
      ),
    );
  }
}
