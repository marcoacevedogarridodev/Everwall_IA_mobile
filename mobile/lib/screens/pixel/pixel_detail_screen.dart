import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../models/message_model.dart';
import '../../models/pixel_model.dart';
import '../../providers/grid_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/offline_service.dart';
import '../../services/pixel_service.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/pixel/pixel_actions_widget.dart';
import '../../widgets/pixel/pixel_comments_widget.dart';
import '../../widgets/pixel/pixel_image_widget.dart';
import '../../widgets/pixel/pixel_stats_widget.dart';

/// Pixel Detail Screen (spec sección 3.2 / navegación por tap normal):
/// imagen con zoom, owner, mensaje, stats, acciones y comentarios.
///
/// Recibe el `PixelModel` completo como argumento de ruta (evita un round
/// trip extra a la API ya que el grid/overlay ya lo tienen cargado).
/// Mantiene una copia local mutable para reflejar el like al instante y
/// sincroniza el cambio de vuelta a `GridProvider` para que el grid quede
/// consistente al volver atrás.
class PixelDetailScreen extends StatefulWidget {
  final PixelModel pixel;
  const PixelDetailScreen({super.key, required this.pixel});

  @override
  State<PixelDetailScreen> createState() => _PixelDetailScreenState();
}

class _PixelDetailScreenState extends State<PixelDetailScreen> {
  late PixelModel _pixel = widget.pixel;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logPixelView(_pixel.id);
  }

  /// Optimista contra `POST /pixels/toggle_like/` (endpoint PROPUESTO, ver
  /// PENDING_BACKEND_ENDPOINTS.md). Revierte si la request falla por algo
  /// que no sea falta de conexión (Sprint 9: si no hay señal, se encola en
  /// vez de intentar y revertir — ver OfflineService).
  Future<void> _toggleLike() async {
    final liked = !_pixel.isLikedByMe;
    final previous = _pixel;

    setState(() {
      _pixel = _pixel.copyWith(
        isLikedByMe: liked,
        likesCount: _pixel.likesCount + (liked ? 1 : -1),
      );
    });
    context.read<GridProvider>().applyOptimisticLike(_pixel.positionKey, liked);

    if (liked) {
      AnalyticsService.instance.logLikeGiven(_pixel.id);
    }

    if (!await OfflineService.instance.hasConnection) {
      await OfflineService.instance.queueLikeAction(_pixel.id);
      return;
    }

    try {
      final result = await PixelService.instance.toggleLike(_pixel.id);
      if (!mounted) return;
      setState(() {
        _pixel = _pixel.copyWith(
          isLikedByMe: result.isLiked,
          likesCount: result.likesCount,
        );
      });
      context
          .read<GridProvider>()
          .applyOptimisticLike(_pixel.positionKey, result.isLiked);
    } catch (_) {
      if (!mounted) return;
      setState(() => _pixel = previous);
      context
          .read<GridProvider>()
          .applyOptimisticLike(_pixel.positionKey, previous.isLikedByMe);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Píxel (${_pixel.x}, ${_pixel.y})')),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          PixelImageWidget(imageUrl: _pixel.imageUrl),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.surfaceLight,
                      child: Text(
                        _pixel.ownerName.isNotEmpty
                            ? _pixel.ownerName[0].toUpperCase()
                            : '?',
                        style: AppTextStyles.body,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(_pixel.ownerName, style: AppTextStyles.title),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(_pixel.ownerMessage, style: AppTextStyles.body),
                const SizedBox(height: 18),
                PixelActionsWidget(
                  pixel: _pixel,
                  onLikeToggle: _toggleLike,
                  onMessage: () => Navigator.of(context).pushNamed(
                    AppRoutes.chatDetail,
                    arguments: ChatSummaryModel(
                      pixelId: _pixel.id,
                      pixelImageUrl: _pixel.imageUrl,
                      pixelOwnerName: _pixel.ownerName,
                      lastMessage: '',
                    ),
                  ),
                  onEdit: () async {
                    final updated = await Navigator.of(context).pushNamed(
                      AppRoutes.pixelEdit,
                      arguments: _pixel,
                    );
                    if (updated is PixelModel && mounted) {
                      setState(() => _pixel = updated);
                    }
                  },
                ),
                const SizedBox(height: 18),
                PixelStatsWidget(pixel: _pixel),
                const SizedBox(height: 24),
                PixelCommentsWidget(pixel: _pixel),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
