import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../models/contact.dart';
import '../models/contacts_repository.dart';
import '../widgets/contact_row.dart';
import 'nouveau_locataire_screen.dart';
import 'locataire_detail_screen.dart';

/// Écran liste des contacts (locataires + propriétaires).
class LocatairesScreen extends StatefulWidget {
  const LocatairesScreen({super.key});

  @override
  State<LocatairesScreen> createState() => _LocatairesScreenState();
}

class _LocatairesScreenState extends State<LocatairesScreen> {
  /// 0 = Tous, 1 = Locataires, 2 = Propriétaires
  int _activeTab = 0;

  void _openNouveauLocataire() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const NouveauLocataireScreen()));
  }

  List<Contact> _filteredFrom(List<Contact> all) {
    switch (_activeTab) {
      case 1:
        return all.where((c) => c.type == ContactType.tenant).toList();
      case 2:
        return all.where((c) => c.type == ContactType.owner).toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ContactsRepository.instance,
      builder: (context, _) {
        final repo = ContactsRepository.instance;
        final filtered = _filteredFrom(repo.items);

        return _buildScaffold(
          context,
          filtered,
          repo.items.length,
          repo.tenantCount,
          repo.ownerCount,
        );
      },
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    List<Contact> filtered,
    int totalActifs,
    int tenants,
    int owners,
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
                              '$totalActifs CONTACTS ACTIFS',
                              style: AppTypography.labelUppercase(
                                color: AppColors.mutedForeground,
                              ),
                            ),
                            // Bouton ajouter
                            GestureDetector(
                              onTap: _openNouveauLocataire,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  LucideIcons.user_plus,
                                  size: 16,
                                  color: AppColors.primaryForeground,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Contacts', style: AppTypography.titleScreen()),
                        const SizedBox(height: 16),

                        // KPI chips filtrables
                        Row(
                          children: [
                            Expanded(
                              child: _KpiChip(
                                label: 'LOCATAIRES',
                                value: tenants.toString(),
                                isActive: _activeTab == 1,
                                onTap: () => setState(
                                  () => _activeTab = _activeTab == 1 ? 0 : 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _KpiChip(
                                label: 'PROPRIÉTAIRES',
                                value: owners.toString(),
                                isActive: _activeTab == 2,
                                onTap: () => setState(
                                  () => _activeTab = _activeTab == 2 ? 0 : 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // Liste des contacts
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (int i = 0; i < filtered.length; i++) ...[
                            ContactRow(
                              contact: filtered[i],
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => LocataireDetailScreen(
                                      contact: filtered[i],
                                    ),
                                  ),
                                );
                              },
                            ),
                            if (i < filtered.length - 1)
                              Divider(
                                height: 1,
                                color: AppColors.border,
                                indent: 74,
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),

            // FAB
            Positioned(
              right: 20,
              bottom: 90,
              child: AppFab(onPressed: _openNouveauLocataire),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chip KPI cliquable avec filtre actif
// ---------------------------------------------------------------------------

class _KpiChip extends StatelessWidget {
  const _KpiChip({
    required this.label,
    required this.value,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withAlpha(20) : AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: isActive ? [] : AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.labelUppercase(
                color: isActive ? AppColors.primary : AppColors.mutedForeground,
                fontSize: 9.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTypography.kpiValue(
                color: isActive ? AppColors.primary : AppColors.foreground,
                fontSize: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
