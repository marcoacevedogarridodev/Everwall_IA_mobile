import 'package:flutter/material.dart';
import '../../services/deep_link_service.dart';
import '../../services/notification_service.dart';
import '../../services/offline_service.dart';
import '../../theme/colors.dart';
import '../../widgets/navigation/bottom_navigation_bar.dart';
import 'grid_screen.dart';
import 'messages_screen.dart';
import 'my_pixels_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

/// Contenedor principal post-login: bottom navigation + las 5 secciones
/// (spec secciones 3-7). Usa IndexedStack para que cada tab mantenga su
/// propio estado (scroll position del grid, etc.) al cambiar de pestaña.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  static const _screens = [
    GridScreen(),
    SearchScreen(),
    MyPixelsScreen(),
    MessagesScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Todas seguras de llamar aunque su configuración externa (Firebase,
    // intent-filters nativos) no esté lista todavía — fallan en silencio.
    NotificationService.instance.init();
    DeepLinkService.instance.consumePendingLink();
    OfflineService.instance.flushPendingActions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
