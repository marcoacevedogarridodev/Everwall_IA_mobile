import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../models/pixel_model.dart';
import '../../providers/grid_provider.dart';
import '../../providers/pixel_provider.dart';
import 'pixel_overlay_widget.dart';

import 'rotating_pixel_card_widget.dart';

/// Grilla de píxeles comprados, en orden secuencial tipo galería
/// (Instagram-style): cada celda visual representa uno de los píxeles
/// comprados, NO su coordenada (x,y) real en el mapa 100x100 del backend
/// — así ningún píxel queda "fuera del ancho visible" del dispositivo.
///
/// Efecto de rotación (pared viva): cada [_rotationInterval] se genera una
/// nueva PERMUTACIÓN de la misma lista de píxeles y se reasigna qué píxel
/// va en cada celda. Al ser una permutación (biyección) de un mismo
/// conjunto, es matemáticamente imposible que dos celdas muestren la
/// misma imagen a la vez, y con el tiempo todas van rotando de posición.
class InfiniteGridWidget extends StatefulWidget {
  const InfiniteGridWidget({super.key});

  @override
  State<InfiniteGridWidget> createState() => _InfiniteGridWidgetState();
}

class _InfiniteGridWidgetState extends State<InfiniteGridWidget> {
  final ScrollController _scrollController = ScrollController();
  static const _rotationInterval = Duration(seconds: 4);

  static const double _targetCellSize = 100;

  int _columns = 4;
  double _cellSize = _targetCellSize;

  final _random = Random();
  Timer? _rotationTimer;

  /// Orden actualmente mostrado en pantalla — una permutación de los
  /// píxeles reales. Se resetea cada vez que cambia el conjunto de
  /// píxeles (nueva compra, refresh) y se vuelve a barajar cada
  /// [_rotationInterval].
  List<PixelModel> _displayedPixels = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestAllPixels());
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  /// Pide el mapa completo una sola vez (spec: 100x100). Si en el futuro
  /// hay muchos más píxeles reales, esto se puede paginar por lotes desde
  /// el backend en vez de pedir todo el rango de golpe.
  void _requestAllPixels() {
    context.read<GridProvider>().requestViewport(
          xMin: 0,
          xMax: 99,
          yMin: 0,
          yMax: 99,
        );
  }

  bool _sameIds(List<PixelModel> a, List<PixelModel> b) {
    if (a.length != b.length) return false;
    final idsA = a.map((p) => p.id).toSet();
    final idsB = b.map((p) => p.id).toSet();
    return idsA.length == idsB.length && idsA.difference(idsB).isEmpty;
  }

  bool _sameOrder(List<PixelModel> a, List<PixelModel> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  void _restartRotationTimer() {
    _rotationTimer?.cancel();
    if (_displayedPixels.length < 2) return; // nada que rotar

    // Rotación parcial: cada tick intercambia solo 1-2 pares al azar (no
    // se re-baraja toda la grilla). El resto de las celdas queda quieto,
    // así el efecto se siente como "de vez en cuando dos fotos cambian de
    // lugar" en vez de un refresh completo simultáneo — mucho más sutil y
    // profesional que un shuffle total.
    _rotationTimer = Timer.periodic(_rotationInterval, (_) {
      if (!mounted) return;
      setState(() {
        final updated = List<PixelModel>.from(_displayedPixels);
        final swaps = _displayedPixels.length >= 6 ? 2 : 1;

        for (var s = 0; s < swaps; s++) {
          final i = _random.nextInt(updated.length);
          int j;
          do {
            j = _random.nextInt(updated.length);
          } while (j == i);

          final temp = updated[i];
          updated[i] = updated[j];
          updated[j] = temp;
        }

        _displayedPixels = updated;
      });
    });
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

  /// Tap en la celda "vacía" al final de la secuencia -> inicia el flujo
  /// de compra genérico (el usuario elige/confirma la posición ahí).
  void _onBuyNextTap() {
    Navigator.of(context).pushNamed(AppRoutes.pixelPurchase);
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

        if (columns != _columns || (cellSize - _cellSize).abs() > 0.5) {
          _columns = columns;
          _cellSize = cellSize;
        }

        return Consumer<GridProvider>(
          builder: (context, gridProvider, _) {
            final sequential = gridProvider.pixelsSequential;

            // El conjunto real de píxeles cambió (primera carga, nueva
            // compra, refresh) — resincroniza el orden mostrado y
            // reinicia el timer de rotación. Diferido a post-frame porque
            // no se puede hacer setState durante el build de este widget.
            if (!_sameIds(sequential, _displayedPixels)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() => _displayedPixels = List.of(sequential));
                _restartRotationTimer();
              });
            }

            final gridSource =
                _displayedPixels.isEmpty ? sequential : _displayedPixels;
            final imagePool = gridProvider.loadedImageUrls;

            return RefreshIndicator(
              color: Colors.white,
              onRefresh: () async {
                gridProvider.reset();
                _requestAllPixels();
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
                // +1: slot final vacío = "comprar el siguiente píxel".
                itemCount: gridSource.length + 1,
                itemBuilder: (context, index) {
                  final pixel =
                      index < gridSource.length ? gridSource[index] : null;

                  return RepaintBoundary(
                    child: GestureDetector(
                      onTap: () {
                        if (pixel != null) {
                          _openDetail(pixel);
                        } else {
                          _onBuyNextTap();
                        }
                      },
                      onLongPress:
                          pixel != null ? () => _openOverlay(pixel) : null,
                      child: RotatingPixelCardWidget(
                        pixel: pixel,
                        size: _cellSize,
                      ),
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