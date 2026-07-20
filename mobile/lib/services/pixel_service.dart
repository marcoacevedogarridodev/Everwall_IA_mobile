import 'dart:io';
import 'package:dio/dio.dart';
import '../models/comment_model.dart';
import '../models/message_model.dart';
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

  /// Resuelve un único píxel por ID reutilizando `search_pixel` (spec 4).
  /// No hay un endpoint "GET /pixels/{id}/" dedicado en tu lista, así que
  /// usamos el de búsqueda con el ID exacto como query — necesario para
  /// abrir Pixel Detail Screen desde un deep link (`pixelapp://pixel/{id}`,
  /// Sprint 9) que solo trae el ID, no el objeto completo.
  Future<PixelModel?> getPixelById(String id) async {
    final results = await searchPixel(id);
    if (results.isEmpty) return null;
    final exactMatch = results.where((p) => p.id == id).toList();
    return exactMatch.isNotEmpty ? exactMatch.first : results.first;
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

  /// POST /pixels/edit_pixel_content/ — edición de un píxel propio
  /// (owner_name, owner_message y, opcionalmente, una nueva imagen).
  /// Siempre se manda como multipart para soportar ambos casos con el
  /// mismo método sin duplicar lógica.
  Future<PixelModel> editPixelContent({
    required String pixelId,
    required String ownerName,
    required String ownerMessage,
    File? image,
  }) async {
    final map = <String, dynamic>{
      'pixel_id': pixelId,
      'owner_name': ownerName,
      'owner_message': ownerMessage,
    };

    if (image != null) {
      map['images'] = await MultipartFile.fromFile(
        image.path,
        filename: image.path.split('/').last,
      );
    }

    final data =
        await _api.multipart('/pixels/edit_pixel_content/', FormData.fromMap(map));
    final pixelJson =
        (data as Map<String, dynamic>)['pixel'] as Map<String, dynamic>? ?? data;
    return PixelModel.fromJson(pixelJson);
  }

  /// POST /pixels/toggle_like/ — endpoint PROPUESTO (no existía en la
  /// lista de endpoints reales que compartiste). Sigue el mismo patrón
  /// de acción que el resto de /pixels/ (`initiate_purchase`,
  /// `edit_pixel_content`, etc): POST con `pixel_id` en el body, retorna
  /// el nuevo estado del like.
  ///
  /// Contrato propuesto — impleméntalo así en Django para que calce sin
  /// tocar el mobile, o avísame el nombre/formato real que uses y ajusto
  /// acá (único lugar que lo necesita):
  ///
  ///   POST /api/pixels/toggle_like/
  ///   Body:     { "pixel_id": "<id>" }
  ///   Response: { "likes_count": <int>, "is_liked": <bool> }
  ///
  /// Ver PENDING_BACKEND_ENDPOINTS.md en la raíz del proyecto para el
  /// checklist completo de endpoints inventados en el mobile.
  Future<({int likesCount, bool isLiked})> toggleLike(String pixelId) async {
    final data = await _api.post('/pixels/toggle_like/', data: {
      'pixel_id': pixelId,
    }) as Map<String, dynamic>;

    return (
      likesCount: (data['likes_count'] as num?)?.toInt() ?? 0,
      isLiked: data['is_liked'] as bool? ?? false,
    );
  }

  /// GET /pixels/share_pixel/ — lista de conversaciones del usuario
  /// (spec sección 6, Messages Screen). Ver nota de formato asumido en
  /// message_model.dart / PENDING_BACKEND_ENDPOINTS.md.
  Future<List<ChatSummaryModel>> getChatList() async {
    final data = await _api.get('/pixels/share_pixel/');
    final list = _extractList(data);
    return list.map((e) => ChatSummaryModel.fromJson(e)).toList();
  }

  /// GET /pixels/share_pixel/?pixel_id=X — mensajes de una conversación
  /// puntual (Pixel Chat Detail).
  Future<List<MessageModel>> getMessages(String pixelId, {String? currentUserId}) async {
    final data = await _api.get('/pixels/share_pixel/', query: {'pixel_id': pixelId});
    final list = _extractList(data);
    return list
        .map((e) => MessageModel.fromJson(e, currentUserId: currentUserId))
        .toList();
  }

  /// POST /pixels/share_pixel/ — envía un mensaje público o privado sobre
  /// un píxel.
  Future<MessageModel> sendMessage({
    required String pixelId,
    required String message,
    required bool isPrivate,
    String? currentUserId,
  }) async {
    final data = await _api.post('/pixels/share_pixel/', data: {
      'pixel_id': pixelId,
      'message': message,
      'is_private': isPrivate,
    }) as Map<String, dynamic>;

    final messageJson = data['message'] as Map<String, dynamic>? ?? data;
    return MessageModel.fromJson(messageJson, currentUserId: currentUserId);
  }

  /// GET /pixels/pixel_comments/?pixel_id=X — endpoint PROPUESTO (spec
  /// sección 9.2, comentarios públicos). Ver comment_model.dart y
  /// PENDING_BACKEND_ENDPOINTS.md para el contrato completo.
  Future<List<CommentModel>> getComments(String pixelId, {String? currentUserId}) async {
    final data = await _api.get('/pixels/pixel_comments/', query: {'pixel_id': pixelId});
    final list = _extractList(data);
    return list
        .map((e) => CommentModel.fromJson(e, currentUserId: currentUserId))
        .toList();
  }

  /// POST /pixels/pixel_comments/ — endpoint PROPUESTO. Crea un
  /// comentario público sobre un píxel.
  Future<CommentModel> addComment({
    required String pixelId,
    required String message,
    String? currentUserId,
  }) async {
    final data = await _api.post('/pixels/pixel_comments/', data: {
      'pixel_id': pixelId,
      'message': message,
    }) as Map<String, dynamic>;

    final commentJson = data['comment'] as Map<String, dynamic>? ?? data;
    return CommentModel.fromJson(commentJson, currentUserId: currentUserId);
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
