import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/empty_state_widget.dart';

/// Messages Screen (spec sección 6): chats públicos/privados por píxel,
/// vía GET/POST /pixels/share_pixel/ + WebSocket. Se implementa completa
/// en el Sprint 6.
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Mensajes'),
      body: const EmptyStateWidget(
        icon: Icons.chat_bubble_outline,
        title: 'Tus conversaciones',
        subtitle: 'Disponible en el Sprint 6',
      ),
    );
  }
}
