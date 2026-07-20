import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/common/custom_app_bar.dart';

/// Settings Screen (arquitectura spec): preferencias de la app (tema,
/// notificaciones) + accesos directos a cuenta (editar perfil, cambiar
/// contraseña) + info de la app + logout.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled =
          prefs.getBool(AppConstants.keyNotificationsEnabled) ?? true;
      _appVersion = '${info.version}+${info.buildNumber}';
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyNotificationsEnabled, value);
    // Nota: esto solo controla si la app pide permiso / muestra push
    // localmente. Avisar al backend que el usuario desactivó notificaciones
    // requeriría el mismo endpoint propuesto en PENDING_BACKEND_ENDPOINTS.md
    // (POST /auth/register_device/) con un flag adicional — pendiente.
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Configuración'),
      body: ListView(
        children: [
          const _SectionHeader('Cuenta'),
          ListTile(
            leading: const Icon(Icons.person_outline, color: AppColors.textSecondary),
            title: const Text('Editar perfil'),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.profileEdit),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
            title: const Text('Cambiar contraseña'),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.changePassword),
          ),
          const Divider(color: AppColors.divider, height: 1),
          const _SectionHeader('Preferencias'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined, color: AppColors.textSecondary),
            title: const Text('Modo oscuro'),
            subtitle: const Text(
              'Pixel App está pensada para dark mode premium',
              style: AppTextStyles.caption,
            ),
            value: isDark,
            activeThumbColor: AppColors.primary,
            onChanged: (_) => themeProvider.toggleTheme(),
          ),
          SwitchListTile(
            secondary:
                const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
            title: const Text('Notificaciones push'),
            subtitle: const Text(
              'Likes, comentarios, mensajes y confirmaciones de compra',
              style: AppTextStyles.caption,
            ),
            value: _notificationsEnabled,
            activeThumbColor: AppColors.primary,
            onChanged: _toggleNotifications,
          ),
          const Divider(color: AppColors.divider, height: 1),
          const _SectionHeader('Acerca de'),
          ListTile(
            leading: const Icon(Icons.info_outline, color: AppColors.textSecondary),
            title: const Text('Versión'),
            trailing: Text(
              _appVersion.isEmpty ? '…' : _appVersion,
              style: AppTextStyles.bodySecondary,
            ),
          ),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  context.read<ChatProvider>().reset();
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
                }
              },
              icon: const Icon(Icons.logout, color: AppColors.error),
              label:
                  const Text('Cerrar sesión', style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: AppColors.error),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
