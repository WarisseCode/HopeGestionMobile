import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../core/design_system.dart';
import '../models/nouveau_bien_form.dart';

/// Étape 4 : Médias & Compléments (photos, vidéo, plan de masse, état).
class BienStep4Medias extends StatefulWidget {
  const BienStep4Medias({super.key, required this.form});
  final NouveauBienForm form;

  @override
  State<BienStep4Medias> createState() => _BienStep4MediasState();
}

class _BienStep4MediasState extends State<BienStep4Medias> {
  final List<String> _dummyPhotos = [];
  late final TextEditingController _videoController;
  late final TextEditingController _planController;

  @override
  void initState() {
    super.initState();
    _videoController = TextEditingController(text: widget.form.videoUrl);
    _planController = TextEditingController(text: widget.form.planUrl);
  }

  @override
  void dispose() {
    _videoController.dispose();
    _planController.dispose();
    super.dispose();
  }

  void _addMockPhoto() {
    if (_dummyPhotos.length < 10) {
      setState(() {
        _dummyPhotos.add('photo_${_dummyPhotos.length + 1}.jpg');
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Photo ${_dummyPhotos.length}/10 ajoutée (simulation)'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _dummyPhotos.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.form;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ÉTAPE 4',
            style: AppTypography.labelUppercase(
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 4),
          Text('Médias & Compléments', style: AppTypography.titleScreen()),
          const SizedBox(height: 8),
          Text(
            'Les photos et documents complémentaires sont facultatifs.',
            style: AppTypography.bodySmall(color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 24),

          // En-tête photos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Photos du bien', style: AppTypography.labelField()),
              Text(
                '${_dummyPhotos.length}/10',
                style: AppTypography.bodySmall(
                  color: AppColors.mutedForeground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Grille photos
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // Bouton d'ajout
              InkWell(
                onTap: _addMockPhoto,
                borderRadius: AppRadius.borderMd,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: AppRadius.borderMd,
                    border: Border.all(
                      color: AppColors.border,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.camera,
                        size: 24,
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

              // Mock photos affichées
              ...List.generate(_dummyPhotos.length, (index) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.positiveSoft,
                        borderRadius: AppRadius.borderMd,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.image,
                            size: 28,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Photo ${index + 1}',
                            style: AppTypography.kpiNote(fontSize: 10),
                          ),
                        ],
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
          const SizedBox(height: 28),

          // Compléments URLs
          AppTextField(
            label: 'URL Vidéo de visite (optionnel)',
            hintText: 'https://youtube.com/... ou lien Drive',
            prefixIcon: Icon(
              LucideIcons.video,
              size: 18,
              color: AppColors.mutedForeground,
            ),
            controller: _videoController,
            onChanged: (v) => f.videoUrl = v,
          ),
          const SizedBox(height: 20),

          AppTextField(
            label: 'URL Plan de masse / architecte (optionnel)',
            hintText: 'https://... lien vers le document PDF',
            prefixIcon: Icon(
              LucideIcons.file_text,
              size: 18,
              color: AppColors.mutedForeground,
            ),
            controller: _planController,
            onChanged: (v) => f.planUrl = v,
          ),
          const SizedBox(height: 20),

          // État du bien
          AppDropdown<String>(
            label: 'État du bien',
            value: f.etat,
            items: NouveauBienForm.etats
                .map((e) => AppDropdownItem(label: e, value: e))
                .toList(),
            onChanged: (v) => setState(() => f.etat = v ?? f.etat),
          ),
          const SizedBox(height: 16),

          const AppInfoBanner(
            text: 'Vous pourrez ajouter d\'autres documents, contrats ou diagnostics ultérieurement dans la fiche détaillée du bien.',
          ),
        ],
      ),
    );
  }
}
