import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_config.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../models/payment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/grid_provider.dart';
import '../../services/api_exception.dart';
import '../../services/payment_service.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/auth/gradient_button.dart';
import 'pixel_upload_screen.dart';

/// Pixel Purchase Screen (spec 8.1, pasos 1-4).
///
/// Paso 1: selección de posición (x, y) sobre una mini-ventana de la grilla
/// (reutiliza los datos ya cacheados en `GridProvider`).
/// Paso 2 (delegado): `PixelUploadScreen` para elegir la imagen.
/// Paso 3: formulario de owner_name / owner_message / currency, en esta
/// misma screen una vez vuelve con la imagen.
/// Paso 4: `POST /pixels/initiate_purchase/` → navega a
/// `PixelPaymentScreen` con la sesión creada para completar el pago.
class PixelPurchaseScreen extends StatefulWidget {
  final int? initialX;
  final int? initialY;

  const PixelPurchaseScreen({super.key, this.initialX, this.initialY});

  @override
  State<PixelPurchaseScreen> createState() => _PixelPurchaseScreenState();
}

class _PixelPurchaseScreenState extends State<PixelPurchaseScreen> {
  static const int _windowSize = 6;

  late final TextEditingController _xController;
  late final TextEditingController _yController;
  late final TextEditingController _ownerNameController;
  final _ownerMessageController = TextEditingController();

  int _windowBaseX = 0;
  int _windowBaseY = 0;
  String _currency = AppConstants.supportedCurrencies.first;
  File? _selectedImage;
  bool _showDetailsStep = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final x = widget.initialX ?? 0;
    final y = widget.initialY ?? 0;
    _xController = TextEditingController(text: '$x');
    _yController = TextEditingController(text: '$y');
    _ownerNameController = TextEditingController(
      text: context.read<AuthProvider>().user?.fullName ?? '',
    );
    _windowBaseX = x - (_windowSize ~/ 2);
    _windowBaseY = y - (_windowSize ~/ 2);
    WidgetsBinding.instance.addPostFrameCallback((_) => _searchZone());
  }

  @override
  void dispose() {
    _xController.dispose();
    _yController.dispose();
    _ownerNameController.dispose();
    _ownerMessageController.dispose();
    super.dispose();
  }

  void _searchZone() {
    final x = int.tryParse(_xController.text) ?? 0;
    final y = int.tryParse(_yController.text) ?? 0;
    setState(() {
      _windowBaseX = x - (_windowSize ~/ 2);
      _windowBaseY = y - (_windowSize ~/ 2);
    });
    context.read<GridProvider>().requestViewport(
          xMin: _windowBaseX,
          xMax: _windowBaseX + _windowSize - 1,
          yMin: _windowBaseY,
          yMax: _windowBaseY + _windowSize - 1,
        );
  }

  void _selectCell(int x, int y) {
    setState(() {
      _xController.text = '$x';
      _yController.text = '$y';
    });
  }

  Future<void> _continueToImage() async {
    final x = int.tryParse(_xController.text);
    final y = int.tryParse(_yController.text);
    if (x == null || y == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una posición X, Y válida')),
      );
      return;
    }

    final occupied = context.read<GridProvider>().pixelAt(x, y) != null;
    if (occupied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esa posición ya está ocupada, elige otra')),
      );
      return;
    }

    final image = await Navigator.of(context).push<File>(
      MaterialPageRoute(builder: (_) => const PixelUploadScreen()),
    );

    if (image != null && mounted) {
      setState(() {
        _selectedImage = image;
        _showDetailsStep = true;
      });
    }
  }

  Future<void> _submitPurchase() async {
    final x = int.parse(_xController.text);
    final y = int.parse(_yController.text);
    final ownerName = _ownerNameController.text.trim();
    final ownerMessage = _ownerMessageController.text.trim();

    if (ownerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa tu nombre')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final session = await PaymentService.instance.initiatePurchase(
        x: x,
        y: y,
        image: _selectedImage!,
        ownerName: ownerName,
        ownerMessage: ownerMessage,
        currency: _currency,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.pixelPayment,
        arguments: session,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_showDetailsStep ? 'Detalles del píxel' : 'Elige tu posición'),
        leading: _showDetailsStep
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _showDetailsStep = false),
              )
            : null,
      ),
      body: SafeArea(
        child: _showDetailsStep ? _buildDetailsStep() : _buildPositionStep(),
      ),
    );
  }

  Widget _buildPositionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Toca una celda disponible o ingresa coordenadas manualmente.',
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _xController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'X'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _yController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Y'),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                onPressed: _searchZone,
                icon: const Icon(Icons.search),
                style: IconButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildMiniGrid(),
          const SizedBox(height: 8),
          Row(
            children: const [
              _LegendDot(color: AppColors.surfaceLight, label: 'Disponible'),
              SizedBox(width: 16),
              _LegendDot(color: AppColors.surface, label: 'Ocupado'),
              SizedBox(width: 16),
              _LegendDot(color: AppColors.primary, label: 'Seleccionado'),
            ],
          ),
          const SizedBox(height: 28),
          GradientButton(label: 'Continuar', onPressed: _continueToImage),
        ],
      ),
    );
  }

  Widget _buildMiniGrid() {
    return Consumer<GridProvider>(
      builder: (context, gridProvider, _) {
        final selX = int.tryParse(_xController.text);
        final selY = int.tryParse(_yController.text);

        return AspectRatio(
          aspectRatio: 1,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _windowSize,
              mainAxisSpacing: 3,
              crossAxisSpacing: 3,
            ),
            itemCount: _windowSize * _windowSize,
            itemBuilder: (context, index) {
              final x = _windowBaseX + (index % _windowSize);
              final y = _windowBaseY + (index ~/ _windowSize);
              final occupied = gridProvider.pixelAt(x, y) != null;
              final isSelected = x == selX && y == selY;

              return GestureDetector(
                onTap: occupied ? null : () => _selectCell(x, y),
                child: Container(
                  decoration: BoxDecoration(
                    color: occupied
                        ? AppColors.surface
                        : (isSelected ? AppColors.primary : AppColors.surfaceLight),
                    borderRadius: BorderRadius.circular(6),
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: occupied
                      ? const Icon(Icons.block, size: 14, color: AppColors.textDisabled)
                      : null,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDetailsStep() {
    final messageLength = _ownerMessageController.text.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_selectedImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.file(_selectedImage!, fit: BoxFit.cover),
              ),
            ),
          const SizedBox(height: 20),
          TextField(
            controller: _ownerNameController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(labelText: 'Tu nombre'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _ownerMessageController,
            maxLength: AppConstants.ownerMessageMaxLength,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Mensaje (opcional)',
              counterText:
                  '$messageLength/${AppConstants.ownerMessageMaxLength}',
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _currency,
            dropdownColor: AppColors.surface,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(labelText: 'Moneda'),
            items: AppConstants.supportedCurrencies
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _currency = v ?? _currency),
          ),
          const SizedBox(height: 28),
          GradientButton(
            label: 'Confirmar compra',
            isLoading: _isSubmitting,
            onPressed: _submitPurchase,
          ),
          if (AppConfig.isDev) ...[
            const SizedBox(height: 12),
            const Text(
              'Posición ($x, $y) — POST /pixels/initiate_purchase/',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  String get x => _xController.text;
  String get y => _yController.text;
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}
