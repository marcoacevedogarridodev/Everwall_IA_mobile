import 'package:flutter/material.dart';
import '../../generated/assets.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';

/// App bar consistente para las pantallas principales. `showLogo: true`
/// muestra el ícono de marca a la izquierda (usado en Grid Screen); si no,
/// muestra `title`.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showLogo;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    this.title,
    this.showLogo = false,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 20,
      title: showLogo
          ? Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Image.asset(
                    Assets.logo,
                    width: 26,
                    height: 26,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Pixel App', style: AppTextStyles.title),
              ],
            )
          : Text(title ?? '', style: AppTextStyles.title),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
