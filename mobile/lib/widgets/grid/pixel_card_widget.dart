import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../config/constants.dart';
import '../../models/pixel_model.dart';
import '../../theme/colors.dart';
import 'package:shimmer/shimmer.dart';

/// Una celda de la grilla infinita.
///
/// - `pixel == null`: celda vacía/disponible (fondo surface + ícono "+").
/// - `pixel != null`: imagen del píxel + indicadores 🔥 (>50 likes,
///   esquina superior derecha) y ❤️ (liked by me, esquina inferior
///   izquierda) según spec sección 3.1.
class PixelCardWidget extends StatelessWidget {
  final PixelModel? pixel;
  final double size;

  const PixelCardWidget({super.key, required this.pixel, required this.size});

  @override
  Widget build(BuildContext context) {
    if (pixel == null) {
      return _EmptyCell(size: size);
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.gridCellRadius),
          child: CachedNetworkImage(
            imageUrl: pixel!.imageUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            placeholder: (context, url) => Shimmer.fromColors(
              baseColor: AppColors.surface,
              highlightColor: AppColors.surfaceLight,
              child: Container(color: AppColors.surface),
            ),
            errorWidget: (context, url, error) => Container(
              color: AppColors.surface,
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image_outlined,
                  color: AppColors.textSecondary, size: 20),
            ),
          ),
        ),
        if (pixel!.isOnFire)
          const Positioned(
            top: 3,
            right: 3,
            child: _PulsingIcon(icon: Icons.local_fire_department,
                color: AppColors.fire),
          ),
        if (pixel!.isLikedByMe)
          const Positioned(
            bottom: 3,
            left: 3,
            child: Icon(Icons.favorite, color: AppColors.like, size: 20),
          ),
      ],
    );
  }
}

class _EmptyCell extends StatelessWidget {
  final double size;
  const _EmptyCell({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.gridCellRadius),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.add, color: AppColors.textDisabled, size: size * 0.3),
    );
  }
}

/// Ícono con parpadeo suave (spec: animación de fuego).
class _PulsingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  const _PulsingIcon({required this.icon, required this.color});

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.5, end: 1.0).animate(_controller),
      child: Icon(widget.icon, color: widget.color, size: 20),
    );
  }
}
