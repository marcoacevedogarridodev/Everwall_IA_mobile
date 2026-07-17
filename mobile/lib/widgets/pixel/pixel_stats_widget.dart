import 'package:flutter/material.dart';
import '../../models/pixel_model.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../utils/formatters.dart';

/// Fila de estadísticas del píxel (posición, likes, comentarios, fecha de
/// compra), usada en Pixel Detail Screen.
class PixelStatsWidget extends StatelessWidget {
  final PixelModel pixel;
  const PixelStatsWidget({super.key, required this.pixel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _Stat(
            icon: Icons.pin_drop_outlined,
            label: 'Posición',
            value: '(${pixel.x}, ${pixel.y})',
          ),
          _divider(),
          _Stat(
            icon: pixel.isOnFire
                ? Icons.local_fire_department
                : Icons.favorite_border,
            label: 'Likes',
            value: '${pixel.likesCount}',
            valueColor: pixel.isOnFire ? AppColors.fire : null,
          ),
          _divider(),
          _Stat(
            icon: Icons.chat_bubble_outline,
            label: 'Comentarios',
            value: '${pixel.commentsCount}',
          ),
          if (pixel.createdAt != null) ...[
            _divider(),
            _Stat(
              icon: Icons.event_outlined,
              label: 'Comprado',
              value: Formatters.truncate(
                '${pixel.createdAt!.day}/${pixel.createdAt!.month}/${pixel.createdAt!.year}',
                10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 32,
        color: AppColors.divider,
        margin: const EdgeInsets.symmetric(horizontal: 8),
      );
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: valueColor ?? AppColors.textSecondary),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.body.copyWith(color: valueColor),
            overflow: TextOverflow.ellipsis,
          ),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
