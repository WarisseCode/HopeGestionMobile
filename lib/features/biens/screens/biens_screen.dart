import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../data/biens_repository.dart';
import '../data/biens_results.dart';
import '../models/immeuble.dart';
import '../models/immeubles_filtre.dart';
import '../widgets/immeuble_card.dart';
import '../widgets/immeuble_card_skeleton.dart';
import 'immeuble_detail_screen.dart';
import 'nouveau_bien_screen.dart';

/// Écran liste des immeubles réels. Présente les **immeubles** comme
/// entité principale (chacun avec son taux d'occupation déjà calculé côté
/// serveur), les lots étant accessibles depuis la fiche de chaque immeuble
/// (`ImmeubleDetailScreen`) — reflète la vraie hiérarchie backend
/// (`buildings`/`lots`), plutôt que de reconstituer la liste plate de
/// l'ancien `Bien` mocké qui n'avait pas de sens sans entité "lot" propre.
class BiensScreen extends StatefulWidget {
  const BiensScreen({super.key});

  /// En-tête « X IMMEUBLES · Y/Z LOTS OCCUPÉS », calculé sur **tous** les
  /// immeubles (pas la liste filtrée). Y/Z reprennent `lotsOccupes`/`nbLots`
  /// tels que calculés côté serveur (`bienRoutes.ts` : un lot `reserve`
  /// compte comme occupé, comme `loue`/`occupe`). Sans aucun lot (Z = 0),
  /// seule la partie immeubles est affichée.
  static String enteteLabel(List<Immeuble> immeubles) {
    final immeublesLabel = '${immeubles.length} IMMEUBLES';
    final totalLots = immeubles.fold<int>(0, (sum, i) => sum + i.nbLots);
    if (totalLots == 0) return immeublesLabel;
    final lotsOccupes = immeubles.fold<int>(0, (sum, i) => sum + i.lotsOccupes);
    return '$immeublesLabel · $lotsOccupes/$totalLots LOTS OCCUPÉS';
  }

  @override
  State<BiensScreen> createState() => _BiensScreenState();
}

class _BiensScreenState extends State<BiensScreen> {
  /// Position du FAB au-dessus de la barre de navigation flottante
  /// (`AppBottomBar` : 64 px + marge 16 px, posée par `ShellScreen`).
  static const double _fabBottom = 90;

  /// Marge sous la dernière carte : position du FAB + sa taille (56 px) +
  /// 16 px d'air, pour que la dernière carte défile au-dessus du FAB.
  static const double _listBottomInset = _fabBottom + 56 + 16;

  final _searchController = TextEditingController();
  String _query = '';
  ImmeublesFiltre _filtre = ImmeublesFiltre.tous;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearch);
    _load();
  }

  void _onSearch() {
    setState(() => _query = _searchController.text.toLowerCase());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await BiensRepository.instance.listImmeubles();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result is ImmeublesListFailure) _error = result.message;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Ouvre directement la création d'immeuble (pas `QuickActionSheet` :
  /// sur l'onglet Biens, l'intention est sans ambiguïté). Pas de rechargement
  /// au retour : `createImmeuble` rafraîchit déjà le dépôt, que cet écran
  /// écoute via `ListenableBuilder`.
  void _openNouveauBien() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const NouveauBienScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BiensRepository.instance,
      builder: (context, _) {
        final all = BiensRepository.instance.immeubles;
        final searched = _query.isEmpty
            ? all
            : all
                  .where(
                    (i) =>
                        i.nom.toLowerCase().contains(_query) ||
                        (i.ville ?? '').toLowerCase().contains(_query),
                  )
                  .toList();
        // Compteurs des puces calculés après la recherche : chacun annonce
        // exactement ce que la puce affichera une fois sélectionnée.
        final counts = {
          for (final f in ImmeublesFiltre.values)
            f: searched.where(f.matches).length,
        };
        final filtered = searched.where(_filtre.matches).toList();
        return _buildScaffold(
          context,
          filtered,
          counts,
          BiensScreen.enteteLabel(all),
        );
      },
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    List<Immeuble> filtered,
    Map<ImmeublesFiltre, int> counts,
    String entete,
  ) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entete,
                            style: AppTypography.labelUppercase(
                              color: AppColors.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Mes biens', style: AppTypography.titleScreen()),
                          const SizedBox(height: 16),

                          AppTextField(
                            controller: _searchController,
                            hintText: 'Rechercher un immeuble...',
                            prefixIcon: Icon(
                              LucideIcons.search,
                              size: 18,
                              color: AppColors.mutedForeground,
                            ),
                            suffixIcon: _query.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Effacer la recherche',
                                    onPressed: _searchController.clear,
                                    icon: Icon(
                                      LucideIcons.x,
                                      size: 18,
                                      color: AppColors.mutedForeground,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),

                  // Puces hors du padding de la colonne : elles défilent
                  // horizontalement jusqu'aux bords de l'écran.
                  SliverToBoxAdapter(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Row(
                        children: [
                          for (final f in ImmeublesFiltre.values) ...[
                            if (f != ImmeublesFiltre.values.first)
                              const SizedBox(width: 8),
                            AppToggleChip(
                              label: '${f.label} (${counts[f] ?? 0})',
                              isSelected: f == _filtre,
                              onTap: () => setState(() => _filtre = f),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Squelettes seulement au premier chargement : lors d'un
                  // rafraîchissement (retour de fiche, pull-to-refresh), la
                  // liste déjà connue reste affichée au lieu de clignoter.
                  if (_loading && BiensRepository.instance.immeubles.isEmpty)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => Padding(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            i == 0 ? 0 : 8,
                            20,
                            0,
                          ),
                          child: const ImmeubleCardSkeleton(),
                        ),
                        childCount: 5,
                      ),
                    )
                  else if (_error != null)
                    SliverFillRemaining(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: AppTypography.bodySmall(
                                  color: AppColors.mutedForeground,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: _load,
                                child: const Text('Réessayer'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else if (filtered.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'Aucun immeuble trouvé',
                          style: AppTypography.bodySmall(
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => Padding(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            i == 0 ? 0 : 8,
                            20,
                            i == filtered.length - 1 ? _listBottomInset : 0,
                          ),
                          child: ImmeubleCard(
                            immeuble: filtered[i],
                            onTap: () {
                              Navigator.of(context)
                                  .push(
                                    MaterialPageRoute(
                                      builder: (_) => ImmeubleDetailScreen(
                                        immeubleId: filtered[i].id,
                                      ),
                                    ),
                                  )
                                  .then((_) => _load());
                            },
                          ),
                        ),
                        childCount: filtered.length,
                      ),
                    ),
                ],
              ),
            ),

            Positioned(
              right: 20,
              bottom: _fabBottom,
              child: AppFab(onPressed: _openNouveauBien),
            ),
          ],
        ),
      ),
    );
  }
}
