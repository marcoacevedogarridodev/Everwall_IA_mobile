import 'package:flutter/material.dart';
import '../../config/routes.dart';
import '../../models/pixel_model.dart';
import '../../services/api_exception.dart';
import '../../services/pixel_service.dart';
import '../../theme/colors.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/grid/pixel_card_widget.dart';
import '../pixel/pixel_edit_screen.dart';

enum _LoadState { loading, loaded, empty, error }

/// My Pixels Screen (spec sección 5): grid estilo Instagram (3 columnas)
/// con todos los píxeles del usuario, vía GET /pixels/my_pixels/.
///
/// Tap -> Pixel Detail Screen. Long-press -> menú de opciones de edición
/// (spec: "Long Press → Opciones de edición"), que hoy ofrece "Editar
/// contenido" (ya conectado a POST /pixels/edit_pixel_content/).
class MyPixelsScreen extends StatefulWidget {
  const MyPixelsScreen({super.key});

  @override
  State<MyPixelsScreen> createState() => _MyPixelsScreenState();
}

class _MyPixelsScreenState extends State<MyPixelsScreen> {
  _LoadState _state = _LoadState.loading;
  List<PixelModel> _pixels = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = _LoadState.loading);
    try {
      final pixels = await PixelService.instance.getMyPixels();
      if (!mounted) return;
      setState(() {
        _pixels = pixels;
        _state = pixels.isEmpty ? _LoadState.empty : _LoadState.loaded;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _state = _LoadState.error;
      });
    }
  }

  void _openOptions(PixelModel pixel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility_outlined,
                  color: AppColors.textSecondary),
              title: const Text('Ver detalle'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context)
                    .pushNamed(AppRoutes.pixelDetail, arguments: pixel);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined,
                  color: AppColors.textSecondary),
              title: const Text('Editar contenido'),
              onTap: () async {
                Navigator.of(context).pop();
                final updated = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PixelEditScreen(pixel: pixel),
                  ),
                );
                if (updated is PixelModel && mounted) {
                  setState(() {
                    final index = _pixels.indexWhere((p) => p.id == pixel.id);
                    if (index != -1) _pixels[index] = updated;
                  });
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Mis Píxeles'),
      body: RefreshIndicator(
        color: Colors.white,
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _LoadState.loading:
        return const LoadingWidget();
      case _LoadState.error:
        return AppErrorWidget(
          message: _errorMessage ?? 'No se pudieron cargar tus píxeles',
          onRetry: _load,
        );
      case _LoadState.empty:
        return LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: constraints.maxHeight,
              child: EmptyStateWidget(
                icon: Icons.photo_library_outlined,
                title: 'Aún no tienes píxeles',
                subtitle: '¡Compra tu primero y hazlo tuyo en la grilla!',
                actionLabel: 'Comprar píxel',
                onAction: () =>
                    Navigator.of(context).pushNamed(AppRoutes.pixelPurchase),
              ),
            ),
          ),
        );
      case _LoadState.loaded:
        return GridView.builder(
          padding: const EdgeInsets.all(4),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: _pixels.length,
          itemBuilder: (context, index) {
            final pixel = _pixels[index];
            return GestureDetector(
              onTap: () => Navigator.of(context)
                  .pushNamed(AppRoutes.pixelDetail, arguments: pixel),
              onLongPress: () => _openOptions(pixel),
              child: LayoutBuilder(
                builder: (context, constraints) => PixelCardWidget(
                  pixel: pixel,
                  size: constraints.maxWidth,
                ),
              ),
            );
          },
        );
    }
  }
}
