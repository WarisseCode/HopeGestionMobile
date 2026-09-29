import 'package:flutter/material.dart';

import '../../../core/design_system.dart';
import '../../../core/i18n/app_strings.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/auth_state.dart';
import '../data/dashboard_repository.dart';
import '../data/dashboard_result.dart';
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
import '../../documents/screens/nouvelle_quittance_screen.dart';
import '../../documents/screens/nouveau_contrat_screen.dart';
import '../../documents/screens/nouvel_etat_des_lieux_screen.dart';

const _weekdays = [
  'LUNDI',
  'MARDI',
  'MERCREDI',
  'JEUDI',
  'VENDREDI',
  'SAMEDI',
  'DIMANCHE',
];
const _months = [
  'JANVIER',
  'FÉVRIER',
  'MARS',
  'AVRIL',
  'MAI',
  'JUIN',
  'JUILLET',
  'AOÛT',
  'SEPTEMBRE',
  'OCTOBRE',
  'NOVEMBRE',
  'DÉCEMBRE',
];

String _todayFormatted() {
  final now = DateTime.now();
  return '${_weekdays[now.weekday - 1]} ${now.day} ${_months[now.month - 1]}';
}

/// Écran principal du Dashboard (Accueil) de HopeGestion Mobile.
/// Données réelles chargées depuis `/api/dashboard/*` via
/// [DashboardRepository] — voir sa doc de classe pour le détail des routes.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardRepository _repository;
  DashboardData? _data;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = DashboardRepository(
      apiClient: AuthRepository.instance.apiClient,
    );
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    final result = await _repository.load();
    if (!mounted) return;
    switch (result) {
      case DashboardLoadSuccess(data: final data):
        setState(() {
          _data = data;
          _loading = false;
        });
      case DashboardLoadFailure(message: final message):
        setState(() {
          _errorMessage = message;
          _loading = false;
        });
    }
  }

  /// Tirer-pour-rafraîchir : contrairement au chargement initial, un échec
  /// ici ne doit pas effacer les données déjà affichées (évite un écran
  /// d'erreur plein écran alors que l'utilisateur avait déjà des données
  /// valides) — juste un message.
  Future<void> _refreshData() async {
    final result = await _repository.load();
    if (!mounted) return;
    switch (result) {
      case DashboardLoadSuccess(data: final data):
        setState(() {
          _data = data;
          _errorMessage = null;
        });
      case DashboardLoadFailure(message: final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
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
    final authState = AuthRepository.instance.state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    if (_loading && _data == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_errorMessage != null && _data == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppStrings.t('Impossible de charger le tableau de bord'),
                    textAlign: TextAlign.center,
                    style: AppTypography.titleScreen(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall(
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppButton.primary(
                    label: AppStrings.t('Réessayer'),
                    onPressed: _loadInitial,
                    isFullWidth: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final data = _data!;

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
                    dateFormatted: _todayFormatted(),
                    userName: user?.displayName ?? '',
                    avatarUrl: user?.avatarUrl,
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
                    encaissements: data.encaissements,
                    depenses: data.depenses,
                    impayes: data.impayes,
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
                    netAmount: data.netFlux,
                    daysData: data.fluxDays,
                  ),
                  const SizedBox(height: 16),

                  // Section Raccourcis CRÉER
                  DashboardQuickActions(onActionTap: _handleAction),
                  const SizedBox(height: 16),

                  // Section LOYERS RÉCENTS
                  DashboardRecentRents(
                    rents: data.recentRents,
                    onSeeAllTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppStrings.t('Voir tous les loyers')),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    onRentTap: (rent) {
                      // `rent.id` = identifiant réel du paiement
                      // (`/dashboard/activity`, type `payment`) : la fiche
                      // charge le paiement lui-même.
                      final paiementId = int.tryParse(rent.id);
                      if (paiementId == null) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TransactionDetailScreen.paiement(
                            paiementId: paiementId,
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
