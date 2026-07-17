import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../utils/validators.dart';
import '../../widgets/auth/auth_text_field.dart';
import '../../widgets/auth/gradient_button.dart';

/// Forgot Password Screen (spec 2.4, paso "Request").
/// POST /auth/password-reset/ { email } -> backend envía email con link/token.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.requestPasswordReset(_emailController.text.trim());
    if (!mounted) return;

    if (success) {
      setState(() => _emailSent = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'No se pudo enviar el email')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _emailSent ? _buildSuccessState(context) : _buildForm(isLoading),
        ),
      ),
    );
  }

  Widget _buildForm(bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          const Text(
            'Ingresa tu email y te enviaremos instrucciones para restablecer tu contraseña.',
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: 20),
          AuthTextField(
            controller: _emailController,
            hintText: 'Email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: Validators.email,
            onFieldSubmitted: (_) => _onSubmit(),
          ),
          const SizedBox(height: 20),
          GradientButton(
            label: 'Enviar instrucciones',
            isLoading: isLoading,
            onPressed: _onSubmit,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.mark_email_read_outlined,
            size: 64, color: AppColors.success),
        const SizedBox(height: 16),
        const Text(
          'Revisa tu email',
          style: AppTextStyles.title,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Te enviamos instrucciones a ${_emailController.text.trim()}',
          style: AppTextStyles.bodySecondary,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        GradientButton(
          label: 'Ya tengo mi código',
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.resetPassword),
        ),
      ],
    );
  }
}
