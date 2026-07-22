import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../generated/assets.dart';
import '../providers/auth_provider.dart';
import '../theme/animations.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// Splash screen: fondo negro, logo con efecto de brillo pulsante,
/// y transición fade a Login tras ~2.2s (spec: 2-3s).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glow;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _glow = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _scale = Tween<double>(begin: 0.94, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    // checkAuthStatus valida el token guardado contra GET /auth/me/ en
    // paralelo a la animación, para no agregar latencia extra visible.
    final authCheck = context.read<AuthProvider>().checkAuthStatus();
    await Future.wait([
      Future.delayed(AppAnimations.splash),
      authCheck,
    ]);

    if (!mounted) return;
    final isAuthenticated = context.read<AuthProvider>().isAuthenticated;
    Navigator.of(context).pushReplacementNamed(
      isAuthenticated ? AppRoutes.main : AppRoutes.login,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scale.value,
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: _glow.value * 0.6),
                      blurRadius: 40,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: child,
              ),
            );
          },
          child: const _LogoMark(),
        ),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.asset(
            Assets.logo,
            width: 96,
            height: 96,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 16),
        const Text('Pixel App', style: AppTextStyles.headline2),
      ],
    );
  }
}
