import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/config/app_config.dart';
import '../../../core/design_system.dart';
import '../data/locataire_results.dart';
import '../data/locataires_repository.dart';
import '../data/owners_repository.dart';
import '../models/locataire.dart';
import '../models/owner.dart';
import '../widgets/contact_row.dart';
import 'nouveau_locataire_screen.dart';
import 'locataire_detail_screen.dart';
import 'owner_detail_screen.dart';

/// Écran liste des contacts : locataires (`LocatairesRepository`,
/// `GET /locataires`) et propriétaires (`OwnersRepository`, `GET /owners`),
/// tous deux réels. L'onglet « Tous » affiche les deux listes, cohérent
/// avec le compteur « N CONTACTS ACTIFS » qui les additionne.
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

  /// État de chargement des propriétaires, indépendant de celui des
  /// locataires : un échec de `/owners` ne masque pas la liste des
  /// locataires (et inversement pour la section propriétaires).
  bool _ownersLoading = true;
  String? _ownersError;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _ownersLoading = true;
      _ownersError = null;
    });
    final (result, ownersResult) = await (
      LocatairesRepository.instance.refresh(),
      OwnersRepository.instance.refresh(),
    ).wait;
    if (!mounted) return;
    setState(() {
      _loading = false;
      _errorMessage = switch (result) {
        LocatairesListSuccess() => null,
        LocatairesListFailure(message: final message) => message,
      };
      _ownersLoading = false;
      _ownersError = _ownersErrorOf(ownersResult);
    });
  }

  Future<void> _loadOwners() async {
    setState(() {
      _ownersLoading = true;
      _ownersError = null;
    });
    final result = await OwnersRepository.instance.refresh();
    if (!mounted) return;
    setState(() {
      _ownersLoading = false;
      _ownersError = _ownersErrorOf(result);
    });
  }

  String? _ownersErrorOf(OwnersListResult result) => switch (result) {
    OwnersListSuccess() => null,
    OwnersListFailure(message: final message) => message,
  };

  Future<void> _refresh() async {
    final (result, ownersResult) = await (
      LocatairesRepository.instance.refresh(),
      OwnersRepository.instance.refresh(),
    ).wait;
    if (!mounted) return;
    setState(() => _ownersError = _ownersErrorOf(ownersResult));
    final message = switch ((result, ownersResult)) {
      (LocatairesListFailure(message: final m), _) => m,
      (_, OwnersListFailure(message: final m)) => m,
      _ => null,
    };
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
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

  void _openOwnerDetail(Owner owner) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OwnerDetailScreen(ownerId: owner.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        LocatairesRepository.instance,
        OwnersRepository.instance,
      ]),
      builder: (context, _) {
        final locataires = LocatairesRepository.instance.items;
        final owners = OwnersRepository.instance.items;

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
    List<Owner> owners,
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
                              // Bouton ajouter (création de locataire
                              // uniquement : masqué sur l'onglet
                              // Propriétaires).
                              if (_activeTab != 2)
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
                        ],
                      ),
                    ),
                  ),

                  // Liste des contacts : « Tous » (0) affiche les deux
                  // sections, cohérent avec le compteur global.
                  if (_activeTab != 2) ...[
                    if (_activeTab == 0) _sectionTitle('Locataires'),
                    _locatairesSection(locataires),
                  ],
                  if (_activeTab == 0)
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  if (_activeTab != 1) ...[
                    if (_activeTab == 0) _sectionTitle('Propriétaires'),
                    _ownersSection(owners),
                  ],

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),

            // FAB (création de locataire : masqué sur l'onglet Propriétaires)
            if (_activeTab != 2)
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

  Widget _sectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 20, 8),
        child: Text(title, style: AppTypography.titleSection(fontSize: 14)),
      ),
    );
  }

  Widget _sectionCard(List<Widget> children) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: AppCard(
          padding: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ),
    );
  }

  Widget _emptyText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          text,
          style: AppTypography.bodySmall(color: AppColors.mutedForeground),
        ),
      ),
    );
  }

  Widget _locatairesSection(List<Locataire> locataires) {
    return _sectionCard([
      for (int i = 0; i < locataires.length; i++) ...[
        ContactRow(
          initials: locataires[i].initials,
          name: locataires[i].displayName,
          info: _locataireInfo(locataires[i]),
          photoUrl: _resolvedPhotoUrl(locataires[i].photoProfilUrl),
          onTap: () => _openLocataireDetail(locataires[i]),
        ),
        if (i < locataires.length - 1)
          Divider(height: 1, color: AppColors.border, indent: 74),
      ],
      if (locataires.isEmpty) _emptyText('Aucun locataire pour le moment.'),
    ]);
  }

  /// États chargement / erreur / vide propres aux propriétaires, affichés
  /// dans la section (pas en plein écran) : la liste des locataires reste
  /// visible même si `/owners` échoue.
  Widget _ownersSection(List<Owner> owners) {
    if (owners.isEmpty && _ownersLoading) {
      return _sectionCard([
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      ]);
    }
    if (owners.isEmpty && _ownersError != null) {
      return _sectionCard([
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            children: [
              Text(
                'Impossible de charger les propriétaires',
                textAlign: TextAlign.center,
                style: AppTypography.titleSection(fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                _ownersError!,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall(
                  color: AppColors.mutedForeground,
                ),
              ),
              const SizedBox(height: 14),
              AppButton.primary(
                label: 'Réessayer',
                onPressed: _loadOwners,
                isFullWidth: false,
              ),
            ],
          ),
        ),
      ]);
    }
    return _sectionCard([
      for (int i = 0; i < owners.length; i++) ...[
        ContactRow(
          initials: owners[i].initials,
          name: owners[i].displayName,
          info: owners[i].info,
          photoUrl: _resolvedPhotoUrl(owners[i].photo),
          onTap: () => _openOwnerDetail(owners[i]),
        ),
        if (i < owners.length - 1)
          Divider(height: 1, color: AppColors.border, indent: 74),
      ],
      if (owners.isEmpty) _emptyText('Aucun propriétaire pour le moment.'),
    ]);
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
