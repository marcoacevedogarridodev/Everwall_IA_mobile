import '../models/pixel_model.dart';
import 'api_service.dart';

/// Mapea los endpoints de píxeles usados por la grilla y navegación
/// (el resto — compra, pago, edición, mensajes — se conecta en Sprints 4-6):
///
///   GET /pixels/grid_status/?x_min=&x_max=&y_min=&y_max=
///   GET /pixels/recent_pixels/
///   GET /pixels/search_pixel/?q=
///   GET /pixels/my_pixels/
///   GET /pixels/stats/
///
/// NOTA IMPORTANTE sobre `grid_status`: asumí que acepta un rango de
/// coordenadas por query params (`x_min`, `x_max`, `y_min`, `y_max`) para
/// poder cargar solo la región visible del viewport, como pediste en el
/// spec ("estilo Google Maps"). Si tu endpoint real espera otros nombres
/// de parámetro (o pagina distinto, ej. por cursor en vez de bounding
/// box), este es el único método a ajustar — el resto de la app no se ve
/// afectado.
class PixelService {
  PixelService._();
  static final PixelService instance = PixelService._();

  final _api = ApiService.instance;

  Future<List<PixelModel>> getGridStatus({
    required int xMin,
    required int xMax,
    required int yMin,
    required int yMax,
  }) async {
    final data = await _api.get('/pixels/grid_status/', query: {
      'x_min': xMin,
      'x_max': xMax,
      'y_min': yMin,
      'y_max': yMax,
    });

    final list = _extractList(data);
    return list.map((e) => PixelModel.fromJson(e)).toList();
  }

  Future<List<PixelModel>> getRecentPixels() async {
    final data = await _api.get('/pixels/recent_pixels/');
    final list = _extractList(data);
    return list.map((e) => PixelModel.fromJson(e)).toList();
  }

  Future<List<PixelModel>> searchPixel(String query) async {
    final data = await _api.get('/pixels/search_pixel/', query: {'q': query});
    final list = _extractList(data);
    return list.map((e) => PixelModel.fromJson(e)).toList();
  }

  Future<List<PixelModel>> getMyPixels() async {
    final data = await _api.get('/pixels/my_pixels/');
    final list = _extractList(data);
    return list.map((e) => PixelModel.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getStats() async {
    final data = await _api.get('/pixels/stats/');
    return data as Map<String, dynamic>;
  }

  /// DRF a veces pagina (`{ results: [...] }`) y a veces devuelve la lista
  /// directa (`[...]`). Soportamos ambos formatos acá para no repetir esta
  /// lógica en cada método.
  List<Map<String, dynamic>> _extractList(dynamic data) {
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    if (data is Map<String, dynamic> && data['results'] is List) {
      return (data['results'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }
}
