import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/colors.dart';

/// Indicador de carga reutilizable. `LoadingWidget.spinner` para loads
/// puntuales (botones, pantallas completas); `LoadingWidget.shimmerGrid`
/// para el estado inicial de la grilla (spec 15.1: shimmer effect).
class LoadingWidget extends StatelessWidget {
  final String? message;
  final bool compact;

  const LoadingWidget({super.key, this.message, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: compact ? 20 : 36,
            height: compact ? 20 : 36,
            child: const CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2.4,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(message!, style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

/// Placeholder shimmer para una celda individual del grid mientras carga.
class ShimmerCell extends StatelessWidget {
  final double size;
  const ShimmerCell({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceLight,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
