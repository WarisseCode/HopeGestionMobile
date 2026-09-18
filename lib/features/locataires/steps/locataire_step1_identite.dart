import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../core/design_system.dart';
import '../models/nouveau_locataire_form.dart';

/// Étape 1 : Identité du locataire / contact.
class LocataireStep1Identite extends StatefulWidget {
  const LocataireStep1Identite({super.key, required this.form});
  final NouveauLocataireForm form;

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
          AppDropdown<String>(
            label: 'Propriétaire de rattachement',
            isRequired: true,
            hintText: 'Sélectionner un propriétaire...',
            value: f.proprietaire.isEmpty ? null : f.proprietaire,
            items: NouveauLocataireForm.proprietaires
                .map((p) => AppDropdownItem(label: p, value: p))
                .toList(),
            onChanged: (v) => setState(() => f.proprietaire = v ?? ''),
          ),
          const SizedBox(height: 20),

          // Zone Avatar / Photo de profil
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.positiveSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          f.initials.isEmpty ? '?' : f.initials,
                          style: AppTypography.titleSection(
                            color: AppColors.primaryStrong,
                          ),
                        ),
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
                        child: const Icon(
                          LucideIcons.camera,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Photo de profil (facultative)',
                  style: AppTypography.kpiNote(
                    color: AppColors.mutedForeground,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
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
}
