import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import 'custom_tab_icon.dart';

/// Bottom nav con las 5 secciones principales (spec sección 3-7):
/// Grid, Search, My Pixels, Messages, Profile.
class AppBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 58,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildItem(0, Icons.grid_view_outlined, Icons.grid_view_rounded),
              _buildItem(1, Icons.search_outlined, Icons.search),
              _buildItem(2, Icons.photo_library_outlined, Icons.photo_library),
              _buildItem(3, Icons.chat_bubble_outline, Icons.chat_bubble),
              _buildItem(4, Icons.person_outline, Icons.person),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(int index, IconData icon, IconData activeIcon) {
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Center(
          child: CustomTabIcon(
            icon: icon,
            activeIcon: activeIcon,
            isActive: currentIndex == index,
          ),
        ),
      ),
    );
  }
}
