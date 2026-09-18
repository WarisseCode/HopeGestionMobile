import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../models/document_item.dart';
import 'document_detail_screen.dart';

/// Formulaire de génération rapide d'une quittance de loyer
class NouvelleQuittanceScreen extends StatefulWidget {
  const NouvelleQuittanceScreen({super.key});

  @override
  State<NouvelleQuittanceScreen> createState() =>
      _NouvelleQuittanceScreenState();
}

class _NouvelleQuittanceScreenState extends State<NouvelleQuittanceScreen> {
  final _loyerController = TextEditingController(text: '185000');
  final _chargesController = TextEditingController(text: '15000');

  String _selectedTenant = 'Yacine Diop';
  String _selectedBien = 'Apt. 12 — Mbour · Lot 101';
  String _selectedPeriod = 'Septembre 2026';
  String _selectedPaymentMethod = 'MTN Mobile Money';

  final List<String> _tenants = [
    'Yacine Diop',
    'Fatou Ndiaye',
    'OJO Gael',
    'Jean-Luc Akue',
    'Amadou Traoré',
  ];

  final List<String> _biens = [
    'Apt. 12 — Mbour · Lot 101',
    'Duplex — Almadies · Lot 2B',
    'Local — Plateau · Lot RDC',
    'Villa — Saly · Villa Entière',
  ];

  final List<String> _periods = [
    'Août 2026',
    'Septembre 2026',
    'Octobre 2026',
    'Novembre 2026',
  ];

  final List<String> _paymentMethods = [
    'MTN Mobile Money',
    'Moov Money',
    'Wave',
    'Espèces',
    'Virement bancaire',
    'Chèque',
  ];

  @override
  void dispose() {
    _loyerController.dispose();
    _chargesController.dispose();
    super.dispose();
  }

  void _generate() {
    final loyer = int.tryParse(_loyerController.text.trim()) ?? 0;
    final charges = int.tryParse(_chargesController.text.trim()) ?? 0;
    final total = loyer + charges;

    final doc = DocumentItem(
      id: 'quittance-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      title: 'Quittance $_selectedPeriod',
      property: '$_selectedBien ($_selectedTenant · $total FCFA)',
      category: DocumentCategory.quittance,
      status: DocumentStatus.genere,
      date: DateTime.now(),
      size: '155 Ko',
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
                    'Générer une quittance',
                    style: AppTypography.titleScreen(fontSize: 22),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.positiveSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.receipt,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'La quittance certifie le paiement effectif du loyer et des charges pour la période sélectionnée.',
                            style: AppTypography.caption(
                              color: AppColors.foreground,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Locataire
                  Text(
                    'LOCATAIRE',
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
                  const SizedBox(height: 16),

                  // Bien concerné
                  Text(
                    'BIEN & LOT ASSOCIÉ',
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

                  // Période
                  Text(
                    'MOIS DE LOYER',
                    style: AppTypography.labelUppercase(
                      color: AppColors.mutedForeground,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AppDropdown<String>(
                    value: _selectedPeriod,
                    items: _periods
                        .map((p) => AppDropdownItem(label: p, value: p))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedPeriod = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Montants (Row)
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LOYER NU (FCFA)',
                              style: AppTypography.labelUppercase(
                                color: AppColors.mutedForeground,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 6),
                            AppTextField(
                              controller: _loyerController,
                              keyboardType: TextInputType.number,
                              hintText: '185000',
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
                              'CHARGES (FCFA)',
                              style: AppTypography.labelUppercase(
                                color: AppColors.mutedForeground,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 6),
                            AppTextField(
                              controller: _chargesController,
                              keyboardType: TextInputType.number,
                              hintText: '15000',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Mode de paiement
                  Text(
                    'MODE DE PAIEMENT CONSTATÉ',
                    style: AppTypography.labelUppercase(
                      color: AppColors.mutedForeground,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AppDropdown<String>(
                    value: _selectedPaymentMethod,
                    items: _paymentMethods
                        .map((m) => AppDropdownItem(label: m, value: m))
                        .toList(),
                    onChanged: (val) {
                      if (val != null)
                        setState(() => _selectedPaymentMethod = val);
                    },
                  ),
                  const SizedBox(height: 28),

                  // Bouton Générer
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _generate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      icon: const Icon(
                        LucideIcons.file_text,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Éditer & Voir la quittance',
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
