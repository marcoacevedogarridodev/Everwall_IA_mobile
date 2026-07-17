import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../providers/grid_provider.dart';
import '../../providers/pixel_provider.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../pixel/pixel_actions_widget.dart';

/// Overlay con la imagen en grande, info del owner, likes, comentarios y
/// acciones (like / comentar / compartir / editar) — spec sección 3.2.
///
/// Se abre como bottom sheet desde InfiniteGridWidget con
/// `PixelProvider.select(pixel)` ya hecho por el caller.
///
/// El sistema de comentarios completo llega en el Sprint 7 (aquí solo se
/// muestra el contador). "Ver detalle completo" navega a PixelDetailScreen
/// y "Editar" a PixelEditScreen (ambos ya funcionales desde el Sprint 4).
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
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context)
                      .pushNamed(AppRoutes.pixelDetail, arguments: pixel);
                },
                child: AspectRatio(
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
                    PixelActionsWidget(
                      pixel: pixel,
                      onLikeToggle: () {
                        context.read<PixelProvider>().toggleLikeOptimistic();
                        context.read<GridProvider>().applyOptimisticLike(
                              pixel.positionKey,
                              !pixel.isLikedByMe,
                            );
                      },
                      onEdit: () {
                        Navigator.of(context).pop();
                        Navigator.of(context)
                            .pushNamed(AppRoutes.pixelEdit, arguments: pixel);
                      },
                    ),
                    const SizedBox(height: 18),
                    const Divider(color: AppColors.divider),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Comentarios (${pixel.commentsCount})',
                          style: AppTextStyles.body,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pushNamed(
                              AppRoutes.pixelDetail,
                              arguments: pixel,
                            );
                          },
                          child: const Text('Ver detalle completo'),
                        ),
                      ],
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
