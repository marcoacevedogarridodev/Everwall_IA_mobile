import 'dart:async';
import 'package:flutter/material.dart';
import '../models/pixel_model.dart';
import '../services/pixel_service.dart';

/// Tamaño de "chunk" (en celdas) usado para trackear qué regiones ya se
/// cargaron y evitar refetch al pasar por la misma zona dos veces.
const int _kChunkSize = 16;

/// Estado global de la grilla infinita. `InfiniteGridWidget` le pide cargar
/// la región visible cada vez que el usuario hace pan; el provider cachea
/// por chunk para no golpear la API en cada frame.
class GridProvider extends ChangeNotifier {
  final _pixelService = PixelService.instance;

  /// Cache de píxeles existentes, key = "x,y" (PixelModel.positionKey).
  final Map<String, PixelModel> _pixels = {};

  /// Chunks ya solicitados (key = "chunkX,chunkY") para no repetir requests.
  final Set<String> _loadedChunks = {};

  bool _isLoading = false;
  String? _error;
  Timer? _debounce;

  Map<String, PixelModel> get pixels => _pixels;
  bool get isLoading => _isLoading;
  String? get error => _error;

  PixelModel? pixelAt(int x, int y) => _pixels['$x,$y'];

  /// Llamado por InfiniteGridWidget con la región visible actual (más un
  /// margen/buffer). Debounced para no disparar una request por cada pixel
  /// de scroll durante un pan rápido.
  void requestViewport({
    required int xMin,
    required int xMax,
    required int yMin,
    required int yMax,
  }) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      _loadMissingChunks(xMin: xMin, xMax: xMax, yMin: yMin, yMax: yMax);
    });
  }

  Future<void> _loadMissingChunks({
    required int xMin,
    required int xMax,
    required int yMin,
    required int yMax,
  }) async {
    final chunkXMin = (xMin / _kChunkSize).floor();
    final chunkXMax = (xMax / _kChunkSize).floor();
    final chunkYMin = (yMin / _kChunkSize).floor();
    final chunkYMax = (yMax / _kChunkSize).floor();

    final missingChunks = <String>[];
    for (var cx = chunkXMin; cx <= chunkXMax; cx++) {
      for (var cy = chunkYMin; cy <= chunkYMax; cy++) {
        final key = '$cx,$cy';
        if (!_loadedChunks.contains(key)) {
          missingChunks.add(key);
        }
      }
    }
    if (missingChunks.isEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Se pide como un solo rectángulo que cubre todos los chunks faltantes
      // (más simple y menos requests que uno por chunk individual).
      final xs = missingChunks.map((k) => int.parse(k.split(',')[0]));
      final ys = missingChunks.map((k) => int.parse(k.split(',')[1]));
      final fetchXMin = xs.reduce((a, b) => a < b ? a : b) * _kChunkSize;
      final fetchXMax = (xs.reduce((a, b) => a > b ? a : b) + 1) * _kChunkSize - 1;
      final fetchYMin = ys.reduce((a, b) => a < b ? a : b) * _kChunkSize;
      final fetchYMax = (ys.reduce((a, b) => a > b ? a : b) + 1) * _kChunkSize - 1;

      final result = await _pixelService.getGridStatus(
        xMin: fetchXMin,
        xMax: fetchXMax,
        yMin: fetchYMin,
        yMax: fetchYMax,
      );

      for (final pixel in result) {
        _pixels[pixel.positionKey] = pixel;
      }
      _loadedChunks.addAll(missingChunks);
    } catch (e) {
      _error = 'No se pudo cargar la grilla. Desliza para reintentar.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Actualización optimista tras dar like (Sprint 7 conecta el endpoint
  /// real; por ahora esto solo refleja el toggle en memoria).
  void applyOptimisticLike(String positionKey, bool liked) {
    final pixel = _pixels[positionKey];
    if (pixel == null) return;
    _pixels[positionKey] = pixel.copyWith(
      isLikedByMe: liked,
      likesCount: pixel.likesCount + (liked ? 1 : -1),
    );
    notifyListeners();
  }

  /// Limpia todo (útil en logout o pull-to-refresh completo).
  void reset() {
    _pixels.clear();
    _loadedChunks.clear();
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
