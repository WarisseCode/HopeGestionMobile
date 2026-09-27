import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../core/design_system.dart';
import '../models/nouveau_locataire_form.dart';
import '../models/owner.dart';
import '../widgets/avatar_picker.dart';

/// Étape 1 : Identité du locataire / contact.
class LocataireStep1Identite extends StatefulWidget {
  const LocataireStep1Identite({
    super.key,
    required this.form,
    required this.owners,
    required this.ownersLoading,
    required this.ownersError,
    required this.onRetryOwners,
  });

  final NouveauLocataireForm form;

  /// Propriétaires réellement gérés par l'utilisateur connecté (`GET
  /// /owners`), chargés une fois par `NouveauLocataireScreen`.
  final List<Owner> owners;
  final bool ownersLoading;
  final String? ownersError;
  final VoidCallback onRetryOwners;

  @override
  State<LocataireStep1Identite> createState() => _LocataireStep1IdentiteState();
}

class _LocataireStep1IdentiteState extends State<LocataireStep1Identite> {
  late final TextEditingController _nomController;
  late final TextEditingController _prenomController;
  late final TextEditingController _nationaliteController;
  late final TextEditingController _telephoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _adresseController;

  @override
  void initState() {
    super.initState();
    final f = widget.form;
    _nomController = TextEditingController(text: f.nom);
    _prenomController = TextEditingController(text: f.prenom);
    _nationaliteController = TextEditingController(text: f.nationalite);
    _telephoneController = TextEditingController(text: f.telephone);
    _emailController = TextEditingController(text: f.email);
    _adresseController = TextEditingController(text: f.adresse);
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _nationaliteController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _adresseController.dispose();
    super.dispose();
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
            'ÉTAPE 1',
            style: AppTypography.labelUppercase(
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 4),
          Text('Identité du profil', style: AppTypography.titleScreen()),
          const SizedBox(height: 8),
          Text(
            'Renseignez les informations d\'état civil et coordonnées.',
            style: AppTypography.bodySmall(color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 24),

          // Propriétaire de rattachement
          _buildOwnerField(f),
          const SizedBox(height: 20),

          // Zone Avatar / Photo de profil
          AvatarPicker(
            initials: f.initials,
            photoUrl: f.photoProfilUrl,
            onChanged: (url) => setState(() => f.photoProfilUrl = url),
          ),
          const SizedBox(height: 20),

          // Nom & Prénom
          AppTextField(
            label: 'Nom',
            isRequired: true,
            hintText: 'Ex: KOUASSI',
            prefixIcon: Icon(
              LucideIcons.user,
              size: 18,
              color: AppColors.mutedForeground,
            ),
            controller: _nomController,
            textCapitalization: TextCapitalization.characters,
            onChanged: (v) {
              setState(() => f.nom = v);
            },
          ),
          const SizedBox(height: 16),

          AppTextField(
            label: 'Prénom',
            isRequired: true,
            hintText: 'Ex: Jean-Marc',
            prefixIcon: Icon(
              LucideIcons.user,
              size: 18,
              color: AppColors.mutedForeground,
            ),
            controller: _prenomController,
            textCapitalization: TextCapitalization.words,
            onChanged: (v) {
              setState(() => f.prenom = v);
            },
          ),
          const SizedBox(height: 20),

          // Type de profil (Locataire / Acheteur / Prospect)
          Text('Type de profil', style: AppTypography.labelField()),
          const SizedBox(height: 8),
          AppToggleChipGroup<String>(
            options: const [
              AppToggleChipOption(label: 'Locataire', value: 'Locataire'),
              AppToggleChipOption(label: 'Acheteur', value: 'Acheteur'),
              AppToggleChipOption(label: 'Prospect', value: 'Prospect'),
            ],
            selectedValue: f.typeProfile,
            onChanged: (val) {
              setState(() => f.typeProfile = val);
            },
          ),
          const SizedBox(height: 20),

          // Nationalité
          AppTextField(
            label: 'Nationalité',
            hintText: 'Ex: Béninoise, Sénégalaise...',
            prefixIcon: Icon(
              LucideIcons.globe,
              size: 18,
              color: AppColors.mutedForeground,
            ),
            controller: _nationaliteController,
            onChanged: (v) => f.nationalite = v,
          ),
          const SizedBox(height: 16),

          // Téléphone
          AppTextField(
            label: 'Numéro de téléphone',
            isRequired: true,
            hintText: 'Ex: +229 97 00 00 00',
            prefixIcon: Icon(
              LucideIcons.phone,
              size: 18,
              color: AppColors.mutedForeground,
            ),
            keyboardType: TextInputType.phone,
            controller: _telephoneController,
            onChanged: (v) => f.telephone = v,
          ),
          const SizedBox(height: 16),

          // Email
          AppTextField(
            label: 'Adresse email',
            hintText: 'Ex: contact@email.com',
            prefixIcon: Icon(
              LucideIcons.mail,
              size: 18,
              color: AppColors.mutedForeground,
            ),
            keyboardType: TextInputType.emailAddress,
            controller: _emailController,
            onChanged: (v) => f.email = v,
          ),
          const SizedBox(height: 16),

          // Adresse
          AppTextField(
            label: 'Adresse de résidence actuelle',
            hintText: 'Ex: Rue 244, Cotonou',
            prefixIcon: Icon(
              LucideIcons.map_pin,
              size: 18,
              color: AppColors.mutedForeground,
            ),
            controller: _adresseController,
            onChanged: (v) => f.adresse = v,
          ),
        ],
      ),
    );
  }

  /// Sélecteur réel, alimenté par `GET /owners` (propriétaires gérés par
  /// l'utilisateur connecté) — voir `NouveauLocataireScreen`. Trois cas
  /// réels observés côté backend (`tenantGuard.ts`) : aucun propriétaire lié
  /// (rien à sélectionner, `owner_id` omis), un seul (résolu automatiquement
  /// côté serveur, pas de choix à faire), plusieurs (sélection obligatoire).
  Widget _buildOwnerField(NouveauLocataireForm f) {
    if (widget.ownersLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (widget.ownersError != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.warningSoft,
          borderRadius: AppRadius.borderMd,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Propriétaires : ${widget.ownersError}',
                style: AppTypography.bodySmall(color: AppColors.warning),
              ),
            ),
            TextButton(
              onPressed: widget.onRetryOwners,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (widget.owners.isEmpty) {
      // Aucun propriétaire lié à l'utilisateur ("mode gestionnaire pur",
      // voir tenantGuard.ts) : owner_id sera omis à la création, rien à
      // sélectionner.
      return const SizedBox.shrink();
    }

    if (widget.owners.length == 1) {
      final only = widget.owners.first;
      return Row(
        children: [
          Icon(LucideIcons.building, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Propriétaire : ${only.displayName}',
              style: AppTypography.bodySmall(color: AppColors.foreground),
            ),
          ),
        ],
      );
    }

    return AppDropdown<int>(
      label: 'Propriétaire de rattachement',
      isRequired: true,
      hintText: 'Sélectionner un propriétaire...',
      value: f.ownerId,
      items: widget.owners
          .map((o) => AppDropdownItem(label: o.displayName, value: o.id))
          .toList(),
      onChanged: (v) => setState(() {
        f.ownerId = v;
        f.ownerName =
            widget.owners.firstWhere((o) => o.id == v).displayName;
      }),
    );
  }
}
