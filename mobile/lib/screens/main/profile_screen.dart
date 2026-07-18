import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/common/custom_app_bar.dart';

/// Profile Screen (spec sección 7): header, stats, editar perfil, cambiar
/// contraseña y logout — todo funcional desde el Sprint 8. El ícono de
/// engranaje en el app bar lleva a SettingsScreen (tema, notificaciones,
/// versión de la app).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Perfil',
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.settings),
          ),
        ],
      ),
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
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.profileEdit),
            ),
            _ProfileOption(
              icon: Icons.lock_outline,
              label: 'Cambiar contraseña',
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.changePassword),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  context.read<ChatProvider>().reset();
                }
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
