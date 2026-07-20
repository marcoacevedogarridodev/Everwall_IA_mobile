import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../config/routes.dart';
import '../../models/payment_model.dart';
import '../../models/pixel_model.dart';
import '../../services/analytics_service.dart';
import '../../services/api_exception.dart';
import '../../services/payment_service.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../utils/formatters.dart';
import '../../widgets/auth/gradient_button.dart';

/// Pixel Payment Screen (spec 8.1 pasos 5-6, 8.2 "UI de Pago").
///
/// Recibe el `PurchaseSessionModel` (de `initiate_purchase`) como argumento
/// de ruta. Al entrar, pide el `client_secret` con `create_payment_intent`,
/// muestra el monto y un `CardField` de Stripe; al confirmar, llama a
/// `Stripe.instance.confirmPayment` y luego `confirm_purchase` para que el
/// backend cree el píxel definitivamente.
///
/// REQUIERE configurar `AppConfig.stripePublishableKey` con tu clave
/// pública real de Stripe y correr `Stripe.instance.applySettings()` en
/// main.dart (ya está agregado ahí). Apple Pay / Google Pay se listan como
/// mejora futura (spec 8.2) — no incluidos en este sprint.
///
/// ⚠️ Solo mobile por ahora: en Flutter Web, `flutter_stripe` necesita
/// configuración aparte (Stripe.js en `web/index.html`) que no está hecha
/// todavía — ver nota en `main.dart`. Esta screen detecta `kIsWeb` y
/// muestra un aviso en vez de intentar cobrar y crashear.
class PixelPaymentScreen extends StatefulWidget {
  final PurchaseSessionModel session;
  const PixelPaymentScreen({super.key, required this.session});

  @override
  State<PixelPaymentScreen> createState() => _PixelPaymentScreenState();
}

enum _PaymentStage { loadingIntent, readyToPay, processing, error, success, webNotSupported }

class _PixelPaymentScreenState extends State<PixelPaymentScreen> {
  _PaymentStage _stage = _PaymentStage.loadingIntent;
  PaymentIntentModel? _intent;
  bool _cardComplete = false;
  String? _errorMessage;
  PixelModel? _confirmedPixel;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // Evita llamar a create_payment_intent + Stripe en web (ver nota de
      // clase arriba) — nada que ganar mostrando loading para algo que no
      // va a poder cobrar.
      _stage = _PaymentStage.webNotSupported;
      return;
    }
    _createIntent();
  }

  Future<void> _createIntent() async {
    setState(() => _stage = _PaymentStage.loadingIntent);
    try {
      final intent = await PaymentService.instance.createPaymentIntent(
        sessionId: widget.session.sessionId,
        currency: widget.session.currency,
      );
      if (!mounted) return;
      setState(() {
        _intent = intent;
        _stage = _PaymentStage.readyToPay;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _stage = _PaymentStage.error;
      });
    }
  }

  Future<void> _pay() async {
    final intent = _intent;
    if (intent == null) return;

    setState(() => _stage = _PaymentStage.processing);

    try {
      final result = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: intent.clientSecret,
        data: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );

      if (result.status != PaymentIntentsStatus.Succeeded) {
        throw ApiException('El pago no se completó (${result.status.name})');
      }

      final pixel = await PaymentService.instance.confirmPurchase(
        paymentIntentId: intent.paymentIntentId,
        sessionId: widget.session.sessionId,
      );

      if (!mounted) return;
      setState(() {
        _confirmedPixel = pixel;
        _stage = _PaymentStage.success;
      });
      AnalyticsService.instance.logPurchaseComplete(
        pixelId: pixel.id,
        amount: intent.amount ?? 0,
        currency: intent.currency,
      );
    } on StripeException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.error.localizedMessage ?? 'Error al procesar el pago';
        _stage = _PaymentStage.readyToPay;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _stage = _PaymentStage.readyToPay;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Ocurrió un error inesperado';
        _stage = _PaymentStage.readyToPay;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pago'),
        automaticallyImplyLeading: _stage != _PaymentStage.success,
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    switch (_stage) {
      case _PaymentStage.webNotSupported:
        return _buildWebNotSupported();
      case _PaymentStage.loadingIntent:
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      case _PaymentStage.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 40),
                const SizedBox(height: 12),
                Text(
                  _errorMessage ?? 'No se pudo iniciar el pago',
                  style: AppTextStyles.bodySecondary,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton(onPressed: _createIntent, child: const Text('Reintentar')),
              ],
            ),
          ),
        );
      case _PaymentStage.success:
        return _buildSuccess();
      case _PaymentStage.readyToPay:
      case _PaymentStage.processing:
        return _buildPaymentForm();
    }
  }

  Widget _buildPaymentForm() {
    final intent = _intent!;
    final isProcessing = _stage == _PaymentStage.processing;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text('Total a pagar',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                Text(
                  Formatters.currency(intent.amount ?? 0, intent.currency),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text('Tarjeta de crédito o débito', style: AppTextStyles.body),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: CardField(
              style: const TextStyle(color: AppColors.textPrimary),
              onCardChanged: (details) {
                setState(() => _cardComplete = details?.complete ?? false);
              },
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(_errorMessage!, style: AppTextStyles.error),
          ],
          const SizedBox(height: 12),
          const Text(
            'Apple Pay / Google Pay estarán disponibles próximamente.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 24),
          GradientButton(
            label:
                'Pagar ${Formatters.currency(intent.amount ?? 0, intent.currency)}',
            isLoading: isProcessing,
            onPressed: _cardComplete && !isProcessing ? _pay : null,
          ),
        ],
      ),
    );
  }

  Widget _buildWebNotSupported() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.phone_iphone, color: AppColors.primary, size: 56),
            const SizedBox(height: 20),
            const Text('Pagos disponibles en la app móvil', style: AppTextStyles.title),
            const SizedBox(height: 10),
            const Text(
              'El cobro con tarjeta (Stripe) todavía no está configurado para '
              'la versión web — pruébalo desde un emulador o celular Android/iOS. '
              'El resto de la app funciona igual acá.',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GradientButton(
              label: 'Volver a la grilla',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 72),
            const SizedBox(height: 20),
            const Text('¡Compra exitosa!', style: AppTextStyles.headline2),
            const SizedBox(height: 8),
            Text(
              'Tu píxel en (${_confirmedPixel?.x}, ${_confirmedPixel?.y}) ya está en la grilla.',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            GradientButton(
              label: 'Ver en la grilla',
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.main,
                    (route) => false,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
