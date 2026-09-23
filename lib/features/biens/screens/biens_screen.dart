import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../../../features/dashboard/widgets/quick_action_sheet.dart';
import '../data/biens_repository.dart';
import '../data/biens_results.dart';
import '../models/immeuble.dart';
import '../widgets/immeuble_card.dart';
import 'immeuble_detail_screen.dart';

/// Écran liste des immeubles réels. Présente les **immeubles** comme
/// entité principale (chacun avec son taux d'occupation déjà calculé côté
/// serveur), les lots étant accessibles depuis la fiche de chaque immeuble
/// (`ImmeubleDetailScreen`) — reflète la vraie hiérarchie backend
/// (`buildings`/`lots`), plutôt que de reconstituer la liste plate de
/// l'ancien `Bien` mocké qui n'avait pas de sens sans entité "lot" propre.
class BiensScreen extends StatefulWidget {
  const BiensScreen({super.key});

  @override
  State<BiensScreen> createState() => _BiensScreenState();
}

class _BiensScreenState extends State<BiensScreen> {
  final _searchController = TextEditingController();
  String _query = '';
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

  void _openQuickActions() {
    QuickActionSheet.showAndNavigate(context);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BiensRepository.instance,
      builder: (context, _) {
        final all = BiensRepository.instance.immeubles;
        final filtered = _query.isEmpty
            ? all
            : all
                  .where(
                    (i) =>
                        i.nom.toLowerCase().contains(_query) ||
                        (i.ville ?? '').toLowerCase().contains(_query),
                  )
                  .toList();
        final total = all.length;
        final occupes = all.where((i) => i.lotsOccupes > 0).length;

        return _buildScaffold(context, filtered, total, occupes);
      },
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    List<Immeuble> filtered,
    int total,
    int occupes,
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
                            '$total IMMEUBLES · $occupes AVEC LOCATAIRES',
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
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  if (_loading)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
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
                            i == filtered.length - 1 ? 100 : 0,
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
              bottom: 90,
              child: AppFab(onPressed: _openQuickActions),
            ),
          ],
        ),
      ),
    );
  }
}
