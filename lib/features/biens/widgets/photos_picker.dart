import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/app_config.dart';
import '../../../core/design_system.dart';
import '../../auth/data/auth_repository.dart';
import '../data/photo_upload_repository.dart';

/// Sélecteur de photos de bien (galerie → upload immédiat via
/// `PhotoUploadRepository.uploadPropertyPhoto`, `type: 'property'`, aperçu,
/// suppression), partagé par l'étape 1 de création d'immeuble
/// (`ImmeubleStep1Identite`), `EditImmeubleScreen` et `NouveauLotScreen`.
/// Extrait tel quel de ces écrans, qui en avaient chacun une copie (même
/// rendu, même limite de 10 photos).
///
/// Contrôlé : [photoUrls] vient du parent, chaque changement lui est remonté
/// par [onChanged] sous forme d'une nouvelle liste (chemins serveur déjà
/// uploadés, jamais des fichiers locaux).
class PhotosPicker extends StatefulWidget {
  const PhotosPicker({
    super.key,
    required this.photoUrls,
    required this.onChanged,
    this.label = 'Photos (optionnel)',
  });

  final List<String> photoUrls;
  final ValueChanged<List<String>> onChanged;
  final String label;

  static const int maxPhotos = 10;

  @override
  State<PhotosPicker> createState() => _PhotosPickerState();
}

class _PhotosPickerState extends State<PhotosPicker> {
  late final PhotoUploadRepository _photoUploadRepository =
      PhotoUploadRepository(apiClient: AuthRepository.instance.apiClient);
  final ImagePicker _picker = ImagePicker();

  bool _uploadingPhotos = false;
  String? _photoError;

  Future<void> _pickAndUploadPhotos() async {
    final List<XFile> picked;
    try {
      picked = await _picker.pickMultiImage(imageQuality: 85);
    } catch (_) {
      if (!mounted) return;
      setState(() => _photoError = 'Impossible d\'ouvrir la galerie.');
      return;
    }
    if (picked.isEmpty) return;

    setState(() {
      _uploadingPhotos = true;
      _photoError = null;
    });

    var failureCount = 0;
    String? lastFailureMessage;
    final remainingSlots =
        PhotosPicker.maxPhotos - widget.photoUrls.length;
    for (final xfile in picked.take(remainingSlots < 0 ? 0 : remainingSlots)) {
      final result = await _photoUploadRepository.uploadPropertyPhoto(
        File(xfile.path),
      );
      if (!mounted) return;
      switch (result) {
        case UploadPhotoSuccess(path: final path):
          // `widget` relu à chaque tour : le parent a pu reconstruire avec la
          // liste mise à jour par le tour précédent.
          widget.onChanged([...widget.photoUrls, path]);
        case UploadPhotoFailure(message: final message):
          failureCount++;
          lastFailureMessage = message;
      }
    }

    if (!mounted) return;
    setState(() {
      _uploadingPhotos = false;
      _photoError = failureCount == 0
          ? null
          : '$failureCount photo(s) non envoyée(s) : $lastFailureMessage';
    });
  }

  void _removePhoto(int index) {
    widget.onChanged([...widget.photoUrls]..removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final photoUrls = widget.photoUrls;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.label, style: AppTypography.labelField()),
            Text(
              '${photoUrls.length}/${PhotosPicker.maxPhotos}',
              style: AppTypography.bodySmall(
                color: AppColors.mutedForeground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (photoUrls.length < PhotosPicker.maxPhotos)
              InkWell(
                onTap: _uploadingPhotos ? null : _pickAndUploadPhotos,
                borderRadius: AppRadius.borderMd,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: AppRadius.borderMd,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: _uploadingPhotos
                      ? const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.camera,
                              size: 22,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Ajouter',
                              style: AppTypography.kpiNote(
                                color: AppColors.primary,
                                fontSize: 11,
                              ).copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                ),
              ),
            ...photoUrls.asMap().entries.map((entry) {
              final index = entry.key;
              final path = entry.value;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: AppRadius.borderMd,
                    child: Image.network(
                      AppConfig.resolveFileUrl(path),
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 88,
                        height: 88,
                        color: AppColors.muted,
                        child: Icon(
                          LucideIcons.image_off,
                          size: 22,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: GestureDetector(
                      onTap: () => _removePhoto(index),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.x,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
        if (_photoError != null) ...[
          const SizedBox(height: 8),
          Text(
            _photoError!,
            style: AppTypography.bodySmall(color: AppColors.error),
          ),
        ],
      ],
    );
  }
}
