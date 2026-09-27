import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../data/locataire_results.dart';
import '../data/locataires_repository.dart';
import '../models/locataire.dart';
import '../widgets/avatar_picker.dart';

/// Modification d'un locataire existant. Contrairement au formulaire de
/// création (assistant en 4 étapes), un formulaire simple sur une page —
/// même choix que `EditProfileScreen` pour le module Profil (phase 4.1) :
/// une édition n'a pas besoin du même parcours qu'une première saisie.
///
/// Pré-remplit TOUS les champs éditables : `PUT /api/locataires/:id` réécrit
/// chaque colonne sans `COALESCE` (voir `LocatairesRepository.update`), donc
/// omettre un champ l'effacerait plutôt que de le laisser inchangé.
class EditLocataireScreen extends StatefulWidget {
  const EditLocataireScreen({super.key, required this.locataire});

  final Locataire locataire;

  @override
  State<EditLocataireScreen> createState() => _EditLocataireScreenState();
}

class _EditLocataireScreenState extends State<EditLocataireScreen> {
  static const List<String> _statuts = ['Actif', 'Rejeté', 'Archivé'];

  late final _nomCtrl = TextEditingController(text: widget.locataire.nom);
  late final _prenomsCtrl = TextEditingController(
    text: widget.locataire.prenoms,
  );
  late final _emailCtrl = TextEditingController(
    text: widget.locataire.email ?? '',
  );
  late final _telephoneCtrl = TextEditingController(
    text: widget.locataire.telephonePrincipal,
  );
  late final _telephoneSecondaireCtrl = TextEditingController(
    text: widget.locataire.telephoneSecondaire ?? '',
  );
  late final _nationaliteCtrl = TextEditingController(
    text: widget.locataire.nationalite ?? '',
  );
  late final _numeroPieceCtrl = TextEditingController(
    text: widget.locataire.numeroPiece ?? '',
  );
  late final _adresseCtrl = TextEditingController(
    text: widget.locataire.adresseActuelle ?? '',
  );

  late String _type = widget.locataire.type;
  late String _statut = widget.locataire.statut;
  late bool _paiementEchelonne = widget.locataire.paiementEchelonne;
  late String? _photoProfilUrl = widget.locataire.photoProfilUrl;

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomsCtrl.dispose();
    _emailCtrl.dispose();
    _telephoneCtrl.dispose();
    _telephoneSecondaireCtrl.dispose();
    _nationaliteCtrl.dispose();
    _numeroPieceCtrl.dispose();
    _adresseCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final nom = _nomCtrl.text.trim();
    final prenoms = _prenomsCtrl.text.trim();
    final telephone = _telephoneCtrl.text.trim();
    if (nom.isEmpty || prenoms.isEmpty || telephone.isEmpty) {
      setState(() => _error = 'Nom, prénoms et téléphone sont obligatoires.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await LocatairesRepository.instance.update(
      id: widget.locataire.id,
      nom: nom,
      prenoms: prenoms,
      telephonePrincipal: telephone,
      type: _type,
      statut: _statut,
      paiementEchelonne: _paiementEchelonne,
      email: _emailCtrl.text.trim(),
      telephoneSecondaire: _telephoneSecondaireCtrl.text.trim(),
      nationalite: _nationaliteCtrl.text.trim(),
      typePiece: widget.locataire.typePiece,
      numeroPiece: _numeroPieceCtrl.text.trim(),
      dateExpirationPiece: widget.locataire.dateExpirationPiece,
      modePaiementPreferentiel: widget.locataire.modePaiementPreferentiel,
      adresseActuelle: _adresseCtrl.text.trim(),
      photoProfilUrl: _photoProfilUrl,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    switch (result) {
      case UpdateLocataireSuccess():
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Locataire mis à jour.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      case UpdateLocataireValidationFailed(message: final message):
        setState(() => _error = message);
      case UpdateLocataireFailure(message: final message):
        setState(() => _error = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statutItems = _statuts.contains(_statut)
        ? _statuts
        : [..._statuts, _statut];

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
                  Text(
                    'Modifier le locataire',
                    style: AppTypography.titleScreen(fontSize: 20),
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
                  AvatarPicker(
                    initials: widget.locataire.initials,
                    photoUrl: _photoProfilUrl,
                    onChanged: (url) => setState(() => _photoProfilUrl = url),
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: 'Nom',
                    isRequired: true,
                    controller: _nomCtrl,
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Prénoms',
                    isRequired: true,
                    controller: _prenomsCtrl,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Téléphone principal',
                    isRequired: true,
                    controller: _telephoneCtrl,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Téléphone secondaire',
                    controller: _telephoneSecondaireCtrl,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Adresse e-mail',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Nationalité',
                    controller: _nationaliteCtrl,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Adresse de résidence',
                    controller: _adresseCtrl,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Numéro de pièce d\'identité',
                    controller: _numeroPieceCtrl,
                  ),
                  const SizedBox(height: 14),
                  AppDropdown<String>(
                    label: 'Type de profil',
                    value: _type,
                    items: const [
                      AppDropdownItem(label: 'Locataire', value: 'Locataire'),
                      AppDropdownItem(label: 'Acheteur', value: 'Acheteur'),
                      AppDropdownItem(label: 'Prospect', value: 'Prospect'),
                    ],
                    onChanged: (v) => setState(() => _type = v ?? _type),
                  ),
                  const SizedBox(height: 14),
                  AppDropdown<String>(
                    label: 'Statut',
                    value: _statut,
                    items: statutItems
                        .map((s) => AppDropdownItem(label: s, value: s))
                        .toList(),
                    onChanged: (v) => setState(() => _statut = v ?? _statut),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Paiement échelonné autorisé',
                          style: AppTypography.body(),
                        ),
                      ),
                      Switch.adaptive(
                        value: _paiementEchelonne,
                        activeTrackColor: AppColors.primary,
                        onChanged: (v) =>
                            setState(() => _paiementEchelonne = v),
                      ),
                    ],
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
