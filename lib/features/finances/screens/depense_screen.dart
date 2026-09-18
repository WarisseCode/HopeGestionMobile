import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';

/// Formulaire d'enregistrement d'une dépense / charge immobilière
class DepenseScreen extends StatefulWidget {
  final String? initialBien;

  const DepenseScreen({super.key, this.initialBien});

  @override
  State<DepenseScreen> createState() => _DepenseScreenState();
}

class _DepenseScreenState extends State<DepenseScreen> {
  final _titleController = TextEditingController();
  final _montantController = TextEditingController();
  final _beneficiaireController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCategory = 'Travaux & Réparations';
  String _selectedBien = 'Apt. 12 — Mbour';
  bool _hasInvoicePhoto = false;

  final List<String> _categories = [
    'Travaux & Réparations',
    'Entretien & Nettoyage',
    'Charges & Gardiennage',
    'Taxes & Impôts',
    'Assurance',
    'Autre',
  ];

  final List<String> _biens = [
    'Apt. 12 — Mbour',
    'Duplex — Almadies',
    'Local — Plateau',
    'Villa — Saly',
    'Studio — Dakar Plateau',
    'Dépense générale cabinet',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialBien != null && _biens.contains(widget.initialBien)) {
      _selectedBien = widget.initialBien!;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _montantController.dispose();
    _beneficiaireController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    final montant = _montantController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez renseigner le motif de la dépense'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (montant.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez renseigner le montant de la dépense'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.arrow_up_right,
                color: AppColors.warning,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Dépense Enregistrée !',
              style: AppTypography.titleScreen(fontSize: 20),
            ),
            const SizedBox(height: 6),
            Text(
              'Montant de $montant FCFA imputé à $_selectedBien pour « $title ».',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall(color: AppColors.mutedForeground),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // ferme modal
                  Navigator.pop(context); // ferme ecran depense
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Retour aux finances',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
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
                    'Enregistrer une dépense',
                    style: AppTypography.titleScreen(fontSize: 22),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  // Catégorie
                  Text(
                    'CATÉGORIE DE DÉPENSE',
                    style: AppTypography.labelUppercase(
                      color: AppColors.mutedForeground,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (_) =>
                            setState(() => _selectedCategory = cat),
                        backgroundColor: AppColors.card,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.foreground,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 12.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        showCheckmark: false,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Motif
                  Text(
                    'MOTIF / INTITULÉ',
                    style: AppTypography.labelUppercase(
                      color: AppColors.mutedForeground,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AppTextField(
                    controller: _titleController,
                    hintText: 'Ex: Remplacement chauffe-eau / Gardiennage Mars',
                    prefixIcon: Icon(
                      LucideIcons.file_pen,
                      size: 16,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bien concerné
                  Text(
                    'BIEN OU IMMEUBLE CONCERNÉ',
                    style: AppTypography.labelUppercase(
                      color: AppColors.mutedForeground,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AppDropdown<String>(
                    value: _selectedBien,
                    items: _biens
                        .map((b) => AppDropdownItem(label: b, value: b))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedBien = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Montant
                  Text(
                    'MONTANT DE LA DÉPENSE (FCFA)',
                    style: AppTypography.labelUppercase(
                      color: AppColors.mutedForeground,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AppTextField(
                    controller: _montantController,
                    keyboardType: TextInputType.number,
                    hintText: '45000',
                    prefixIcon: Icon(
                      LucideIcons.coins,
                      size: 16,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bénéficiaire
                  Text(
                    'BÉNÉFICIAIRE / PRESTATAIRE / ARTISAN',
                    style: AppTypography.labelUppercase(
                      color: AppColors.mutedForeground,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AppTextField(
                    controller: _beneficiaireController,
                    hintText: 'Ex: ETS Plomberie Moderne / M. Diallo',
                    prefixIcon: Icon(
                      LucideIcons.user,
                      size: 16,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Justificatif / Facture photo
                  Text(
                    'JUSTIFICATIF OU FACTURE PHOTO',
                    style: AppTypography.labelUppercase(
                      color: AppColors.mutedForeground,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() => _hasInvoicePhoto = !_hasInvoicePhoto);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _hasInvoicePhoto
                                ? 'Facture photo ajoutée avec succès'
                                : 'Facture photo supprimée',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: _hasInvoicePhoto
                            ? AppColors.positiveSoft
                            : AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _hasInvoicePhoto
                              ? AppColors.primary
                              : AppColors.border,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _hasInvoicePhoto
                                  ? LucideIcons.circle_check
                                  : LucideIcons.camera,
                              color: _hasInvoicePhoto
                                  ? AppColors.positive
                                  : AppColors.mutedForeground,
                              size: 26,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _hasInvoicePhoto
                                  ? 'Facture jointe (justificatif_01.jpg)'
                                  : 'Prendre une photo ou importer un reçu',
                              style: AppTypography.bodySmall(
                                color: _hasInvoicePhoto
                                    ? AppColors.primary
                                    : AppColors.mutedForeground,
                              ).copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notes complémentaires
                  Text(
                    'NOTES OU COMMENTAIRES',
                    style: AppTypography.labelUppercase(
                      color: AppColors.mutedForeground,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AppTextField(
                    controller: _notesController,
                    hintText:
                        'Détails des travaux ou conditions de paiement...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 28),

                  // Bouton validation
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      icon: const Icon(
                        LucideIcons.circle_check,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Enregistrer la dépense',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
