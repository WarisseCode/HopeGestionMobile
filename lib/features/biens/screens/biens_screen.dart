import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../../../features/dashboard/widgets/quick_action_sheet.dart';
import 'bien_detail_screen.dart';
import '../models/bien.dart';
import '../models/biens_repository.dart';
import '../widgets/bien_card.dart';

/// Écran liste des biens immobiliers.
class BiensScreen extends StatefulWidget {
  const BiensScreen({super.key});

  @override
  State<BiensScreen> createState() => _BiensScreenState();
}

class _BiensScreenState extends State<BiensScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearch);
  }

  void _onSearch() {
    setState(() => _query = _searchController.text.toLowerCase());
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
        final all = BiensRepository.instance.items;
        final filtered = _query.isEmpty
            ? all
            : all
                  .where(
                    (b) =>
                        b.name.toLowerCase().contains(_query) ||
                        b.type.toLowerCase().contains(_query),
                  )
                  .toList();
        final total = all.length;
        final occupes = all.where((b) => b.status == BienStatus.occupe).length;

        return _buildScaffold(context, filtered, total, occupes);
      },
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    List<Bien> filtered,
    int total,
    int occupes,
  ) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$total BIENS · $occupes OCCUPÉS',
                              style: AppTypography.labelUppercase(
                                color: AppColors.mutedForeground,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                LucideIcons.sliders_horizontal,
                                size: 20,
                                color: AppColors.foreground,
                              ),
                              onPressed: () {},
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Mes biens', style: AppTypography.titleScreen()),
                        const SizedBox(height: 16),

                        // Search bar
                        AppTextField(
                          controller: _searchController,
                          hintText: 'Rechercher un bien...',
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

                // Liste
                filtered.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
                          child: Text(
                            'Aucun bien trouvé',
                            style: AppTypography.bodySmall(
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => Padding(
                            padding: EdgeInsets.fromLTRB(
                              20,
                              i == 0 ? 0 : 8,
                              20,
                              i == filtered.length - 1 ? 100 : 0,
                            ),
                            child: BienCard(
                              bien: filtered[i],
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        BienDetailScreen(bien: filtered[i]),
                                  ),
                                );
                              },
                              onMenu: () {},
                            ),
                          ),
                          childCount: filtered.length,
                        ),
                      ),
              ],
            ),

            // FAB
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
