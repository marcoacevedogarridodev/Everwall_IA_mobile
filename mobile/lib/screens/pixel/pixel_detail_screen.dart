import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/grid_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/offline_service.dart';
import '../../services/pixel_service.dart';
import '../../models/pixel_model.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/pixel/pixel_comments_widget.dart';
import '../../widgets/pixel/pixel_image_widget.dart';

/// Pixel Detail Screen: imagen con zoom, overlay de dueño + acciones
/// (like, vistas, compartir) sobre la imagen, y comentarios.
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

  void _share() {
    Share.share(
      '¡Mira este píxel de ${_pixel.ownerName} en EverWall! '
      'pixelapp://pixel/${_pixel.id}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(showLogo: true),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildImageWithOverlay(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_pixel.ownerMessage, style: AppTextStyles.body),
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

  Widget _buildImageWithOverlay() {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: PixelImageWidget(imageUrl: _pixel.imageUrl),
        ),
        // Degradado inferior para que el texto/íconos se lean bien
        // sobre cualquier imagen.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.65),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 14,
          right: 14,
          bottom: 12,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Nombre del dueño — costado izquierdo.
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.surfaceLight,
                      child: Text(
                        _pixel.ownerName.isNotEmpty
                            ? _pixel.ownerName[0].toUpperCase()
                            : '?',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _pixel.ownerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Like + vistas + compartir — costado derecho.
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ImageStatIcon(
                    icon: _pixel.isLikedByMe
                        ? Icons.favorite
                        : Icons.favorite_border,
                    label: '${_pixel.likesCount}',
                    color: _pixel.isLikedByMe ? AppColors.like : Colors.white,
                    onTap: _toggleLike,
                  ),
                  const SizedBox(width: 14),
                  _ImageStatIcon(
                    icon: Icons.remove_red_eye_outlined,
                    label: '${_pixel.viewsCount}',
                    color: Colors.white,
                  ),
                  const SizedBox(width: 14),
                  _ImageStatIcon(
                    icon: Icons.share_outlined,
                    color: Colors.white,
                    onTap: _share,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ImageStatIcon extends StatelessWidget {
  final IconData icon;
  final String? label;
  final Color color;
  final VoidCallback? onTap;

  const _ImageStatIcon({
    required this.icon,
    required this.color,
    this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            if (label != null) ...[
              const SizedBox(width: 4),
              Text(
                label!,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
