import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/empty_state_widget.dart';

/// Search Screen (spec sección 4): búsqueda por ID vía
/// GET /pixels/search_pixel/?q={id}. Se implementa completa en el Sprint 5;
/// `PixelService.searchPixel()` ya existe y está listo para usar.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Buscar'),
      body: const EmptyStateWidget(
        icon: Icons.search,
        title: 'Búsqueda de píxeles',
        subtitle: 'Disponible en el Sprint 5',
      ),
    );
  }
}
