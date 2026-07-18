import 'package:flutter/material.dart';
import '../chat/chat_list_screen.dart';

/// Tab "Mensajes" del bottom nav — delega directamente en ChatListScreen
/// (spec sección 6), ya funcional desde el Sprint 6.
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ChatListScreen();
  }
}
