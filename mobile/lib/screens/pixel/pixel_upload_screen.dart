import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/auth/gradient_button.dart';

/// Pantalla de selección de imagen (spec 8.1, paso 2: "Cámara / Galería,
/// Previsualización"). Se navega a ella (`Navigator.push`) desde
/// PixelPurchaseScreen y retorna el `File` elegido vía `Navigator.pop`.
///
/// NOTA de plataforma: `image_picker` requiere permisos nativos que no
/// viven en `lib/` — agrega en tu proyecto real:
///   iOS (ios/Runner/Info.plist): NSPhotoLibraryUsageDescription, NSCameraUsageDescription
///   Android (android/app/src/main/AndroidManifest.xml): CAMERA (si usas cámara; galería no requiere permiso en Android 13+ con photo_picker)
class PixelUploadScreen extends StatefulWidget {
  const PixelUploadScreen({super.key});

  @override
  State<PixelUploadScreen> createState() => _PixelUploadScreenState();
}

class _PixelUploadScreenState extends State<PixelUploadScreen> {
  final _picker = ImagePicker();
  File? _selectedImage;
  bool _isPicking = false;

  Future<void> _pick(ImageSource source) async {
    setState(() => _isPicking = true);
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (picked != null) {
        setState(() => _selectedImage = File(picked.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo acceder: $e')),
      );
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Selecciona una imagen')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _selectedImage != null
                      ? Image.file(_selectedImage!, fit: BoxFit.cover)
                      : const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.image_outlined,
                                  size: 56, color: AppColors.textSecondary),
                              SizedBox(height: 12),
                              Text(
                                'Ninguna imagen seleccionada',
                                style: AppTextStyles.bodySecondary,
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isPicking ? null : () => _pick(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Cámara'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        side: const BorderSide(color: AppColors.divider),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _isPicking ? null : () => _pick(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Galería'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        side: const BorderSide(color: AppColors.divider),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GradientButton(
                label: 'Usar esta imagen',
                onPressed: _selectedImage == null
                    ? null
                    : () => Navigator.of(context).pop(_selectedImage),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
