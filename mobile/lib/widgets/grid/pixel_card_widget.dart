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
///   esquina superior derecha), corazón de like (esquina inferior
///   izquierda — SIEMPRE visible: outline si no le he dado like, relleno
///   rojo si sí) y contador de vistas (esquina inferior derecha) según
///   spec sección 3.1.
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
            child: _PulsingIcon(
                icon: Icons.local_fire_department, color: AppColors.fire),
          ),
        // Corazón SIEMPRE visible: outline/transparente si no le he dado
        // like, relleno rojo si ya se lo di.
        Positioned(
          bottom: 3,
          left: 3,
          child: Icon(
            pixel!.isLikedByMe ? Icons.favorite : Icons.favorite_border,
            color: pixel!.isLikedByMe
                ? AppColors.like
                : Colors.white.withValues(alpha: 0.65),
            size: 20,
          ),
        ),
        // Contador de vistas.
        if (pixel!.viewsCount > 0)
          Positioned(
            bottom: 3,
            right: 3,
            child: _ViewsBadge(count: pixel!.viewsCount),
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

/// Pill pequeño con ícono de ojo + número de vistas, esquina inferior
/// derecha de la celda (spec: "contador de cuántas personas la han visto").
class _ViewsBadge extends StatelessWidget {
  final int count;
  const _ViewsBadge({required this.count});

  String get _formatted {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.remove_red_eye_outlined,
              size: 10, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            _formatted,
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
