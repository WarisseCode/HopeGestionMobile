import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../models/transaction.dart';
import '../../documents/screens/document_detail_screen.dart';
import '../../documents/models/document_item.dart';

/// Fiche détaillée d'une transaction financière
class TransactionDetailScreen extends StatelessWidget {
  final FinanceTransaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.isIncome;
    final formattedDate =
        '${transaction.date.day.toString().padLeft(2, '0')}/${transaction.date.month.toString().padLeft(2, '0')}/${transaction.date.year}';

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
                  Expanded(
                    child: Text(
                      'Détail de l\'opération',
                      style: AppTypography.titleScreen(fontSize: 20),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Reçu d\'opération partagé'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: Icon(
                      LucideIcons.share_2,
                      size: 20,
                      color: AppColors.foreground,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  // Carte Montant & Statut
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppShadows.soft,
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: isIncome
                                ? AppColors.positiveSoft
                                : AppColors.warning.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isIncome
                                ? LucideIcons.arrow_down_left
                                : LucideIcons.arrow_up_right,
                            color: isIncome
                                ? AppColors.positive
                                : AppColors.warning,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          transaction.formattedAmount,
                          style: AppTypography.titleScreen(
                            fontSize: 28,
                            color: isIncome
                                ? AppColors.positive
                                : AppColors.foreground,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isIncome
                              ? 'Encaissement de loyer'
                              : 'Dépense d\'entretien / charge',
                          style: AppTypography.bodySmall(
                            color: AppColors.mutedForeground,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.positiveSoft,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'OPÉRATION VALIDÉE',
                            style: AppTypography.caption(
                              color: AppColors.primaryStrong,
                            ).copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tableau récapitulatif
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppShadows.soft,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'INFORMATIONS SUR LA TRANSACTION',
                          style: AppTypography.labelUppercase(
                            color: AppColors.mutedForeground,
                            fontSize: 10.5,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _TxRow(label: 'Intitulé', value: transaction.title),
                        Divider(color: AppColors.border, height: 1),
                        _TxRow(
                          label: isIncome
                              ? 'Locataire'
                              : 'Tiers / Bénéficiaire',
                          value: transaction.subtitle,
                        ),
                        Divider(color: AppColors.border, height: 1),
                        _TxRow(
                          label: 'Catégorie',
                          value:
                              transaction.category ??
                              (isIncome ? 'Loyer' : 'Maintenance'),
                        ),
                        Divider(color: AppColors.border, height: 1),
                        _TxRow(
                          label: 'Date de règlement',
                          value: formattedDate,
                        ),
                        Divider(color: AppColors.border, height: 1),
                        _TxRow(
                          label: 'Mode de paiement',
                          value: isIncome
                              ? 'MTN Mobile Money'
                              : 'Virement bancaire',
                        ),
                        Divider(color: AppColors.border, height: 1),
                        _TxRow(
                          label: 'Identifiant transaction',
                          value: transaction.id.toUpperCase(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Actions liées
                  if (isIncome)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DocumentDetailScreen(
                                document: DocumentItem(
                                  id: 'quittance-${transaction.id}',
                                  title: 'Quittance ${transaction.title}',
                                  property: transaction.subtitle,
                                  category: DocumentCategory.quittance,
                                  status: DocumentStatus.genere,
                                  date: transaction.date,
                                  size: '142 Ko',
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
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(
                          LucideIcons.file_text,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Consulter la quittance liée',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Affichage du reçu de justificatif',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.foreground,
                          side: BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(LucideIcons.image, size: 18),
                        label: const Text('Voir le justificatif de dépense'),
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

class _TxRow extends StatelessWidget {
  final String label;
  final String value;

  const _TxRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall(color: AppColors.mutedForeground),
          ),
          Text(
            value,
            style: AppTypography.bodySmall(color: AppColors.foreground)
                .copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
