import 'package:flutter/material.dart';
import '../../theme/colors.dart';

/// Ícono individual de la bottom nav, con color primary cuando está activo.
class CustomTabIcon extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;

  const CustomTabIcon({
    super.key,
    required this.icon,
    required this.activeIcon,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: Icon(
        isActive ? activeIcon : icon,
        key: ValueKey(isActive),
        color: isActive ? AppColors.primary : AppColors.textSecondary,
        size: 26,
      ),
    );
  }
}
