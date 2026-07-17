import 'package:flutter/material.dart';
import '../../models/pixel_model.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';

/// Sección de comentarios en Pixel Detail Screen. El sistema completo
/// (listar últimos 3, público/privado, responder) se conecta en el
/// Sprint 7 — `CommentModel` y el endpoint real de comentarios llegan ahí.
/// Por ahora muestra el contador y un estado explicativo.
class PixelCommentsWidget extends StatelessWidget {
  final PixelModel pixel;
  const PixelCommentsWidget({super.key, required this.pixel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Comentarios (${pixel.commentsCount})', style: AppTextStyles.title),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.chat_bubble_outline,
                  color: AppColors.textSecondary),
              const SizedBox(height: 8),
              const Text(
                'El listado de comentarios (públicos y respuestas privadas '
                'por chat) llega en el Sprint 7.',
                style: AppTextStyles.bodySecondary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
