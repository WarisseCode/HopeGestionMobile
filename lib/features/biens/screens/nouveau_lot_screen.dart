import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../data/biens_repository.dart';
import '../data/biens_results.dart';
import '../widgets/photos_picker.dart';

/// Formulaire "Nouveau lot" — page unique (pas d'assistant multi-étapes,
/// même choix qu'`EditLocataireScreen`/`NouveauLotScreen` n'a pas besoin du
/// même parcours qu'une création d'immeuble). Toujours rattaché à
/// [buildingId] : un lot ne peut pas exister sans immeuble (voir
/// `bienRoutes.ts`, `POST /lots`).
///
/// Champs volontairement limités à ceux demandés explicitement pour cette
/// phase (référence, type, étage, bloc, superficie, nb pièces, loyer,
/// charges, périodicité, caution, avance, statut) : `prix_vente`/
/// `modalite_vente`/`duree_echelonnement`/`date_disponibilite`/`description`
/// existent côté backend mais restent hors périmètre ici.
class NouveauLotScreen extends StatefulWidget {
  const NouveauLotScreen({
    super.key,
    required this.buildingId,
    required this.immeubleNom,
  });

  final int buildingId;
  final String immeubleNom;

  @override
  State<NouveauLotScreen> createState() => _NouveauLotScreenState();
}

class _NouveauLotScreenState extends State<NouveauLotScreen> {
  static const List<String> _types = [
    'Appartement',
    'Studio',
    'Chambre',
    'Boutique',
    'Bureau',
    'Dépôt',
    'Terrain nu',
  ];

  static const List<String> _periodicites = [
    'mensuel',
    'trimestriel',
    'semestriel',
    'annuel',
  ];

  /// Valeurs réelles observées côté backend (`disponible`/`occupe`/
  /// `reserve`/`vendu`) + `hors_service`, exposée côté web
  /// (`LotForm.tsx`) sans contrainte serveur associée (colonne texte libre,
  /// aucune validation dans `lotRules`).
  static const List<String> _statuts = [
    'disponible',
    'reserve',
    'occupe',
    'vendu',
    'hors_service',
  ];

  final _referenceCtrl = TextEditingController();
  final _etageCtrl = TextEditingController();
  final _blocCtrl = TextEditingController();
  final _superficieCtrl = TextEditingController();
  final _nbPiecesCtrl = TextEditingController();
  final _loyerCtrl = TextEditingController();
  final _chargesCtrl = TextEditingController();
  final _cautionCtrl = TextEditingController();
  final _avanceCtrl = TextEditingController(text: '1');

  String _type = 'Appartement';
  String _periodicite = 'mensuel';
  String _statut = 'disponible';

  bool _loading = false;
  String? _error;

  List<String> _photoUrls = [];

  @override
  void dispose() {
    _referenceCtrl.dispose();
    _etageCtrl.dispose();
    _blocCtrl.dispose();
    _superficieCtrl.dispose();
    _nbPiecesCtrl.dispose();
    _loyerCtrl.dispose();
    _chargesCtrl.dispose();
    _cautionCtrl.dispose();
    _avanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reference = _referenceCtrl.text.trim();
    if (reference.isEmpty) {
      setState(() => _error = 'La référence du lot est obligatoire.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await BiensRepository.instance.createLot(
      buildingId: widget.buildingId,
      reference: reference,
      type: _type,
      etage: _etageCtrl.text.trim(),
      bloc: _blocCtrl.text.trim(),
      superficie: double.tryParse(_superficieCtrl.text),
      nbPieces: int.tryParse(_nbPiecesCtrl.text),
      loyer: double.tryParse(_loyerCtrl.text),
      charges: double.tryParse(_chargesCtrl.text),
      periodicite: _periodicite,
      caution: double.tryParse(_cautionCtrl.text),
      avance: int.tryParse(_avanceCtrl.text) ?? 1,
      statut: _statut,
      photos: _photoUrls.isEmpty ? null : _photoUrls,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    switch (result) {
      case CreateLotSuccess():
        Navigator.of(context).pop(true);
      case CreateLotValidationFailed(message: final message):
        setState(() => _error = message);
      case CreateLotFailure(message: final message):
        // Couvre aussi le 403 de limite d'abonnement (`checkPropertyLimit`)
        // — le message serveur est déjà directement affichable.
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nouveau lot',
                          style: AppTypography.titleScreen(fontSize: 20),
                        ),
                        Text(
                          widget.immeubleNom,
                          style: AppTypography.bodySmall(
                            color: AppColors.mutedForeground,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                children: [
                  AppTextField(
                    label: 'Référence du lot',
                    hintText: 'Ex : Apt. 12',
                    isRequired: true,
                    controller: _referenceCtrl,
                  ),
                  const SizedBox(height: 14),
                  AppDropdown<String>(
                    label: 'Type',
                    value: _type,
                    items: _types
                        .map((t) => AppDropdownItem(label: t, value: t))
                        .toList(),
                    onChanged: (v) => setState(() => _type = v ?? _type),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Étage',
                          hintText: 'Ex : RDC, 1er étage',
                          controller: _etageCtrl,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          label: 'Bloc',
                          hintText: 'Ex : A',
                          controller: _blocCtrl,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Superficie (m²)',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          controller: _superficieCtrl,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          label: 'Nombre de pièces',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          controller: _nbPiecesCtrl,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Loyer mensuel',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          controller: _loyerCtrl,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          label: 'Charges',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          controller: _chargesCtrl,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AppDropdown<String>(
                    label: 'Périodicité du loyer',
                    value: _periodicite,
                    items: _periodicites
                        .map((p) => AppDropdownItem(label: p, value: p))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _periodicite = v ?? _periodicite),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Caution',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          controller: _cautionCtrl,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          label: 'Avance (mois)',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          controller: _avanceCtrl,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AppDropdown<String>(
                    label: 'Statut',
                    value: _statut,
                    items: _statuts
                        .map((s) => AppDropdownItem(label: s, value: s))
                        .toList(),
                    onChanged: (v) => setState(() => _statut = v ?? _statut),
                  ),
                  const SizedBox(height: 20),

                  PhotosPicker(
                    photoUrls: _photoUrls,
                    onChanged: (urls) => setState(() => _photoUrls = urls),
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
                    label: 'Enregistrer le lot',
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
