import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/pixel_model.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';

/// Fila de acciones reutilizada por `PixelOverlayWidget` (Sprint 3) y
/// `PixelDetailScreen` (Sprint 4).
///
/// No depende directamente de ningún Provider: recibe `pixel` y
/// `onLikeToggle` desde el caller, que decide cómo persistir el estado
/// (PixelProvider en el overlay, estado local + GridProvider en el detail
/// screen). Esto evita mutar providers durante el build de un widget hijo.
class PixelActionsWidget extends StatelessWidget {
  final PixelModel pixel;
  final VoidCallback onLikeToggle;
  final VoidCallback onEdit;
  final VoidCallback? onComment;
  final VoidCallback? onMessage;

  const PixelActionsWidget({
    super.key,
    required this.pixel,
    required this.onLikeToggle,
    required this.onEdit,
    this.onComment,
    this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionButton(
          icon: pixel.isLikedByMe ? Icons.favorite : Icons.favorite_border,
          label: '${pixel.likesCount}',
          color: pixel.isLikedByMe ? AppColors.like : AppColors.textSecondary,
          onTap: onLikeToggle,
        ),
        const SizedBox(width: 20),
        _ActionButton(
          icon: Icons.chat_bubble_outline,
          label: 'Comentar',
          onTap: onComment ??
              () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Comentarios disponibles en el Sprint 7'),
                    ),
                  ),
        ),
        const SizedBox(width: 20),
        _ActionButton(
          icon: Icons.share_outlined,
          label: 'Compartir',
          onTap: () {
            Share.share(
              '¡Mira este píxel de ${pixel.ownerName} en Pixel App! '
              'pixelapp://pixel/${pixel.id}',
            );
          },
        ),
        if (!pixel.isOwner && onMessage != null) ...[
          const SizedBox(width: 20),
          _ActionButton(
            icon: Icons.mail_outline,
            label: 'Mensaje',
            onTap: onMessage!,
          ),
        ],
        const Spacer(),
        if (pixel.isOwner)
          _ActionButton(icon: Icons.edit_outlined, label: 'Editar', onTap: onEdit),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color ?? AppColors.textSecondary, size: 24),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.caption.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
