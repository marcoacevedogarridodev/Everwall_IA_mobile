import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/common/custom_app_bar.dart';

/// Profile Screen (spec sección 7). El header + logout ya son funcionales
/// (conectados a AuthProvider / POST /auth/logout/). Estadísticas de
/// píxeles/likes y edición de perfil se completan en el Sprint 8.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Perfil'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 12),
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.surfaceLight,
              child: Text(user?.initials ?? '?', style: AppTextStyles.headline2),
            ),
            const SizedBox(height: 16),
            Text(
              user?.fullName ?? '',
              style: AppTextStyles.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(user?.email ?? '', style: AppTextStyles.bodySecondary),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Píxeles',
                    value: '${user?.pixelsCount ?? 0}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Likes recibidos',
                    value: '${user?.likesReceived ?? 0}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _ProfileOption(
              icon: Icons.edit_outlined,
              label: 'Editar perfil',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Disponible en el Sprint 8')),
              ),
            ),
            _ProfileOption(
              icon: Icons.lock_outline,
              label: 'Cambiar contraseña',
              onTap: () {
                // AuthProvider.changePassword() ya está implementado y
                // mapeado a POST /auth/change-password/; falta el
                // formulario de UI (old/new password), que llega en el
                // Sprint 8 junto al resto de Profile/Settings.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Formulario completo de cambio de contraseña — Sprint 8',
                    ),
                  ),
                );
              },
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.login,
                    (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text('Cerrar sesión',
                  style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: AppColors.error),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.headline2),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ProfileOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(label, style: AppTextStyles.body),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
