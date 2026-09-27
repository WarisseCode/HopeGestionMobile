import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/config/app_config.dart';
import '../../../core/design_system.dart';
import '../data/locataire_results.dart';
import '../data/locataires_repository.dart';
import '../models/contact.dart';
import '../models/contacts_repository.dart';
import '../models/locataire.dart';
import '../widgets/contact_row.dart';
import 'nouveau_locataire_screen.dart';
import 'locataire_detail_screen.dart';

/// Écran liste des contacts. Les locataires (`LocatairesRepository`) sont
/// des données réelles depuis la phase 4.3 ; les propriétaires
/// (`ContactsRepository`) restent mockés — module distinct, hors périmètre
/// de cette phase (voir journal, T-027).
class LocatairesScreen extends StatefulWidget {
  const LocatairesScreen({super.key});

  @override
  State<LocatairesScreen> createState() => _LocatairesScreenState();
}

class _LocatairesScreenState extends State<LocatairesScreen> {
  /// 0 = Tous, 1 = Locataires, 2 = Propriétaires
  int _activeTab = 0;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    final result = await LocatairesRepository.instance.refresh();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _errorMessage = switch (result) {
        LocatairesListSuccess() => null,
        LocatairesListFailure(message: final message) => message,
      };
    });
  }

  Future<void> _refresh() async {
    final result = await LocatairesRepository.instance.refresh();
    if (!mounted) return;
    if (result is LocatairesListFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _openNouveauLocataire() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const NouveauLocataireScreen()));
  }

  void _openLocataireDetail(Locataire locataire) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LocataireDetailScreen(locataireId: locataire.id),
      ),
    );
  }

  void _showOwnersNotAvailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Le module Propriétaires n\'est pas encore disponible.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        LocatairesRepository.instance,
        ContactsRepository.instance,
      ]),
      builder: (context, _) {
        final locataires = LocatairesRepository.instance.items;
        final owners = ContactsRepository.instance.items
            .where((c) => c.type == ContactType.owner)
            .toList();

        if (_loading && locataires.isEmpty && _errorMessage == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (_errorMessage != null && locataires.isEmpty) {
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
                        'Impossible de charger les locataires',
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
                        label: 'Réessayer',
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

        return _buildScaffold(context, locataires, owners);
      },
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    List<Locataire> locataires,
    List<Contact> owners,
  ) {
    final int totalActifs = locataires.length + owners.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.card,
              onRefresh: _refresh,
              child: CustomScrollView(
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
                                  value: locataires.length.toString(),
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
                                  value: owners.length.toString(),
                                  isActive: _activeTab == 2,
                                  onTap: () => setState(
                                    () => _activeTab = _activeTab == 2 ? 0 : 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          if (_activeTab == 2) ...[
                            const AppWarningBanner(
                              text: 'Module Propriétaires : données '
                                  'd\'exemple, pas encore connecté au backend.',
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Liste des contacts
                  if (_activeTab != 2) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: AppCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              for (int i = 0; i < locataires.length; i++) ...[
                                ContactRow(
                                  initials: locataires[i].initials,
                                  name: locataires[i].displayName,
                                  info: _locataireInfo(locataires[i]),
                                  photoUrl: _resolvedPhotoUrl(
                                    locataires[i].photoProfilUrl,
                                  ),
                                  onTap: () =>
                                      _openLocataireDetail(locataires[i]),
                                ),
                                if (i < locataires.length - 1)
                                  Divider(
                                    height: 1,
                                    color: AppColors.border,
                                    indent: 74,
                                  ),
                              ],
                              if (locataires.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 24,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Aucun locataire pour le moment.',
                                      style: AppTypography.bodySmall(
                                        color: AppColors.mutedForeground,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: AppCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              for (int i = 0; i < owners.length; i++) ...[
                                ContactRow(
                                  initials: owners[i].initials,
                                  name: owners[i].name,
                                  info: owners[i].info,
                                  onTap: _showOwnersNotAvailable,
                                ),
                                if (i < owners.length - 1)
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
                  ],

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
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

  String _locataireInfo(Locataire l) {
    if (l.lotNom != null && l.lotNom!.isNotEmpty) {
      return '${l.type} · ${l.lotNom}';
    }
    return '${l.type} · ${l.statut}';
  }
}

/// `null`/vide reste `null` (`ContactRow` affiche alors les initiales) ;
/// sinon résout un chemin relatif (`/uploads/avatars/...`) en URL absolue —
/// même logique que `ImmeubleCard`/`_LotRow` (T-031/T-034).
String? _resolvedPhotoUrl(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  return AppConfig.resolveFileUrl(raw);
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
