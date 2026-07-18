import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/routes.dart';
import '../../models/pixel_model.dart';
import '../../services/api_exception.dart';
import '../../services/pixel_service.dart';
import '../../theme/colors.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/grid/pixel_card_widget.dart';

enum _SearchState { idle, loading, results, empty, error }

/// Search Screen (spec sección 4): búsqueda por ID en tiempo real contra
/// GET /pixels/search_pixel/?q={id}, con debounce para no disparar una
/// request por cada tecla.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  _SearchState _state = _SearchState.idle;
  List<PixelModel> _results = [];
  String? _errorMessage;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();

    if (query.isEmpty) {
      setState(() {
        _state = _SearchState.idle;
        _results = [];
      });
      return;
    }

    // Búsqueda "en tiempo real" (spec 4) pero con 400ms de debounce para
    // no spamear el backend en cada tecla.
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  Future<void> _search(String query) async {
    setState(() => _state = _SearchState.loading);
    try {
      final results = await PixelService.instance.searchPixel(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _state = results.isEmpty ? _SearchState.empty : _SearchState.results;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _state = _SearchState.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: false,
          keyboardType: TextInputType.number,
          onChanged: _onChanged,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Buscar píxel por ID…',
            prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () {
                      _controller.clear();
                      _onChanged('');
                    },
                  )
                : null,
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _SearchState.idle:
        return const EmptyStateWidget(
          icon: Icons.search,
          title: 'Busca un píxel',
          subtitle: 'Ingresa el ID numérico del píxel que buscas',
        );
      case _SearchState.loading:
        return const LoadingWidget();
      case _SearchState.error:
        return AppErrorWidget(
          message: _errorMessage ?? 'No se pudo buscar',
          onRetry: () => _search(_controller.text.trim()),
        );
      case _SearchState.empty:
        return const EmptyStateWidget(
          icon: Icons.search_off,
          title: 'Sin resultados',
          subtitle: 'No encontramos ningún píxel con ese ID',
        );
      case _SearchState.results:
        return GridView.builder(
          padding: const EdgeInsets.all(4),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: _results.length,
          itemBuilder: (context, index) {
            final pixel = _results[index];
            return GestureDetector(
              onTap: () => Navigator.of(context)
                  .pushNamed(AppRoutes.pixelDetail, arguments: pixel),
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
