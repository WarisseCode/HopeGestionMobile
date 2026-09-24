import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/design_system.dart';
import '../../auth/data/auth_repository.dart';
import '../data/photo_upload_repository.dart';
import '../models/nouveau_immeuble_form.dart';

/// Étape 1 : Identité de l'immeuble (nom, type, étages, capacité prévue,
/// photos).
class ImmeubleStep1Identite extends StatefulWidget {
  const ImmeubleStep1Identite({super.key, required this.form});
  final NouveauImmeubleForm form;

  @override
  State<ImmeubleStep1Identite> createState() => _ImmeubleStep1IdentiteState();
}

class _ImmeubleStep1IdentiteState extends State<ImmeubleStep1Identite> {
  late final TextEditingController _nomCtrl;
  late final TextEditingController _etagesCtrl;
  late final TextEditingController _lotsCtrl;
  late final TextEditingController _descCtrl;
  late final PhotoUploadRepository _photoUploadRepository;
  final ImagePicker _picker = ImagePicker();

  bool _uploadingPhotos = false;
  String? _photoError;

  @override
  void initState() {
    super.initState();
    final f = widget.form;
    _nomCtrl = TextEditingController(text: f.nom);
    _etagesCtrl = TextEditingController(text: f.nombreEtages.toString());
    _lotsCtrl = TextEditingController(text: f.totalLots?.toString() ?? '');
    _descCtrl = TextEditingController(text: f.description);
    _photoUploadRepository = PhotoUploadRepository(
      apiClient: AuthRepository.instance.apiClient,
    );

    _nomCtrl.addListener(() => f.nom = _nomCtrl.text);
    _etagesCtrl.addListener(
      () => f.nombreEtages = int.tryParse(_etagesCtrl.text) ?? 0,
    );
    _lotsCtrl.addListener(
      () => f.totalLots = int.tryParse(_lotsCtrl.text),
    );
    _descCtrl.addListener(() => f.description = _descCtrl.text);
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _etagesCtrl.dispose();
    _lotsCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

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
    final remainingSlots = 10 - widget.form.photoUrls.length;
    for (final xfile in picked.take(remainingSlots < 0 ? 0 : remainingSlots)) {
      final result = await _photoUploadRepository.uploadPropertyPhoto(
        File(xfile.path),
      );
      if (!mounted) return;
      switch (result) {
        case UploadPhotoSuccess(path: final path):
          setState(() => widget.form.photoUrls.add(path));
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
    setState(() => widget.form.photoUrls.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ÉTAPE 1',
            style: AppTypography.labelUppercase(
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 4),
          Text('Identité de l\'immeuble', style: AppTypography.titleScreen()),
          const SizedBox(height: 24),

          AppTextField(
            controller: _nomCtrl,
            hintText: 'Ex : Résidence Les Palmiers',
            label: 'Nom de l\'immeuble',
            isRequired: true,
            prefixIcon: Icon(
              LucideIcons.building,
              size: 18,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 20),

          AppDropdown<String>(
            label: 'Type de bien',
            value: widget.form.type,
            items: NouveauImmeubleForm.typesImmeuble
                .map((t) => AppDropdownItem(label: t, value: t))
                .toList(),
            onChanged: (v) => setState(() => widget.form.type = v ?? 'Immeuble'),
          ),
          const SizedBox(height: 20),

          AppTextField(
            controller: _etagesCtrl,
            hintText: '0',
            label: 'Nombre d\'étages',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            helperText: 'Indiquez 0 si le bien est de plain-pied',
          ),
          const SizedBox(height: 20),

          AppTextField(
            controller: _lotsCtrl,
            hintText: 'Ex : 12',
            label: 'Capacité prévue (optionnel)',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            helperText:
                'Nombre de lots que vous prévoyez — n\'en crée aucun '
                'automatiquement, purement informatif tant qu\'ils ne sont '
                'pas ajoutés un par un',
          ),
          const SizedBox(height: 20),

          AppTextField(
            controller: _descCtrl,
            hintText: 'Équipements, atouts, informations complémentaires...',
            label: 'Description',
            maxLines: 4,
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Photos (optionnel)', style: AppTypography.labelField()),
              Text(
                '${widget.form.photoUrls.length}/10',
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
              if (widget.form.photoUrls.length < 10)
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
              ...widget.form.photoUrls.asMap().entries.map((entry) {
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
      ),
    );
  }
}
