import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import '../../theme/colors.dart';

/// Imagen del píxel con zoom/pan, usada en Pixel Detail Screen.
/// A diferencia de la celda del grid (que solo hace `cover`), acá el
/// usuario puede pellizcar para hacer zoom y ver el detalle real.
class PixelImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? height;

  const PixelImageWidget({super.key, required this.imageUrl, this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height ?? MediaQuery.of(context).size.width,
      width: double.infinity,
      child: PhotoView(
        imageProvider: NetworkImage(imageUrl),
        backgroundDecoration: const BoxDecoration(color: AppColors.surface),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2.5,
        loadingBuilder: (context, event) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image_outlined,
              color: AppColors.textSecondary, size: 40),
        ),
      ),
    );
  }
}
