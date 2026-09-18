import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../../documents/screens/document_detail_screen.dart';
import '../../documents/models/document_item.dart';

/// Formulaire d'enregistrement d'un encaissement de loyer
class EncaisserScreen extends StatefulWidget {
  final String? initialTenant;
  final String? initialBien;
  final String? initialMontant;

  const EncaisserScreen({
    super.key,
    this.initialTenant,
    this.initialBien,
    this.initialMontant,
  });

  @override
  State<EncaisserScreen> createState() => _EncaisserScreenState();
}

class _EncaisserScreenState extends State<EncaisserScreen> {
  late final TextEditingController _montantController;
  late final TextEditingController _refController;
  late final TextEditingController _notesController;

  String _selectedTenant = 'Yacine Diop';
  String _selectedBien = 'Apt. 12 — Mbour · Lot 101';
  String _selectedPeriod = 'Septembre 2026';
  String _selectedPaymentMethod = 'MTN MoMo';
  bool _generateReceipt = true;

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
    'Studio — Dakar Plateau · Studio 4',
  ];

  final List<String> _periods = [
    'Août 2026',
    'Septembre 2026',
    'Octobre 2026',
    'Novembre 2026',
  ];

  final List<Map<String, dynamic>> _paymentMethods = [
    {'name': 'Espèces', 'icon': LucideIcons.banknote},
    {'name': 'MTN MoMo', 'icon': LucideIcons.smartphone},
    {'name': 'Moov Money', 'icon': LucideIcons.smartphone_charging},
    {'name': 'Wave', 'icon': LucideIcons.zap},
    {'name': 'Virement', 'icon': LucideIcons.landmark},
    {'name': 'Chèque', 'icon': LucideIcons.file_text},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialTenant != null &&
        _tenants.contains(widget.initialTenant)) {
      _selectedTenant = widget.initialTenant!;
    }
    if (widget.initialBien != null) {
      _selectedBien = widget.initialBien!;
    }
    _montantController = TextEditingController(
      text: widget.initialMontant ?? '185000',
    );
    _refController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _montantController.dispose();
    _refController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    final montant = _montantController.text.trim();
    if (montant.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez renseigner le montant perçu'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Affiche la confirmation d'encaissement
    showModalBottomSheet(
      context: context,
      isDismissible: false,
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
                color: AppColors.positiveSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.circle_check,
                color: AppColors.positive,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Encaissement Enregistré !',
              style: AppTypography.titleScreen(fontSize: 20),
            ),
            const SizedBox(height: 6),
            Text(
              'Montant de $montant FCFA reçu de $_selectedTenant par $_selectedPaymentMethod pour $_selectedPeriod.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall(color: AppColors.mutedForeground),
            ),
            const SizedBox(height: 24),
            if (_generateReceipt) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // ferme modal
                    Navigator.pop(context); // ferme ecran encaissement
                    // Ouvre directement l'aperçu de quittance
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DocumentDetailScreen(
                          document: DocumentItem(
                            id: 'doc-auto',
                            title: 'Quittance $_selectedPeriod',
                            property: '$_selectedBien · $_selectedTenant',
                            category: DocumentCategory.quittance,
                            status: DocumentStatus.genere,
                            date: DateTime.now(),
                            size: '185 Ko',
                          ),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  icon: const Icon(
                    LucideIcons.file_text,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Voir et partager la quittance',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context); // ferme modal
                  Navigator.pop(context); // ferme ecran encaissement
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.foreground,
                  side: BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: const Text('Terminer'),
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
                    'Encaisser un loyer',
                    style: AppTypography.titleScreen(fontSize: 22),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  // Bannière info
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
                          LucideIcons.info,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'L\'enregistrement d\'un encaissement met à jour le solde et génère automatiquement la quittance.',
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
                    'LOCATAIRE PAYEUR',
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

                  // Bien & Lot
                  Text(
                    'BIEN CONCERNÉ',
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

                  // Période & Montant (Row)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PÉRIODE',
                              style: AppTypography.labelUppercase(
                                color: AppColors.mutedForeground,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 6),
                            AppDropdown<String>(
                              value: _selectedPeriod,
                              items: _periods
                                  .map(
                                    (p) => AppDropdownItem(label: p, value: p),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null)
                                  setState(() => _selectedPeriod = val);
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
                              'MONTANT (FCFA)',
                              style: AppTypography.labelUppercase(
                                color: AppColors.mutedForeground,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 6),
                            AppTextField(
                              controller: _montantController,
                              keyboardType: TextInputType.number,
                              hintText: '185000',
                              prefixIcon: Icon(
                                LucideIcons.coins,
                                size: 16,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Mode de paiement
                  Text(
                    'MODE DE RÈGLEMENT',
                    style: AppTypography.labelUppercase(
                      color: AppColors.mutedForeground,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _paymentMethods.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.6,
                        ),
                    itemBuilder: (context, index) {
                      final item = _paymentMethods[index];
                      final isSelected = _selectedPaymentMethod == item['name'];
                      return GestureDetector(
                        onTap: () => setState(
                          () => _selectedPaymentMethod = item['name'],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                            boxShadow: AppShadows.soft,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                item['icon'] as IconData,
                                size: 18,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.foreground,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['name'] as String,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.foreground,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 18),

                  // Référence de paiement
                  Text(
                    'RÉFÉRENCE / TRANSACTION ID (FACULTATIF)',
                    style: AppTypography.labelUppercase(
                      color: AppColors.mutedForeground,
                      fontSize: 10.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AppTextField(
                    controller: _refController,
                    hintText: 'Ex: TRX-2026-987410 / N° Chèque',
                    prefixIcon: Icon(
                      LucideIcons.hash,
                      size: 16,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Switch Quittance immédiate
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.receipt,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Générer la quittance',
                                  style: AppTypography.bodyMedium(
                                    color: AppColors.foreground,
                                  ).copyWith(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'PDF prêt pour remise au locataire',
                                  style: AppTypography.caption(
                                    color: AppColors.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Switch.adaptive(
                          value: _generateReceipt,
                          onChanged: (val) =>
                              setState(() => _generateReceipt = val),
                          activeThumbColor: Colors.white,
                          activeTrackColor: AppColors.primary,
                        ),
                      ],
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
                      label: const Text(
                        'Valider l\'encaissement',
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
