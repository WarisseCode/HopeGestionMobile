import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../models/document_item.dart';
import 'document_detail_screen.dart';

/// Formulaire d'établissement d'un contrat de bail de location
class NouveauContratScreen extends StatefulWidget {
  const NouveauContratScreen({super.key});

  @override
  State<NouveauContratScreen> createState() => _NouveauContratScreenState();
}

class _NouveauContratScreenState extends State<NouveauContratScreen> {
  final _loyerController = TextEditingController(text: '250000');
  final _cautionController = TextEditingController(text: '500000');
  final _avanceController = TextEditingController(text: '2'); // mois

  String _selectedOwner = 'Mamadou Camara';
  String _selectedTenant = 'Yacine Diop';
  String _selectedBien = 'Duplex — Almadies · Lot 2B';
  String _selectedTypeBail = 'Bail d\'habitation (Usage résidentiel)';
  String _selectedDuree = '1 an (Renouvelable par tacite reconduction)';

  final List<String> _owners = [
    'Mamadou Camara',
    'Aïcha Sarr',
    'Cabinet Hope Gestion (Mandataire)',
  ];

  final List<String> _tenants = [
    'Yacine Diop',
    'Fatou Ndiaye',
    'OJO Gael',
    'Jean-Luc Akue',
    'Amadou Traoré',
  ];

  final List<String> _biens = [
    'Duplex — Almadies · Lot 2B',
    'Apt. 12 — Mbour · Lot 101',
    'Local — Plateau · Lot RDC',
    'Villa — Saly · Villa Entière',
  ];

  final List<String> _typesBail = [
    'Bail d\'habitation (Usage résidentiel)',
    'Bail meublé courte durée',
    'Bail commercial / Professionnel',
  ];

  final List<String> _durees = [
    '1 an (Renouvelable par tacite reconduction)',
    '2 ans fermes',
    '3 ans (Bail commercial standard)',
  ];

  @override
  void dispose() {
    _loyerController.dispose();
    _cautionController.dispose();
    _avanceController.dispose();
    super.dispose();
  }

  void _submit() {
    final doc = DocumentItem(
      id: 'contrat-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      title: 'Contrat de location · $_selectedTenant',
      property: _selectedBien,
      category: DocumentCategory.contrat,
      status: DocumentStatus.signe,
      date: DateTime.now(),
      size: '1.8 Mo',
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
                    'Nouveau contrat de bail',
                    style: AppTypography.titleScreen(fontSize: 22),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  // Type de bail
                  Text(
                    'TYPE DE CONTRAT',
                    style: AppTypography.labelUppercase(
                      color: AppColors.mutedForeground,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AppDropdown<String>(
                    value: _selectedTypeBail,
                    items: _typesBail
                        .map((t) => AppDropdownItem(label: t, value: t))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedTypeBail = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Parties prenantes
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BAILLEUR / PROPRIÉTAIRE',
                              style: AppTypography.labelUppercase(
                                color: AppColors.mutedForeground,
                                fontSize: 10.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            AppDropdown<String>(
                              value: _selectedOwner,
                              items: _owners
                                  .map(
                                    (o) => AppDropdownItem(label: o, value: o),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null)
                                  setState(() => _selectedOwner = val);
                              },
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
                              'LOCATAIRE PRENEUR',
                              style: AppTypography.labelUppercase(
                                color: AppColors.mutedForeground,
                                fontSize: 10.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            AppDropdown<String>(
                              value: _selectedTenant,
                              items: _tenants
                                  .map(
                                    (t) => AppDropdownItem(label: t, value: t),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null)
                                  setState(() => _selectedTenant = val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bien & Lot
                  Text(
                    'LOGEMENT OU LOCAL OBJET DU BAIL',
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

                  // Conditions financières
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LOYER MENSUEL (FCFA)',
                              style: AppTypography.labelUppercase(
                                color: AppColors.mutedForeground,
                                fontSize: 10.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            AppTextField(
                              controller: _loyerController,
                              keyboardType: TextInputType.number,
                              hintText: '250000',
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
                              'CAUTION / DÉPÔT (FCFA)',
                              style: AppTypography.labelUppercase(
                                color: AppColors.mutedForeground,
                                fontSize: 10.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            AppTextField(
                              controller: _cautionController,
                              keyboardType: TextInputType.number,
                              hintText: '500000',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Durée
                  Text(
                    'DURÉE DU BAIL',
                    style: AppTypography.labelUppercase(
                      color: AppColors.mutedForeground,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AppDropdown<String>(
                    value: _selectedDuree,
                    items: _durees
                        .map((d) => AppDropdownItem(label: d, value: d))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedDuree = val);
                    },
                  ),
                  const SizedBox(height: 28),

                  // Bouton Créer
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
                        LucideIcons.file_pen,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Établir le contrat officiel',
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
