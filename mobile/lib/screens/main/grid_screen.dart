import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../providers/grid_provider.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/grid/grid_floating_button.dart';
import '../../widgets/grid/infinite_grid_widget.dart';

/// Grid Screen (spec sección 3): grilla infinita + FAB de compra.
/// La búsqueda tiene su propia tab/pantalla (Search Screen, Sprint 5), así
/// que el app bar acá solo muestra el logo.
class GridScreen extends StatelessWidget {
  const GridScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(showLogo: true),
      body: Stack(
        children: [
          const InfiniteGridWidget(),
          // Banner offline (spec 12.2): visible mientras GridProvider está
          // mostrando el último snapshot cacheado en vez de datos frescos.
          Consumer<GridProvider>(
            builder: (context, grid, _) {
              if (!grid.isOffline) return const SizedBox.shrink();
              return Positioned(
                top: 8,
                left: 12,
                right: 12,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off,
                            size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Sin conexión — mostrando datos guardados',
                            style: AppTextStyles.caption,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: GridFloatingButton(
        onPressed: () {
          Navigator.of(context).pushNamed(AppRoutes.pixelPurchase);
        },
      ),
    );
  }
}
