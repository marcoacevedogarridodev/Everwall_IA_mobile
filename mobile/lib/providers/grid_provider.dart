import 'dart:async';
import 'package:flutter/material.dart';
import '../models/pixel_model.dart';
import '../services/offline_service.dart';
import '../services/pixel_service.dart';

import '../services/analytics_service.dart';

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

  final Set<String> _viewedThisSession = {};

  bool hasViewedThisSession(String pixelId) =>
      _viewedThisSession.contains(pixelId);

  bool _isLoading = false;
  bool _isOffline = false;
  String? _error;
  Timer? _debounce;

  Map<String, PixelModel> get pixels => _pixels;
  bool get isLoading => _isLoading;
  bool get isOffline => _isOffline;
  String? get error => _error;

  List<String> get loadedImageUrls => _pixels.values
      .map((p) => p.imageUrl)
      .where((url) => url.isNotEmpty)
      .toList();

  PixelModel? pixelAt(int x, int y) => _pixels['$x,$y'];

  /// Lista de píxeles ordenados secuencialmente (por fecha de creación si
  /// está disponible; si no, por y y luego x) — usada por el layout tipo
  /// galería de InfiniteGridWidget, que ya no dibuja cada píxel en su
  /// coordenada (x,y) real sino que los va acomodando en orden, columna
  /// por columna, fila por fila, sin huecos por posiciones vacías del
  /// mapa. La coordenada real sigue viva como metadata (Pixel Detail),
  /// solo deja de determinar dónde se pinta en esta grilla.
  List<PixelModel> get pixelsSequential {
    final list = _pixels.values.toList();
    list.sort((a, b) {
      if (a.createdAt != null && b.createdAt != null) {
        return a.createdAt!.compareTo(b.createdAt!);
      }
      if (a.y != b.y) return a.y.compareTo(b.y);
      return a.x.compareTo(b.x);
    });
    return list;
  }

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
      final fetchXMax =
          (xs.reduce((a, b) => a > b ? a : b) + 1) * _kChunkSize - 1;
      final fetchYMin = ys.reduce((a, b) => a < b ? a : b) * _kChunkSize;
      final fetchYMax =
          (ys.reduce((a, b) => a > b ? a : b) + 1) * _kChunkSize - 1;

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
      _isOffline = false;

      // Cache best-effort para poder mostrar algo si se pierde la
      // conexión más adelante (spec 12.2). Nunca bloquea ni falla el flujo.
      unawaited(OfflineService.instance.cacheGridSnapshot(_pixels.values));
    } catch (e) {
      final cached = OfflineService.instance.getCachedGridSnapshot();
      if (cached.isNotEmpty) {
        for (final pixel in cached) {
          _pixels.putIfAbsent(pixel.positionKey, () => pixel);
        }
        _isOffline = true;
        _error = 'Sin conexión — mostrando la última grilla guardada.';
      } else {
        _error = 'No se pudo cargar la grilla. Desliza para reintentar.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Inyecta o actualiza un píxel directo en el cache (usado tras confirmar
  /// una compra o una edición exitosa, para reflejarlo al instante sin
  /// esperar un refetch de grid_status).
  void addOrUpdatePixel(PixelModel pixel) {
    _pixels[pixel.positionKey] = pixel;
    notifyListeners();
  }

  /// Refleja el toggle de like en el cache del grid al instante. La
  /// persistencia real (POST /pixels/toggle_like/, endpoint propuesto) la
  /// maneja el caller (PixelProvider / PixelDetailScreen) — esto solo
  /// mantiene la grilla visualmente consistente con lo que ve el usuario
  /// en el overlay/detail.
  void applyOptimisticLike(String positionKey, bool liked) {
    final pixel = _pixels[positionKey];
    if (pixel == null) return;
    _pixels[positionKey] = pixel.copyWith(
      isLikedByMe: liked,
      likesCount: pixel.likesCount + (liked ? 1 : -1),
    );
    notifyListeners();
  }

  Future<void> registerPixelView(PixelModel pixel) async {
    if (_viewedThisSession.contains(pixel.id)) return;
    _viewedThisSession.add(pixel.id);

    final current = _pixels[pixel.positionKey];
    if (current != null) {
      _pixels[pixel.positionKey] =
          current.copyWith(viewsCount: current.viewsCount + 1);
      notifyListeners();
    }

    try {
      final realCount = await _pixelService.registerView(pixel.id);
      final updated = _pixels[pixel.positionKey];
      if (updated != null) {
        _pixels[pixel.positionKey] = updated.copyWith(viewsCount: realCount);
        notifyListeners();
      }
    } catch (_) {
      // Endpoint aún no existe en el backend real — se mantiene el
      // conteo local optimista.
    }
  }

  /// 2do tap en adelante sobre la misma celda, misma sesión: toggle de
  /// like directo desde el grid (mismo patrón optimista + rollback que
  /// PixelProvider.toggleLikeOptimistic / PixelDetailScreen._toggleLike).
  Future<void> toggleLikeFromGrid(PixelModel pixel) async {
    final key = pixel.positionKey;
    final current = _pixels[key] ?? pixel;
    final optimisticLiked = !current.isLikedByMe;
    final previous = current;

    _pixels[key] = current.copyWith(
      isLikedByMe: optimisticLiked,
      likesCount: current.likesCount + (optimisticLiked ? 1 : -1),
    );
    notifyListeners();

    if (optimisticLiked) {
      AnalyticsService.instance.logLikeGiven(pixel.id);
    }

    if (!await OfflineService.instance.hasConnection) {
      await OfflineService.instance.queueLikeAction(pixel.id);
      return;
    }

    try {
      final result = await _pixelService.toggleLike(pixel.id);
      final updated = _pixels[key];
      if (updated != null) {
        _pixels[key] = updated.copyWith(
          isLikedByMe: result.isLiked,
          likesCount: result.likesCount,
        );
        notifyListeners();
      }
    } catch (_) {
      _pixels[key] = previous;
      notifyListeners();
    }
  }

  /// Limpia todo (útil en logout o pull-to-refresh completo).
  void reset() {
    _pixels.clear();
    _loadedChunks.clear();
    _viewedThisSession.clear();
    _error = null;
    _isOffline = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
