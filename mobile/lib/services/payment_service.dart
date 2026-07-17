import 'dart:io';
import 'package:dio/dio.dart';
import '../models/payment_model.dart';
import '../models/pixel_model.dart';
import 'api_service.dart';

/// Mapea el flujo de compra completo (spec 8.1):
///
///   POST /pixels/initiate_purchase/       multipart: x, y, images, owner_name, owner_message, currency
///   POST /pixels/create_payment_intent/   { session_id, currency }
///   POST /pixels/confirm_purchase/        { payment_intent_id, session_id }
class PaymentService {
  PaymentService._();
  static final PaymentService instance = PaymentService._();

  final _api = ApiService.instance;

  Future<PurchaseSessionModel> initiatePurchase({
    required int x,
    required int y,
    required File image,
    required String ownerName,
    required String ownerMessage,
    required String currency,
  }) async {
    final formData = FormData.fromMap({
      'x': x,
      'y': y,
      'owner_name': ownerName,
      'owner_message': ownerMessage,
      'currency': currency,
      'images': await MultipartFile.fromFile(
        image.path,
        filename: image.path.split('/').last,
      ),
    });

    final data = await _api.multipart('/pixels/initiate_purchase/', formData);
    return PurchaseSessionModel.fromJson(data as Map<String, dynamic>);
  }

  Future<PaymentIntentModel> createPaymentIntent({
    required String sessionId,
    required String currency,
  }) async {
    final data = await _api.post('/pixels/create_payment_intent/', data: {
      'session_id': sessionId,
      'currency': currency,
    });
    return PaymentIntentModel.fromJson(data as Map<String, dynamic>);
  }

  Future<PixelModel> confirmPurchase({
    required String paymentIntentId,
    required String sessionId,
  }) async {
    final data = await _api.post('/pixels/confirm_purchase/', data: {
      'payment_intent_id': paymentIntentId,
      'session_id': sessionId,
    }) as Map<String, dynamic>;

    // Soporta tanto { pixel: {...} } como el pixel devuelto directo.
    final pixelJson = data['pixel'] as Map<String, dynamic>? ?? data;
    return PixelModel.fromJson(pixelJson);
  }
}
