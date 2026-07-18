import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/verify_email_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/main/main_screen.dart';
import '../screens/pixel/pixel_detail_screen.dart';
import '../screens/pixel/pixel_purchase_screen.dart';
import '../screens/pixel/pixel_payment_screen.dart';
import '../screens/pixel/pixel_edit_screen.dart';
import '../screens/chat/chat_detail_screen.dart';
import '../models/pixel_model.dart';
import '../models/payment_model.dart';
import '../models/message_model.dart';
import '../theme/animations.dart';

/// Nombres de ruta centralizados. Usar SIEMPRE estas constantes en vez de
/// strings sueltos al navegar (Navigator.pushNamed(context, AppRoutes.login)).
///
/// Las rutas de main/pixel/chat/settings se agregan progresivamente en los
/// siguientes sprints; por ahora solo splash y login están registradas.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyEmail = '/verify-email';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // Sprint 3+
  static const String main = '/main';
  static const String grid = '/grid';
  static const String search = '/search';
  static const String myPixels = '/my-pixels';
  static const String messages = '/messages';
  static const String profile = '/profile';

  // Sprint 4+
  static const String pixelDetail = '/pixel-detail';
  static const String pixelPurchase = '/pixel-purchase';
  static const String pixelPayment = '/pixel-payment';
  static const String pixelEdit = '/pixel-edit';
  static const String pixelUpload = '/pixel-upload';

  // Sprint 6+
  static const String chatDetail = '/chat-detail';

  // Sprint 8+
  static const String settings = '/settings';
  static const String profileEdit = '/profile-edit';

  /// Genera las rutas con una transición de slide consistente en toda la app.
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _buildRoute(const SplashScreen(), settings, fade: true);
      case login:
        return _buildRoute(const LoginScreen(), settings);
      case register:
        return _buildRoute(const RegisterScreen(), settings);
      case verifyEmail:
        final email = settings.arguments as String? ?? '';
        return _buildRoute(VerifyEmailScreen(email: email), settings);
      case forgotPassword:
        return _buildRoute(const ForgotPasswordScreen(), settings);
      case resetPassword:
        final token = settings.arguments as String?;
        return _buildRoute(
          ResetPasswordScreen(initialToken: token),
          settings,
        );
      case main:
        return _buildRoute(const MainScreen(), settings, fade: true);
      case pixelDetail:
        final pixel = settings.arguments as PixelModel;
        return _buildRoute(PixelDetailScreen(pixel: pixel), settings);
      case pixelPurchase:
        final args = settings.arguments as Map<String, int>?;
        return _buildRoute(
          PixelPurchaseScreen(
            initialX: args?['x'],
            initialY: args?['y'],
          ),
          settings,
        );
      case pixelPayment:
        final session = settings.arguments as PurchaseSessionModel;
        return _buildRoute(PixelPaymentScreen(session: session), settings);
      case pixelEdit:
        final pixel = settings.arguments as PixelModel;
        return _buildRoute(PixelEditScreen(pixel: pixel), settings);
      case chatDetail:
        final chat = settings.arguments as ChatSummaryModel;
        return _buildRoute(ChatDetailScreen(chat: chat), settings);
      // pixelUpload no tiene ruta nombrada: se navega con Navigator.push
      // directo desde PixelPurchaseScreen (ver ese archivo) porque retorna
      // un valor (el File elegido) vía Navigator.pop.
      default:
        return _buildRoute(
          Scaffold(
            body: Center(
              child: Text('Ruta no encontrada: ${settings.name}'),
            ),
          ),
          settings,
        );
    }
  }

  static Route<dynamic> _buildRoute(
    Widget page,
    RouteSettings settings, {
    bool fade = false,
  }) {
    return PageRouteBuilder(
      settings: settings,
      transitionDuration: AppAnimations.normal,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: fade
          ? AppAnimations.fadeTransition
          : AppAnimations.slideTransition,
    );
  }
}
