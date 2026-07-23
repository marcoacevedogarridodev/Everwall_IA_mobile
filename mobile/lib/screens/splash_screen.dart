import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/colors.dart';
import 'auth/login_screen.dart';
import 'main/main_screen.dart';

/// "Bootstrap" screen — NO dibuja ningún ícono ni logo propio, y en
/// condiciones normales el usuario NUNCA la ve. El único splash visible
/// es el NATIVO (pubspec.yaml -> flutter_native_splash, generado con
/// `dart run flutter_native_splash:create`), que `main.dart` mantiene
/// fijo en pantalla (`FlutterNativeSplash.preserve`) mientras esta
/// screen hace su trabajo por detrás.
///
/// Antes existían DOS splashes (el nativo + un widget de Flutter con el
/// mismo ícono encima) — como cada uno lo renderiza con su propio motor,
/// siempre se iba a notar el salto por más que se calzara el tamaño en
/// dp. La solución no es igualar dos splashes: es que exista solo UNO.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // El splash nativo se mantiene en pantalla mientras esto corre — no
    // hace falta un piso de tiempo artificial: dura lo que demore la
    // validación real de sesión contra GET /auth/me/.
    await context.read<AuthProvider>().checkAuthStatus();
    if (!mounted) return;

    final isAuthenticated = context.read<AuthProvider>().isAuthenticated;

    // Reemplazo INSTANTÁNEO (transición de duración cero) — igual que
    // Instagram/WhatsApp: van directo del splash del sistema a la
    // primera pantalla real, sin slide ni fade de por medio. Se navega
    // directo al widget (no por nombre de ruta) para evitar la
    // transición con slide que sí usan el resto de las rutas nombradas.
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) =>
            isAuthenticated ? const MainScreen() : const LoginScreen(),
      ),
    );

    // Saca el splash nativo recién en el frame siguiente, una vez la
    // pantalla de destino ya está construida y pintada detrás — así el
    // reemplazo se ve como un solo corte directo (splash -> app), sin
    // pasar por ningún frame vacío/negro en el medio.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Red de seguridad: en condiciones normales esto nunca se pinta en
    // pantalla (el splash nativo lo tapa todo hasta el remove() de
    // arriba). Mismo negro, sin ícono ni animación.
    return const Scaffold(backgroundColor: AppColors.background);
  }
}