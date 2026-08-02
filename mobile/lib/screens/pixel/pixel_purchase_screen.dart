import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_config.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/grid_provider.dart';
import '../../services/api_exception.dart';
import '../../services/payment_service.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/auth/gradient_button.dart';
import 'pixel_upload_screen.dart';

/// Pixel Purchase Screen (spec 8.1).
///
/// Ya NO tiene paso de selección manual de posición: al tocar "+" en la
/// grilla, se asigna automáticamente la primera coordenada libre y se abre
/// de inmediato el selector de imagen (cámara/galería). El usuario ve un
/// único flujo: "+" -> elegir imagen -> nombre/mensaje/moneda -> pago.
class PixelPurchaseScreen extends StatefulWidget {
  final int? initialX;
  final int? initialY;

  const PixelPurchaseScreen({super.key, this.initialX, this.initialY});

  @override
  State<PixelPurchaseScreen> createState() => _PixelPurchaseScreenState();
}

class _PixelPurchaseScreenState extends State<PixelPurchaseScreen> {
  late final TextEditingController _xController;
  late final TextEditingController _yController;
  late final TextEditingController _ownerNameController;
  final _ownerMessageController = TextEditingController();

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _startFlow());
  }

  @override
  void dispose() {
    _xController.dispose();
    _yController.dispose();
    _ownerNameController.dispose();
    _ownerMessageController.dispose();
    super.dispose();
  }

  /// Arranca el flujo apenas se abre la pantalla: asigna posición
  /// automáticamente (si no vino una explícita) y abre el selector de
  /// imagen de inmediato — sin mostrar ningún paso intermedio de
  /// selección de coordenadas.
  Future<void> _startFlow() async {
    if (widget.initialX == null || widget.initialY == null) {
      _assignAvailablePosition();
    }
    await _pickImageAndContinue();
  }

  /// Busca la primera celda libre (0,0 en adelante) usando el cache ya
  /// cargado en GridProvider. Si el grid todavía no terminó de cargar o
  /// está lleno, se queda en (0,0) — el backend valida igual al confirmar
  /// la compra en `initiate_purchase`.
  void _assignAvailablePosition() {
    final grid = context.read<GridProvider>();
    for (var y = 0; y < 100; y++) {
      for (var x = 0; x < 100; x++) {
        if (grid.pixelAt(x, y) == null) {
          _xController.text = '$x';
          _yController.text = '$y';
          return;
        }
      }
    }
  }

  Future<void> _pickImageAndContinue() async {
    final image = await Navigator.of(context).push<File>(
      MaterialPageRoute(builder: (_) => const PixelUploadScreen()),
    );

    if (!mounted) return;

    if (image == null) {
      // Canceló la selección de imagen — no hay paso previo al que
      // volver, así que se cierra todo el flujo de compra.
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _selectedImage = image;
      _showDetailsStep = true;
    });
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Detalles de tu imagen')),
      body: SafeArea(
        child: _showDetailsStep
            ? _buildDetailsStep()
            : const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
      ),
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
              labelText: 'Titulo para tu imagen (opcional)',
              counterText:
                  '$messageLength/${AppConstants.ownerMessageMaxLength}',
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _currency,
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
          ],
        ],
      ),
    );
  }
}
