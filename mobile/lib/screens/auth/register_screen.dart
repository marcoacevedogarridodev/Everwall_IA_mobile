import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../utils/validators.dart';
import '../../widgets/auth/auth_text_field.dart';
import '../../widgets/auth/gradient_button.dart';

/// Register Screen (spec 2.2): email, first name, last name, password
/// (fuerte), confirm password, checkbox de términos.
///
/// POST /auth/register/ vía AuthProvider.register(). Al tener éxito navega
/// a Verify Email, pasando el email para el botón "Reenviar".
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _acceptedTerms = false;
  bool _termsError = false;

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    final formValid = _formKey.currentState!.validate();
    setState(() => _termsError = !_acceptedTerms);
    if (!formValid || !_acceptedTerms) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      email: _emailController.text.trim(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.verifyEmail,
        arguments: _emailController.text.trim(),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'No se pudo registrar')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                AuthTextField(
                  controller: _emailController,
                  hintText: 'Email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                const SizedBox(height: 14),
                AuthTextField(
                  controller: _firstNameController,
                  hintText: 'Nombre',
                  prefixIcon: Icons.person_outline,
                  validator: (v) => Validators.name(v, field: 'El nombre'),
                ),
                const SizedBox(height: 14),
                AuthTextField(
                  controller: _lastNameController,
                  hintText: 'Apellido',
                  prefixIcon: Icons.person_outline,
                  validator: (v) => Validators.name(v, field: 'El apellido'),
                ),
                const SizedBox(height: 14),
                AuthTextField(
                  controller: _passwordController,
                  hintText: 'Contraseña',
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
                const SizedBox(height: 16),
                CheckboxListTile(
                  value: _acceptedTerms,
                  onChanged: (v) => setState(() {
                    _acceptedTerms = v ?? false;
                    _termsError = false;
                  }),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.primary,
                  title: const Text(
                    'Acepto los Términos y Condiciones',
                    style: AppTextStyles.bodySecondary,
                  ),
                ),
                if (_termsError)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Debes aceptar los términos para continuar',
                      style: AppTextStyles.error,
                    ),
                  ),
                const SizedBox(height: 8),
                GradientButton(
                  label: 'Crear Cuenta',
                  isLoading: isLoading,
                  onPressed: _onSubmit,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
