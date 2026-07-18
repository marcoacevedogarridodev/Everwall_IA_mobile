import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/colors.dart';
import '../../utils/validators.dart';
import '../../widgets/auth/auth_text_field.dart';
import '../../widgets/auth/gradient_button.dart';

/// Profile Edit Screen (spec sección 7, "Editar perfil").
/// PATCH /auth/me/ (endpoint propuesto — ver AuthService.updateProfile
/// y PENDING_BACKEND_ENDPOINTS.md).
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.updateProfile(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'No se pudo actualizar')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Editar perfil')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.surfaceLight,
                    child: Text(user?.initials ?? '?'),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Subida de foto de perfil pendiente de endpoint — ver PENDING_BACKEND_ENDPOINTS.md',
                        ),
                      ),
                    ),
                    child: const Text('Cambiar foto'),
                  ),
                ),
                const SizedBox(height: 12),
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
                  textInputAction: TextInputAction.done,
                  validator: (v) => Validators.name(v, field: 'El apellido'),
                  onFieldSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 24),
                GradientButton(
                  label: 'Guardar cambios',
                  isLoading: isLoading,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
