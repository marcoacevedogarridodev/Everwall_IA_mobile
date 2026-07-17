import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/empty_state_widget.dart';

/// My Pixels Screen (spec sección 5): grid 3 columnas con los píxeles del
/// usuario, vía GET /pixels/my_pixels/. Se implementa completa en el
/// Sprint 5; `PixelService.getMyPixels()` ya existe y está listo para usar.
class MyPixelsScreen extends StatelessWidget {
  const MyPixelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Mis Píxeles'),
      body: const EmptyStateWidget(
        icon: Icons.photo_library_outlined,
        title: 'Tu galería de píxeles',
        subtitle: 'Disponible en el Sprint 5',
      ),
    );
  }
}
