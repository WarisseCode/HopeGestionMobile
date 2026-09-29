import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../../dashboard/widgets/quick_action_sheet.dart';
import '../data/finances_repository.dart';
import '../data/finances_results.dart';
import '../models/finance_format.dart';
import '../models/finance_stats.dart';
import '../models/mouvement.dart';
import '../widgets/finances_action_buttons.dart';
import '../widgets/finances_balance_card.dart';
import '../widgets/finances_skeleton.dart';
import '../widgets/transaction_item.dart';
import 'encaisser_screen.dart';
import 'depense_screen.dart';
import 'transaction_detail_screen.dart';

/// Écran principal des Finances (phase 4.5, lecture seule) : synthèse du
/// mois (`GET /finances/stats`) et mouvements du mois — paiements
/// (`GET /finances`) et dépenses (`GET /expenses`) fusionnés, voir
/// [Mouvement.fusionner].
class FinancesScreen extends StatefulWidget {
  const FinancesScreen({super.key, this.maintenant});

  /// Horloge injectable (tests) : fixe le mois courant, mois affiché par
  /// défaut et borne de navigation. `DateTime.now` sinon.
  final DateTime Function()? maintenant;

  @override
  State<FinancesScreen> createState() => _FinancesScreenState();
}

class _FinancesScreenState extends State<FinancesScreen> {
  late final DateTime _moisCourant;
  late DateTime _mois;

  bool _loading = true;
  String? _error;
  FinanceStats _stats = FinanceStats.zero;
  List<Mouvement> _mouvements = const [];

  /// Numéro de la dernière requête : une réponse d'un mois quitté entre-temps
  /// (navigation rapide) est ignorée.
  int _requete = 0;

  @override
  void initState() {
    super.initState();
    final now = (widget.maintenant ?? DateTime.now)();
    _moisCourant = DateTime(now.year, now.month);
    _mois = _moisCourant;
    _load();
  }

  bool get _estMoisCourant => !_mois.isBefore(_moisCourant);

  void _changerMois(int delta) {
    final cible = DateTime(_mois.year, _mois.month + delta);
    if (cible.isAfter(_moisCourant)) return;
    setState(() => _mois = cible);
    _load();
  }

  Future<void> _load() async {
    final requete = ++_requete;
    setState(() {
      _loading = true;
      _error = null;
    });
    final repo = FinancesRepository.instance;
    // Bornes incluses : du 1er au dernier jour du mois.
    final debut = DateTime(_mois.year, _mois.month, 1);
    final fin = DateTime(_mois.year, _mois.month + 1, 0);
    final (paiements, depenses, stats) = await (
      repo.listPaiements(debut: debut, fin: fin),
      repo.listDepenses(debut: debut, fin: fin),
      repo.getStats(mois: _mois.month, annee: _mois.year),
    ).wait;
    if (!mounted || requete != _requete) return;
    setState(() {
      _loading = false;
      _error = switch ((paiements, depenses, stats)) {
        (PaiementsListFailure(:final message), _, _) => message,
        (_, DepensesListFailure(:final message), _) => message,
        (_, _, FinanceStatsFailure(:final message)) => message,
        _ => null,
      };
      if (_error != null) return;
      _stats = (stats as FinanceStatsSuccess).stats;
      _mouvements = Mouvement.fusionner(
        (paiements as PaiementsListSuccess).items,
        (depenses as DepensesListSuccess).items,
      );
    });
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

  void _openDetail(Mouvement mouvement) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionDetailScreen(mouvement: mouvement),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête : Titre + Bouton options
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Finances',
                          style: AppTypography.titleScreen(fontSize: 26),
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
                    const SizedBox(height: 16),

                    _SelecteurMois(
                      libelle: formatMois(_mois).toUpperCase(),
                      onPrecedent: () => _changerMois(-1),
                      onSuivant: _estMoisCourant
                          ? null
                          : () => _changerMois(1),
                    ),
                    const SizedBox(height: 16),

                    if (_error != null)
                      _Erreur(message: _error!, onRetry: _load)
                    else if (_loading)
                      const FinancesSkeleton.carte()
                    else
                      FinancesBalanceCard(stats: _stats),
                    const SizedBox(height: 16),

                    // Boutons Encaisser & Dépense (écrans actuels, branchés
                    // aux étapes 2 et 3).
                    FinancesActionButtons(
                      onEncaisser: _onEncaisser,
                      onDepense: _onDepense,
                    ),

                    if (_error == null) ...[
                      const SizedBox(height: 24),
                      _SectionMouvements(
                        loading: _loading,
                        mouvements: _mouvements,
                        onTap: _openDetail,
                      ),
                    ],
                  ],
                ),
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

class _SelecteurMois extends StatelessWidget {
  const _SelecteurMois({
    required this.libelle,
    required this.onPrecedent,
    required this.onSuivant,
  });

  final String libelle;
  final VoidCallback onPrecedent;

  /// `null` sur le mois courant : pas de navigation vers le futur.
  final VoidCallback? onSuivant;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Mois précédent',
            onPressed: onPrecedent,
            icon: Icon(
              LucideIcons.chevron_left,
              size: 20,
              color: AppColors.foreground,
            ),
          ),
          Expanded(
            child: Text(
              libelle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelUppercase(
                color: AppColors.foreground,
                fontSize: 12,
                letterSpacing: 0.8,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Mois suivant',
            onPressed: onSuivant,
            icon: Icon(
              LucideIcons.chevron_right,
              size: 20,
              color: onSuivant == null
                  ? AppColors.border
                  : AppColors.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionMouvements extends StatelessWidget {
  const _SectionMouvements({
    required this.loading,
    required this.mouvements,
    required this.onTap,
  });

  final bool loading;
  final List<Mouvement> mouvements;
  final ValueChanged<Mouvement> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            loading
                ? 'MOUVEMENTS DU MOIS'
                : 'MOUVEMENTS DU MOIS · ${mouvements.length}',
            style: AppTypography.labelUppercase(
              color: AppColors.mutedForeground,
              fontSize: 10.5,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          if (loading)
            const FinancesSkeleton.lignes()
          else if (mouvements.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Aucun encaissement ni dépense ce mois-ci',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall(
                    color: AppColors.mutedForeground,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: mouvements.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, thickness: 0.8, color: AppColors.border),
              itemBuilder: (context, index) {
                final m = mouvements[index];
                return TransactionItem(mouvement: m, onTap: () => onTap(m));
              },
            ),
        ],
      ),
    );
  }
}

class _Erreur extends StatelessWidget {
  const _Erreur({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall(color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}
