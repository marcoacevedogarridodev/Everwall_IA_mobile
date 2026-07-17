import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../utils/validators.dart';
import '../../widgets/auth/auth_text_field.dart';
import '../../widgets/auth/gradient_button.dart';

/// Reset Password Screen (spec 2.4, paso "Confirm").
/// POST /auth/password-reset/confirm/ { token, password }
///
/// El token normalmente llega por deep link desde el email (Sprint 9); por
/// ahora se ingresa manualmente para que el flujo sea 100% funcional ya.
class ResetPasswordScreen extends StatefulWidget {
  final String? initialToken;
  const ResetPasswordScreen({super.key, this.initialToken});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tokenController;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(text: widget.initialToken ?? '');
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.confirmPasswordReset(
      token: _tokenController.text.trim(),
      newPassword: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña actualizada. Inicia sesión de nuevo.'),
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'No se pudo restablecer')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Nueva contraseña')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                AuthTextField(
                  controller: _tokenController,
                  hintText: 'Código / token recibido por email',
                  prefixIcon: Icons.vpn_key_outlined,
                  validator: (v) =>
                      Validators.requiredField(v, field: 'El token'),
                ),
                const SizedBox(height: 14),
                AuthTextField(
                  controller: _passwordController,
                  hintText: 'Nueva contraseña',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  validator: Validators.strongPassword,
                ),
                const SizedBox(height: 14),
                AuthTextField(
                  controller: _confirmPasswordController,
                  hintText: 'Confirmar contraseña',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  validator: (v) => Validators.confirmPassword(
                    v,
                    _passwordController.text,
                  ),
                  onFieldSubmitted: (_) => _onSubmit(),
                ),
                const SizedBox(height: 22),
                GradientButton(
                  label: 'Restablecer contraseña',
                  isLoading: isLoading,
                  onPressed: _onSubmit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
