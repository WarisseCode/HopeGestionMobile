import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../../../core/network/api_exception.dart';
import '../data/notifications_repository.dart';
import '../data/notifications_results.dart';
import '../models/alerte.dart';

/// Écran des alertes (`NotificationsRepository`, `GET /api/alertes`).
///
/// - Pas de date affichée : `dateCreation` est générée à la volée par le
///   serveur pour la plupart des alertes (voir `Alerte`).
/// - Une seule action par alerte : « Ignorer » (`POST /alertes/:id/dismiss`).
///   Pas de « tout ignorer » : le backend n'offre que la réinitialisation
///   des alertes ignorées (`DELETE /alertes/dismissed`), soit l'inverse.
/// - Pas de bouton « Relancer » : la relance WhatsApp/appel sera branchée
///   dans une étape séparée.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  /// 0 : Toutes, 1 : Impayés, 2 : Baux & Contrats. Pas de filtre
  /// « Paiements » : `/alertes` ne signale aucun paiement reçu.
  int _activeFilter = 0;

  static const List<String> _filters = ['Toutes', 'Impayés', 'Baux & Contrats'];

  bool _loading = true;
  String? _errorMessage;
  ApiExceptionType? _errorType;

  /// Alertes dont l'ignorance est en cours d'envoi (bouton désactivé).
  final Set<String> _dismissing = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _errorType = null;
    });
    final result = await NotificationsRepository.instance.refresh();
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case AlertesListSuccess():
          break;
        case AlertesListFailure(:final message, :final type):
          _errorMessage = message;
          _errorType = type;
      }
    });
  }

  Future<void> _refresh() async {
    final result = await NotificationsRepository.instance.refresh();
    if (!mounted) return;
    if (result is AlertesListFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _dismiss(Alerte alerte) async {
    if (_dismissing.contains(alerte.id)) return;
    setState(() => _dismissing.add(alerte.id));
    final result = await NotificationsRepository.instance.dismiss(alerte.id);
    if (!mounted) return;
    setState(() => _dismissing.remove(alerte.id));
    final message = switch (result) {
      DismissAlerteSuccess() => 'Alerte ignorée',
      DismissAlerteFailure(:final message) => message,
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  List<Alerte> _filtered(List<Alerte> alertes) {
    switch (_activeFilter) {
      case 1:
        return alertes
            .where((a) => a.categorie == AlerteCategorie.impaye)
            .toList();
      case 2:
        return alertes
            .where((a) => a.categorie == AlerteCategorie.contrat)
            .toList();
      default:
        return alertes;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NotificationsRepository.instance,
      builder: (context, _) {
        final repo = NotificationsRepository.instance;
        final alertes = repo.items;

        final Widget body;
        if (_loading && alertes.isEmpty && _errorMessage == null) {
          body = Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        } else if (_errorMessage != null && alertes.isEmpty) {
          body = _buildError();
        } else {
          body = _buildContent(alertes);
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(alertes.length, repo.dismissedCount),
                Expanded(child: body),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(int count, int dismissedCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(LucideIcons.arrow_left, color: AppColors.foreground),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Notifications',
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleScreen(fontSize: 22),
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$count',
                          style: AppTypography.caption(color: Colors.white)
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                if (dismissedCount > 0)
                  Text(
                    dismissedCount == 1
                        ? '1 alerte ignorée'
                        : '$dismissedCount alertes ignorées',
                    style: AppTypography.caption(
                      color: AppColors.mutedForeground,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    // 403 : relancer ne changera rien (même politique qu'`OwnerDetailScreen`).
    final canRetry = _errorType != ApiExceptionType.forbidden;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Impossible de charger les alertes',
              textAlign: TextAlign.center,
              style: AppTypography.titleScreen(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall(color: AppColors.mutedForeground),
            ),
            if (canRetry) ...[
              const SizedBox(height: 20),
              AppButton.primary(
                label: 'Réessayer',
                onPressed: _load,
                isFullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<Alerte> alertes) {
    final list = _filtered(alertes);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filtres horizontaux
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: List.generate(_filters.length, (index) {
              final isSelected = _activeFilter == index;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(_filters[index]),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _activeFilter = index),
                  backgroundColor: AppColors.card,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.foreground,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  showCheckmark: false,
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _refresh,
            child: list.isEmpty
                ? _buildEmpty(
                    alertes.isEmpty
                        ? 'Aucune alerte pour le moment'
                        : 'Aucune alerte dans cette catégorie',
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final alerte = list[index];
                      return _AlerteCard(
                        key: ValueKey(alerte.id),
                        alerte: alerte,
                        dismissing: _dismissing.contains(alerte.id),
                        onDismiss: () => _dismiss(alerte),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  /// Scrollable pour que le pull-to-refresh reste possible quand la liste
  /// est vide.
  Widget _buildEmpty(String message) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.bell_off,
                  size: 48,
                  color: AppColors.mutedForeground.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: AppTypography.bodyMedium(
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AlerteCard extends StatelessWidget {
  const _AlerteCard({
    super.key,
    required this.alerte,
    required this.dismissing,
    required this.onDismiss,
  });

  final Alerte alerte;
  final bool dismissing;
  final VoidCallback onDismiss;

  AppBadgeType _prioriteType(String priorite) {
    switch (priorite) {
      case 'Urgente':
        return AppBadgeType.danger;
      case 'Haute':
        return AppBadgeType.warning;
      case 'Moyenne':
        return AppBadgeType.info;
      default:
        return AppBadgeType.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categorie = alerte.categorie;
    final priorite = alerte.priorite;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icône ronde de catégorie
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: categorie.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(categorie.icon, color: categorie.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            alerte.titre,
                            style: AppTypography.bodyMedium(
                              color: AppColors.foreground,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (priorite != null && priorite.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          AppBadge(
                            label: priorite,
                            type: _prioriteType(priorite),
                          ),
                        ],
                      ],
                    ),
                    if (alerte.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        alerte.description,
                        style: AppTypography.bodySmall(
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: dismissing ? null : onDismiss,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.mutedForeground,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
              ),
              icon: const Icon(LucideIcons.eye_off, size: 14),
              label: const Text(
                'Ignorer',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
