import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/constants.dart';
import '../../models/pixel_model.dart';
import '../../services/api_exception.dart';
import '../../services/pixel_service.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/auth/gradient_button.dart';

/// Pixel Edit Screen (spec sección 8.1 arquitectura / edición post-compra).
/// POST /pixels/edit_pixel_content/ — permite al dueño actualizar el
/// mensaje y, opcionalmente, reemplazar la imagen.
///
/// Recibe el `PixelModel` a editar como argumento de ruta y retorna
/// (`Navigator.pop`) el `PixelModel` actualizado para que
/// `PixelDetailScreen` refresque su estado local.
class PixelEditScreen extends StatefulWidget {
  final PixelModel pixel;
  const PixelEditScreen({super.key, required this.pixel});

  @override
  State<PixelEditScreen> createState() => _PixelEditScreenState();
}

class _PixelEditScreenState extends State<PixelEditScreen> {
  late final TextEditingController _messageController;
  File? _newImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController(text: widget.pixel.ownerMessage);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (picked != null) {
      setState(() => _newImage = File(picked.path));
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final updated = await PixelService.instance.editPixelContent(
        pixelId: widget.pixel.id,
        ownerName: widget.pixel.ownerName,
        ownerMessage: _messageController.text.trim(),
        image: _newImage,
      );
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messageLength = _messageController.text.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Editar píxel')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _newImage != null
                        ? Image.file(_newImage!, fit: BoxFit.cover)
                        : Image.network(
                            widget.pixel.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.surface,
                              child: const Icon(Icons.broken_image_outlined,
                                  color: AppColors.textSecondary),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_camera_outlined, size: 18),
                  label: const Text('Cambiar imagen'),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _messageController,
                maxLength: AppConstants.ownerMessageMaxLength,
                maxLines: 3,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Mensaje',
                  counterText:
                      '$messageLength/${AppConstants.ownerMessageMaxLength}',
                ),
              ),
              const SizedBox(height: 24),
              GradientButton(
                label: 'Guardar cambios',
                isLoading: _isSaving,
                onPressed: _save,
              ),
              const SizedBox(height: 8),
              const Text(
                'La posición y el propietario del píxel no se pueden cambiar.',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
