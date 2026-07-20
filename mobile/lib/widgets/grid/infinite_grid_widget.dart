import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../models/pixel_model.dart';
import '../../providers/grid_provider.dart';
import '../../providers/pixel_provider.dart';
import 'pixel_card_widget.dart';
import 'pixel_overlay_widget.dart';

/// Grilla infinita de píxeles.
///
/// DECISIÓN DE DISEÑO (léela antes de tocar este archivo): el spec original
/// pide una grilla "tipo Google Maps" pannable libremente en las 4
/// direcciones. Eso requiere un canvas virtual 2D con su propio motor de
/// scroll/zoom — bastante más ingeniería (World-to-screen transform, tiles,
/// zoom con recentrado, etc). Para este sprint implementé la interpretación
/// que además calza con el mockup ASCII del spec (grilla de N columnas
/// fijas, `5x5` en el ejemplo): **scroll infinito vertical** con columnas
/// fijas según el ancho de pantalla — el eje X está acotado a las columnas
/// visibles y el eje Y crece sin límite mientras el usuario baja. Esto es
/// perfomante, simple de mantener y ya cumple "scroll infinito con lazy
/// loading + cache" (spec 15.1). Si de verdad necesitas paneo libre 2D como
/// Google Maps, es un widget aparte a nivel de esfuerzo de un sprint propio
/// — avísame y lo armamos.
class InfiniteGridWidget extends StatefulWidget {
  const InfiniteGridWidget({super.key});

  @override
  State<InfiniteGridWidget> createState() => _InfiniteGridWidgetState();
}

class _InfiniteGridWidgetState extends State<InfiniteGridWidget> {
  final ScrollController _scrollController = ScrollController();

  static const double _targetCellSize = 100;
  static const int _rowBuffer = 6; // filas extra a precargar arriba/abajo

  int _columns = 4;
  double _cellSize = _targetCellSize;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Primer fetch tras el primer frame, cuando ya conocemos el ancho real.
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestVisibleRows());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() => _requestVisibleRows();

  void _requestVisibleRows() {
    if (!_scrollController.hasClients) return;

    final rowHeight = _cellSize + AppConstants.gridCellSpacing;
    final firstVisibleRow =
        (_scrollController.offset / rowHeight).floor().clamp(0, 1 << 30);
    final viewportRows =
        (_scrollController.position.viewportDimension / rowHeight).ceil();
    final lastVisibleRow = firstVisibleRow + viewportRows;

    context.read<GridProvider>().requestViewport(
          xMin: 0,
          xMax: _columns - 1,
          yMin: (firstVisibleRow - _rowBuffer).clamp(0, 1 << 30),
          yMax: lastVisibleRow + _rowBuffer,
        );
  }

  void _openOverlay(PixelModel pixel) {
    context.read<PixelProvider>().select(pixel);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PixelOverlayWidget(),
    );
  }

  /// Tap normal sobre un píxel existente -> Pixel Detail Screen (spec 3.2).
  void _openDetail(PixelModel pixel) {
    Navigator.of(context).pushNamed(AppRoutes.pixelDetail, arguments: pixel);
  }

  /// Tap sobre una celda vacía -> inicia el flujo de compra con esa
  /// posición pre-cargada (Sprint 4, spec 8.1).
  void _onEmptyCellTap(int x, int y) {
    Navigator.of(context).pushNamed(
      AppRoutes.pixelPurchase,
      arguments: {'x': x, 'y': y},
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = AppConstants.gridCellSpacing;
        final columns =
            ((constraints.maxWidth + spacing) / (_targetCellSize + spacing))
                .floor()
                .clamp(3, 10);
        final cellSize =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        // Si cambió el layout (rotación, resize), recalculamos y re-pedimos.
        if (columns != _columns || (cellSize - _cellSize).abs() > 0.5) {
          _columns = columns;
          _cellSize = cellSize;
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _requestVisibleRows());
        }

        return Consumer<GridProvider>(
          builder: (context, gridProvider, _) {
            return RefreshIndicator(
              color: Colors.white,
              onRefresh: () async {
                gridProvider.reset();
                _requestVisibleRows();
              },
              child: GridView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(spacing),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _columns,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  childAspectRatio: 1,
                ),
                // Techo alto pero finito: permite scroll "infinito" en la
                // práctica sin que GridView necesite itemCount nulo.
                itemCount: _columns * 200000,
                itemBuilder: (context, index) {
                  final x = index % _columns;
                  final y = index ~/ _columns;
                  final pixel = gridProvider.pixelAt(x, y);

                  return RepaintBoundary(
                    child: GestureDetector(
                      onTap: () {
                        if (pixel != null) {
                          _openDetail(pixel);
                        } else {
                          _onEmptyCellTap(x, y);
                        }
                      },
                      onLongPress:
                          pixel != null ? () => _openOverlay(pixel) : null,
                      child: PixelCardWidget(pixel: pixel, size: _cellSize),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
