import 'package:flutter/material.dart';
import '../../theme/colors.dart';

/// FAB "+" para iniciar la compra de un píxel (spec 3.3).
/// El flujo real de compra/upload se conecta en el Sprint 4; por ahora
/// navega a un placeholder vía el callback `onPressed` inyectado por
/// GridScreen.
class GridFloatingButton extends StatelessWidget {
  final VoidCallback onPressed;

  const GridFloatingButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: AppColors.primary,
      elevation: 4,
      child: const Icon(Icons.add, color: Colors.white, size: 28),
    );
  }
}
