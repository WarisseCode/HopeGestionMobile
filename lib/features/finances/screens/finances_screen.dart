import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../../dashboard/widgets/quick_action_sheet.dart';
import '../models/transaction.dart';
import '../widgets/finances_action_buttons.dart';
import '../widgets/finances_balance_card.dart';
import '../widgets/transaction_item.dart';
import 'encaisser_screen.dart';
import 'depense_screen.dart';
import 'transaction_detail_screen.dart';

/// Écran principal des Finances
/// Conforme à la maquette 05-finances.png
class FinancesScreen extends StatefulWidget {
  const FinancesScreen({super.key});

  @override
  State<FinancesScreen> createState() => _FinancesScreenState();
}

class _FinancesScreenState extends State<FinancesScreen> {
  final FinanceMetrics _metrics = FinanceMetrics.mock;
  late List<FinanceTransaction> _transactions;

  @override
  void initState() {
    super.initState();
    _transactions = FinanceTransaction.mockList;
  }

  void _openQuickActions() {
    QuickActionSheet.showAndNavigate(context);
  }

  void _onEncaisser() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const EncaisserScreen()));
  }

  void _onDepense() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const DepenseScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête : Mois + Titre + Bouton options
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _metrics.period,
                            style: AppTypography.labelUppercase(
                              color: AppColors.mutedForeground,
                              fontSize: 11,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Finances',
                            style: AppTypography.titleScreen(fontSize: 26),
                          ),
                        ],
                      ),
                      // Bouton d'options "..."
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Options de filtrage financier'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border),
                            boxShadow: AppShadows.soft,
                          ),
                          child: Center(
                            child: Icon(
                              LucideIcons.ellipsis,
                              size: 20,
                              color: AppColors.foreground,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Carte Sombre Solde Disponible
                  FinancesBalanceCard(metrics: _metrics),
                  const SizedBox(height: 16),

                  // Boutons Encaisser & Dépense
                  FinancesActionButtons(
                    onEncaisser: _onEncaisser,
                    onDepense: _onDepense,
                  ),
                  const SizedBox(height: 24),

                  // Conteneur « DERNIÈRES OPÉRATIONS »
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppShadows.soft,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DERNIÈRES OPÉRATIONS',
                          style: AppTypography.labelUppercase(
                            color: AppColors.mutedForeground,
                            fontSize: 10.5,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 10),

                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _transactions.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            thickness: 0.8,
                            color: AppColors.border,
                          ),
                          itemBuilder: (context, index) {
                            final tx = _transactions[index];
                            return TransactionItem(
                              transaction: tx,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => TransactionDetailScreen(
                                      transaction: tx,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // FAB Flottant
            Positioned(
              right: 20,
              bottom: 90,
              child: AppFab(onPressed: _openQuickActions),
            ),
          ],
        ),
      ),
    );
  }
}
