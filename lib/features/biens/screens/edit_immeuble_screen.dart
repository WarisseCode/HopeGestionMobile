import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../data/biens_repository.dart';
import '../data/biens_results.dart';
import '../models/immeuble.dart';
import '../models/nouveau_immeuble_form.dart';
import '../widgets/photos_picker.dart';

/// Modification d'un immeuble existant. Formulaire sur une page, même choix
/// qu'`EditLocataireScreen` : une édition n'a pas besoin de l'assistant en
/// 3 étapes de la création.
///
/// Pré-remplit tous les champs éditables et renvoie **tels quels** ceux qui
/// ne le sont pas (coordonnées, gestionnaire, vidéo, plan de masse,
/// propriétaire) : `POST /api/biens/immeubles` avec `id` réécrit chaque
/// colonne sans `COALESCE` (voir `BiensRepository.updateImmeuble`).
class EditImmeubleScreen extends StatefulWidget {
  const EditImmeubleScreen({super.key, required this.immeuble});

  final Immeuble immeuble;

  @override
  State<EditImmeubleScreen> createState() => _EditImmeubleScreenState();
}

class _EditImmeubleScreenState extends State<EditImmeubleScreen> {
  /// Valeurs observées côté web (`ImmeubleForm.tsx`), voir [Immeuble.statut].
  static const List<String> _statuts = ['actif', 'inactif'];

  Immeuble get _i => widget.immeuble;

  late final _nomCtrl = TextEditingController(text: _i.nom);
  late final _etagesCtrl = TextEditingController(
    text: _i.nombreEtages?.toString() ?? '',
  );
  late final _capaciteCtrl = TextEditingController(
    text: (_i.totalLotsDeclares ?? 0) > 0 ? '${_i.totalLotsDeclares}' : '',
  );
  late final _descCtrl = TextEditingController(text: _i.description ?? '');
  late final _adresseCtrl = TextEditingController(text: _i.adresse ?? '');
  late final _quartierCtrl = TextEditingController(text: _i.quartier ?? '');
  late final _villeCtrl = TextEditingController(text: _i.ville ?? '');

  late String _type = _i.type ?? NouveauImmeubleForm.typesImmeuble.first;
  late String _pays = _i.pays ?? 'Bénin';
  late String _statut = _i.statut;

  /// `galerie` : photo principale en tête, puis `photos` sans doublon. À
  /// l'enregistrement, la première photo devient la photo principale.
  late List<String> _photos = _i.galerie;

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _etagesCtrl.dispose();
    _capaciteCtrl.dispose();
    _descCtrl.dispose();
    _adresseCtrl.dispose();
    _quartierCtrl.dispose();
    _villeCtrl.dispose();
    super.dispose();
  }

  /// Liste de choix + valeur actuelle si elle n'y figure pas (valeur saisie
  /// côté web hors liste) : ne jamais la perdre à l'enregistrement.
  static List<String> _avecValeurActuelle(List<String> choix, String actuel) =>
      choix.contains(actuel) ? choix : [...choix, actuel];

  static String? _nullSiVide(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _submit() async {
    final nom = _nomCtrl.text.trim();
    final ville = _villeCtrl.text.trim();
    if (nom.isEmpty || ville.isEmpty) {
      setState(() => _error = 'Le nom et la ville sont obligatoires.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await BiensRepository.instance.updateImmeuble(
      id: _i.id,
      nom: nom,
      type: _type,
      adresse: _adresseCtrl.text.trim(),
      ville: ville,
      pays: _pays,
      quartier: _nullSiVide(_quartierCtrl.text),
      description: _nullSiVide(_descCtrl.text),
      nombreEtages: int.tryParse(_etagesCtrl.text),
      totalLots: int.tryParse(_capaciteCtrl.text),
      statut: _statut,
      photos: _photos,
      photo: _photos.isEmpty ? null : _photos.first,
      // Non éditables ici : renvoyés tels quels.
      latitude: _i.latitude,
      longitude: _i.longitude,
      gestionnaireId: _i.gestionnaireId,
      videoUrl: _i.videoUrl,
      planMasseUrl: _i.planMasseUrl,
      ownerId: _i.ownerId,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    switch (result) {
      case UpdateImmeubleSuccess():
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Immeuble mis à jour.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      case UpdateImmeubleValidationFailed(message: final message):
        setState(() => _error = message);
      case UpdateImmeubleFailure(message: final message):
        setState(() => _error = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      LucideIcons.arrow_left,
                      color: AppColors.foreground,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Modifier l\'immeuble',
                      style: AppTypography.titleScreen(fontSize: 20),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  PhotosPicker(
                    label: 'Photos',
                    photoUrls: _photos,
                    onChanged: (urls) => setState(() => _photos = urls),
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: 'Nom de l\'immeuble',
                    isRequired: true,
                    controller: _nomCtrl,
                  ),
                  const SizedBox(height: 14),
                  AppDropdown<String>(
                    label: 'Type de bien',
                    value: _type,
                    items:
                        _avecValeurActuelle(
                              NouveauImmeubleForm.typesImmeuble,
                              _type,
                            )
                            .map((t) => AppDropdownItem(label: t, value: t))
                            .toList(),
                    onChanged: (v) => setState(() => _type = v ?? _type),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Étages',
                          controller: _etagesCtrl,
                          hintText: '0',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          label: 'Capacité prévue',
                          controller: _capaciteCtrl,
                          hintText: 'Ex : 12',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Description',
                    controller: _descCtrl,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Adresse complète',
                    controller: _adresseCtrl,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(label: 'Quartier', controller: _quartierCtrl),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Ville',
                    isRequired: true,
                    controller: _villeCtrl,
                  ),
                  const SizedBox(height: 14),
                  AppDropdown<String>(
                    label: 'Pays',
                    value: _pays,
                    items:
                        _avecValeurActuelle(NouveauImmeubleForm.paysListe, _pays)
                            .map((p) => AppDropdownItem(label: p, value: p))
                            .toList(),
                    onChanged: (v) => setState(() => _pays = v ?? _pays),
                  ),
                  const SizedBox(height: 14),
                  AppDropdown<String>(
                    label: 'Statut',
                    value: _statut,
                    items: _avecValeurActuelle(_statuts, _statut)
                        .map(
                          (s) => AppDropdownItem(
                            label: s == 'actif'
                                ? 'Actif'
                                : s == 'inactif'
                                ? 'Inactif'
                                : s,
                            value: s,
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _statut = v ?? _statut),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _error!,
                      style: AppTypography.bodySmall(color: AppColors.error),
                    ),
                  ],
                  const SizedBox(height: 24),
                  AppButton.primary(
                    label: 'Enregistrer',
                    isLoading: _loading,
                    onPressed: _loading ? null : _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
