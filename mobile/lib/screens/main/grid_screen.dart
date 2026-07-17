import 'package:flutter/material.dart';
import '../../config/routes.dart';
import '../../theme/colors.dart';
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
      body: const InfiniteGridWidget(),
      floatingActionButton: GridFloatingButton(
        onPressed: () {
          Navigator.of(context).pushNamed(AppRoutes.pixelPurchase);
        },
      ),
    );
  }
}
