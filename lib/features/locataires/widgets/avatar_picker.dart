import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/app_config.dart';
import '../../../core/design_system.dart';
import '../../auth/data/auth_repository.dart';
import '../../biens/data/photo_upload_repository.dart';

/// Sélecteur de photo de profil (avatar circulaire, 80px) — réutilisé par
/// `LocataireStep1Identite` (création) et `EditLocataireScreen`
/// (modification) : mêmes `image_picker`/`PhotoUploadRepository` que pour
/// les photos de Biens (T-033/T-034), avec `type: 'avatar'` (dossier
/// `avatars` côté serveur).
class AvatarPicker extends StatefulWidget {
  const AvatarPicker({
    super.key,
    required this.initials,
    required this.photoUrl,
    required this.onChanged,
  });

  final String initials;

  /// Chemin/URL brut tel que renvoyé par `/api/upload` (`photos`/`photo_
  /// profil_url`), pas encore résolu — voir `AppConfig.resolveFileUrl`.
  final String? photoUrl;

  /// Appelé avec le nouveau chemin après upload réussi, ou `null` après
  /// suppression.
  final ValueChanged<String?> onChanged;

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  late final PhotoUploadRepository _photoUploadRepository;
  final ImagePicker _picker = ImagePicker();

  bool _uploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _photoUploadRepository = PhotoUploadRepository(
      apiClient: AuthRepository.instance.apiClient,
    );
  }

  Future<void> _pick() async {
    final XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
    } catch (_) {
      setState(() => _error = 'Impossible d\'ouvrir la galerie.');
      return;
    }
    if (picked == null) return;

    setState(() {
      _uploading = true;
      _error = null;
    });

    final result = await _photoUploadRepository.uploadAvatarPhoto(
      File(picked.path),
    );
    if (!mounted) return;
    setState(() => _uploading = false);

    switch (result) {
      case UploadPhotoSuccess(path: final path):
        widget.onChanged(path);
      case UploadPhotoFailure(message: final message):
        setState(() => _error = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = widget.photoUrl != null && widget.photoUrl!.isNotEmpty;

    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _uploading ? null : _pick,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipOval(
                  child: Container(
                    width: 80,
                    height: 80,
                    color: AppColors.positiveSoft,
                    child: _uploading
                        ? const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : hasPhoto
                        ? Image.network(
                            AppConfig.resolveFileUrl(widget.photoUrl!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _initialsFallback(),
                          )
                        : _initialsFallback(),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      LucideIcons.camera,
                      size: 14,
                      color: AppColors.primaryForeground,
                    ),
                  ),
                ),
                if (hasPhoto && !_uploading)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: GestureDetector(
                      onTap: () => widget.onChanged(null),
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
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _error ?? 'Photo de profil (facultative)',
            textAlign: TextAlign.center,
            style: AppTypography.kpiNote(
              color: _error != null ? AppColors.error : AppColors.mutedForeground,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _initialsFallback() {
    return Center(
      child: Text(
        widget.initials.isEmpty ? '?' : widget.initials,
        style: AppTypography.titleSection(color: AppColors.primaryStrong),
      ),
    );
  }
}
