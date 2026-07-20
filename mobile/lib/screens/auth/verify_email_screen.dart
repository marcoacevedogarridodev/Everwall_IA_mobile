import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/auth/gradient_button.dart';

/// Verify Email Screen (spec 2.3).
///
/// Recibe el email por argumento de ruta para poder reenviar la
/// verificación: POST /auth/resend-verification/ { email }.
///
/// La auto-detección por deep link (miapp://verify?token=...) se agrega en
/// el Sprint 9 junto al resto de deep links. Mientras tanto se incluye un
/// campo manual para pegar el token del email como fallback funcional:
/// POST /auth/verify-email/ { token }.
class VerifyEmailScreen extends StatefulWidget {
  final String email;
  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _tokenController = TextEditingController();
  bool _isVerifying = false;
  int _resendCooldown = 0;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _resend() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.resendVerification(widget.email);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Email de verificación reenviado'
              : (auth.errorMessage ?? 'No se pudo reenviar'),
        ),
      ),
    );

    if (success) {
      setState(() => _resendCooldown = 30);
      _tickCooldown();
    }
  }

  void _tickCooldown() async {
    while (_resendCooldown > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _resendCooldown--);
    }
  }

  Future<void> _verifyWithToken() async {
    if (_tokenController.text.trim().isEmpty) return;
    setState(() => _isVerifying = true);

    final auth = context.read<AuthProvider>();
    try {
      await auth.confirmEmailToken(_tokenController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Email verificado! Ya puedes iniciar sesión.'),
        ),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token inválido o expirado')),
      );
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.mark_email_read_outlined,
                  size: 72, color: AppColors.primary),
              const SizedBox(height: 20),
              const Text(
                'Verifica tu email',
                style: AppTextStyles.headline2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Te hemos enviado un email de verificación a\n${widget.email}',
                style: AppTextStyles.bodySecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: _resendCooldown == 0 ? _resend : null,
                child: Text(
                  _resendCooldown == 0
                      ? 'Reenviar email'
                      : 'Reenviar en ${_resendCooldown}s',
                ),
              ),
              const SizedBox(height: 24),
              const Row(
                children: [
                  Expanded(child: Divider(color: AppColors.divider)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('o pega el token', style: AppTextStyles.caption),
                  ),
                  Expanded(child: Divider(color: AppColors.divider)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _tokenController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration:
                    const InputDecoration(hintText: 'Token de verificación'),
              ),
              const SizedBox(height: 16),
              GradientButton(
                label: 'Verificar',
                isLoading: _isVerifying,
                onPressed: _verifyWithToken,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
