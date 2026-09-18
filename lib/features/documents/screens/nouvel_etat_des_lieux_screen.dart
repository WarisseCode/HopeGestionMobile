import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../models/document_item.dart';
import 'document_detail_screen.dart';

/// Formulaire de saisie d'un état des lieux contradictoire
class NouvelEtatDesLieuxScreen extends StatefulWidget {
  const NouvelEtatDesLieuxScreen({super.key});

  @override
  State<NouvelEtatDesLieuxScreen> createState() =>
      _NouvelEtatDesLieuxScreenState();
}

class _NouvelEtatDesLieuxScreenState extends State<NouvelEtatDesLieuxScreen> {
  final _indexEauController = TextEditingController(text: '0482');
  final _indexElecController = TextEditingController(text: '12940');
  final _clesController = TextEditingController(text: '3');
  final _remarquesController = TextEditingController();

  String _type = 'Entrée'; // Entrée ou Sortie
  String _selectedTenant = 'Yacine Diop';
  String _selectedBien = 'Apt. 12 — Mbour · Lot 101';

  final Map<String, String> _roomStatus = {
    'Séjour / Salon': 'Bon état',
    'Cuisine': 'Bon état',
    'Chambres': 'Très bon état',
    'Salle d\'eau': 'Bon état',
  };

  final List<String> _tenants = [
    'Yacine Diop',
    'Fatou Ndiaye',
    'OJO Gael',
    'Jean-Luc Akue',
  ];

  final List<String> _biens = [
    'Apt. 12 — Mbour · Lot 101',
    'Duplex — Almadies · Lot 2B',
    'Local — Plateau · Lot RDC',
    'Villa — Saly · Villa Entière',
  ];

  @override
  void dispose() {
    _indexEauController.dispose();
    _indexElecController.dispose();
    _clesController.dispose();
    _remarquesController.dispose();
    super.dispose();
  }

  void _submit() {
    final doc = DocumentItem(
      id: 'edl-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      title: 'État des lieux d\'$_type · $_selectedTenant',
      property: _selectedBien,
      category: DocumentCategory.contrat,
      status: DocumentStatus.signe,
      date: DateTime.now(),
      size: '2.1 Mo',
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => DocumentDetailScreen(document: doc)),
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
                    'État des lieux',
                    style: AppTypography.titleScreen(fontSize: 22),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  // Type Entrée / Sortie Toggle
                  Row(
                    children: [
                      for (final t in ['Entrée', 'Sortie'])
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: t == 'Entrée' ? 8 : 0,
                            ),
                            child: ChoiceChip(
                              label: Center(
                                child: Text('État des lieux d\'$t'),
                              ),
                              selected: _type == t,
                              onSelected: (_) => setState(() => _type = t),
                              backgroundColor: AppColors.card,
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: _type == t
                                    ? Colors.white
                                    : AppColors.foreground,
                                fontWeight: _type == t
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: _type == t
                                      ? AppColors.primary
                                      : AppColors.border,
                                ),
                              ),
                              showCheckmark: false,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Bien & Locataire
                  Text(
                    'LOGEMENT CONCERNÉ',
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

                  Text(
                    'LOCATAIRE PRÉSENT',
                    style: AppTypography.labelUppercase(
                      color: AppColors.mutedForeground,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AppDropdown<String>(
                    value: _selectedTenant,
                    items: _tenants
                        .map((t) => AppDropdownItem(label: t, value: t))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedTenant = val);
                    },
                  ),
                  const SizedBox(height: 20),

                  // Relevé des compteurs & clés
                  Text(
                    'RELEVÉ DES COMPTEURS & CLÉS',
                    style: AppTypography.labelUppercase(
                      color: AppColors.mutedForeground,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'COMPTEUR EAU (m³)',
                                    style: AppTypography.caption(
                                      color: AppColors.mutedForeground,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  AppTextField(
                                    controller: _indexEauController,
                                    keyboardType: TextInputType.number,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ÉLECTRICITÉ (kWh)',
                                    style: AppTypography.caption(
                                      color: AppColors.mutedForeground,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  AppTextField(
                                    controller: _indexElecController,
                                    keyboardType: TextInputType.number,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.key_round,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Nombre de jeux de clés remis :',
                                style: AppTypography.bodySmall(
                                  color: AppColors.foreground,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 60,
                              child: AppTextField(
                                controller: _clesController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // État par pièce
                  Text(
                    'ÉTAT DES PIÈCES',
                    style: AppTypography.labelUppercase(
                      color: AppColors.mutedForeground,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: _roomStatus.entries.map((entry) {
                        return ListTile(
                          title: Text(
                            entry.key,
                            style: AppTypography.bodyMedium(
                              color: AppColors.foreground,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.positiveSoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              entry.value,
                              style: AppTypography.caption(
                                color: AppColors.primaryStrong,
                              ).copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bouton Enregistrer
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
                      label: Text(
                        'Valider l\'état des lieux d\'$_type',
                        style: const TextStyle(
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
