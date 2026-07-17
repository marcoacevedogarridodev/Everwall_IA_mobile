import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/pixel_model.dart';
import '../../providers/grid_provider.dart';
import '../../providers/pixel_provider.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';

/// Overlay con la imagen en grande, info del owner, likes, comentarios y
/// acciones (like / comentar / compartir / editar) — spec sección 3.2.
///
/// Se abre como bottom sheet desde InfiniteGridWidget con
/// `PixelProvider.select(pixel)` ya hecho por el caller.
///
/// El sistema de comentarios completo llega en el Sprint 7 (aquí solo se
/// muestra el contador); "Editar" navega al flujo real en el Sprint 4.
class PixelOverlayWidget extends StatelessWidget {
  const PixelOverlayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final pixel = context.watch<PixelProvider>().selected;
    if (pixel == null) return const SizedBox.shrink();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              AspectRatio(
                aspectRatio: 1,
                child: CachedNetworkImage(
                  imageUrl: pixel.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.surfaceLight,
                    child: const Icon(Icons.broken_image_outlined,
                        color: AppColors.textSecondary),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pixel.ownerName, style: AppTextStyles.title),
                    const SizedBox(height: 6),
                    Text(pixel.ownerMessage, style: AppTextStyles.bodySecondary),
                    const SizedBox(height: 18),
                    _ActionsRow(pixel: pixel),
                    const SizedBox(height: 18),
                    const Divider(color: AppColors.divider),
                    const SizedBox(height: 10),
                    Text(
                      'Comentarios (${pixel.commentsCount})',
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'El listado de comentarios y la posibilidad de '
                        'responder llegan en el Sprint 7 💬',
                        style: AppTextStyles.caption,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionsRow extends StatelessWidget {
  final PixelModel pixel;
  const _ActionsRow({required this.pixel});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionButton(
          icon: pixel.isLikedByMe ? Icons.favorite : Icons.favorite_border,
          label: '${pixel.likesCount}',
          color: pixel.isLikedByMe ? AppColors.like : AppColors.textSecondary,
          onTap: () {
            context.read<PixelProvider>().toggleLikeOptimistic();
            context.read<GridProvider>().applyOptimisticLike(
                  pixel.positionKey,
                  !pixel.isLikedByMe,
                );
          },
        ),
        const SizedBox(width: 20),
        _ActionButton(
          icon: Icons.chat_bubble_outline,
          label: 'Comentar',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Comentarios disponibles en el Sprint 7'),
              ),
            );
          },
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
        const Spacer(),
        if (pixel.isOwner)
          _ActionButton(
            icon: Icons.edit_outlined,
            label: 'Editar',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Edición de píxel disponible en el Sprint 4'),
                ),
              );
            },
          ),
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
            Text(
              label,
              style: AppTextStyles.caption.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
