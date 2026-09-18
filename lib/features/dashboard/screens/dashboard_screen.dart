import 'package:flutter/material.dart';

import '../../../core/design_system.dart';
import '../../../core/i18n/app_strings.dart';
import '../models/dashboard_data.dart';
import '../widgets/dashboard_flux_chart.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_kpis.dart';
import '../widgets/dashboard_quick_actions.dart';
import '../widgets/dashboard_recent_rents.dart';
import '../widgets/quick_action_sheet.dart';
import '../../biens/screens/nouveau_bien_screen.dart';
import '../../locataires/screens/nouveau_locataire_screen.dart';

import '../../notifications/screens/notifications_screen.dart';
import '../../profil/screens/profil_screen.dart';
import '../../finances/screens/transaction_detail_screen.dart';
import '../../finances/screens/depense_screen.dart';
import '../../finances/models/transaction.dart';
import '../../documents/screens/nouvelle_quittance_screen.dart';
import '../../documents/screens/nouveau_contrat_screen.dart';
import '../../documents/screens/nouvel_etat_des_lieux_screen.dart';

/// Écran principal du Dashboard (Accueil) de HopeGestion Mobile
/// Fidèle aux maquettes 01-dashboard.png et 02-action-rapide.png
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DashboardData _data;

  @override
  void initState() {
    super.initState();
    _data = DashboardData.mock();
  }

  Future<void> _refreshData() async {
    // Simule un rafraîchissement des données du dashboard
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _data = DashboardData.mock();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.t('Tableau de bord actualisé')),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleAction(String actionId) {
    if (actionId == 'property') {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const NouveauBienScreen()));
    } else if (actionId == 'tenant') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const NouveauLocataireScreen()));
    } else if (actionId == 'invoice') {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const DepenseScreen()));
    } else if (actionId == 'receipt') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const NouvelleQuittanceScreen()),
      );
    } else if (actionId == 'contract') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const NouveauContratScreen()));
    } else if (actionId == 'inventory') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const NouvelEtatDesLieuxScreen()),
      );
    }
  }

  void _openQuickActionSheet() async {
    final selectedId = await QuickActionSheet.show(context);
    if (selectedId != null && mounted) {
      _handleAction(selectedId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Contenu défilable
            RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.card,
              onRefresh: _refreshData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                children: [
                  // En-tête : Date, Salutation, Profil & Notifications
                  DashboardHeader(
                    dateFormatted: _data.dateFormatted,
                    userName: _data.userName,
                    onProfileTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProfilScreen()),
                      );
                    },
                    onNotificationsTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // 3 Cartes KPIs
                  DashboardKpis(
                    encaissements: _data.encaissements,
                    depenses: _data.depenses,
                    impayes: _data.impayes,
                    onKpiTap: (kpi) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppStrings.t('Détail KPI : {kpi}', {'kpi': kpi}),
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Graphique des Flux 7 Jours
                  DashboardFluxChart(
                    netAmount: _data.netFlux,
                    daysData: _data.fluxDays,
                  ),
                  const SizedBox(height: 16),

                  // Section Raccourcis CRÉER
                  DashboardQuickActions(onActionTap: _handleAction),
                  const SizedBox(height: 16),

                  // Section LOYERS RÉCENTS
                  DashboardRecentRents(
                    rents: _data.recentRents,
                    onSeeAllTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppStrings.t('Voir tous les loyers')),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    onRentTap: (rent) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TransactionDetailScreen(
                            transaction: FinanceTransaction(
                              id: 'tx-${rent.id}',
                              title: 'Loyer ${rent.property}',
                              subtitle: rent.tenant,
                              amount:
                                  int.tryParse(
                                    rent.amount.replaceAll(
                                      RegExp(r'[^0-9]'),
                                      '',
                                    ),
                                  ) ??
                                  185000,
                              isIncome: true,
                              date: DateTime.now(),
                              category: 'Loyer',
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Bouton d'action flottant FAB (+)
            Positioned(
              right: 20,
              bottom: 130,
              child: AppFab(onPressed: _openQuickActionSheet),
            ),
          ],
        ),
      ),
    );
  }
}
