import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../../../core/network/api_exception.dart';
import '../../dashboard/widgets/quick_action_sheet.dart';
import '../../finances/widgets/finances_skeleton.dart';
import '../data/documents_repository.dart';
import '../data/documents_results.dart';
import '../models/document.dart';
import '../models/element_document.dart';
import '../widgets/document_row.dart';
import 'document_detail_screen.dart';

/// Écran Documents (phase 4.6, étape A — lecture seule) : fichiers de
/// `GET /api/documents` et quittances manuelles de `GET /api/quittances`,
/// fusionnés par [ElementDocument.fusionner]. Les quittances de paiement
/// restent dans Finances (voir [ElementDocument]).
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  /// `null` : toutes les catégories.
  CategorieDocument? _filtre;

  bool _loading = true;
  String? _error;

  /// Une seule des deux sources refusée (403) : la liste de l'autre est
  /// affichée, avec cette mention.
  String? _avertissement;
  List<ElementDocument> _elements = const [];

  /// Numéro de la dernière requête : une réponse dépassée est ignorée.
  int _requete = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text);
    });
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final requete = ++_requete;
    setState(() {
      _loading = true;
      _error = null;
    });
    final repo = DocumentsRepository.instance;
    final (documents, quittances) = await (
      repo.listDocuments(),
      repo.listQuittancesManuelles(),
    ).wait;
    if (!mounted || requete != _requete) return;
    setState(() {
      _loading = false;
      _avertissement = null;
      switch ((documents, quittances)) {
        case (
          DocumentsListSuccess(items: final docs),
          QuittancesManuellesSuccess(items: final quits),
        ):
          _elements = ElementDocument.fusionner(docs, quits);
        case (
          DocumentsListSuccess(items: final docs),
          QuittancesManuellesFailure(type: ApiExceptionType.forbidden),
        ):
          _elements = ElementDocument.fusionner(docs, const []);
          _avertissement =
              'Les quittances manuelles ne sont pas accessibles avec '
              'votre rôle.';
        case (
          DocumentsListFailure(type: ApiExceptionType.forbidden),
          QuittancesManuellesSuccess(items: final quits),
        ):
          _elements = ElementDocument.fusionner(const [], quits);
          _avertissement =
              'Les fichiers déposés ne sont pas accessibles avec votre rôle.';
        case (
          DocumentsListFailure(type: ApiExceptionType.forbidden),
          QuittancesManuellesFailure(type: ApiExceptionType.forbidden),
        ):
          _error = "Vous n'avez pas accès aux documents.";
        case (DocumentsListFailure(:final message), _):
          _error = message;
        case (_, QuittancesManuellesFailure(:final message)):
          _error = message;
      }
      // Filtre devenu vide après rechargement : retour à « Tous ».
      if (_filtre != null && !_elements.any((e) => e.categorie == _filtre)) {
        _filtre = null;
      }
    });
  }

  void _openQuickActions() {
    QuickActionSheet.showAndNavigate(context);
  }

  void _openDetail(ElementDocument element) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentDetailScreen(element: element),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Puces : catégories présentes dans la liste réelle ; compteurs
    // calculés après la recherche (ce que la puce affichera une fois
    // sélectionnée), comme l'écran Biens.
    final presentes = CategorieDocument.values
        .where((c) => _elements.any((e) => e.categorie == c))
        .toList();
    final cherches = _elements.where((e) => e.correspondA(_query)).toList();
    final affiches = _filtre == null
        ? cherches
        : cherches.where((e) => e.categorie == _filtre).toList();
    final premierChargement = _loading && _elements.isEmpty;

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
                    _EnTete(
                      total: premierChargement || _error != null
                          ? null
                          : _elements.length,
                      onAjouter: _openQuickActions,
                    ),
                    const SizedBox(height: 16),
                    if (_error != null)
                      _Erreur(message: _error!, onRetry: _load)
                    else ...[
                      AppTextField(
                        controller: _searchController,
                        hintText: 'Rechercher un document...',
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
                      if (presentes.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              AppToggleChip(
                                label: 'Tous (${cherches.length})',
                                isSelected: _filtre == null,
                                onTap: () => setState(() => _filtre = null),
                              ),
                              for (final c in presentes) ...[
                                const SizedBox(width: 8),
                                AppToggleChip(
                                  label:
                                      '${c.libellePluriel} '
                                      '(${cherches.where((e) => e.categorie == c).length})',
                                  isSelected: _filtre == c,
                                  onTap: () => setState(
                                    () => _filtre = _filtre == c ? null : c,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      if (_avertissement != null) ...[
                        const SizedBox(height: 12),
                        AppInfoBanner(text: _avertissement!),
                      ],
                      const SizedBox(height: 16),
                      _SectionListe(
                        titre: _filtre == null
                            ? 'TOUS LES DOCUMENTS'
                            : _filtre!.libellePluriel.toUpperCase(),
                        chargement: premierChargement,
                        elements: affiches,
                        messageVide: _elements.isEmpty
                            ? 'Aucun document pour le moment.'
                            : 'Aucun document ne correspond à votre '
                                  'recherche.',
                        onTap: _openDetail,
                      ),
                    ],
                  ],
                ),
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

class _EnTete extends StatelessWidget {
  const _EnTete({required this.total, required this.onAjouter});

  /// `null` pendant le premier chargement ou en erreur.
  final int? total;
  final VoidCallback onAjouter;

  @override
  Widget build(BuildContext context) {
    final compteur = switch (total) {
      null => 'DOCUMENTS',
      1 => '1 DOCUMENT',
      final n => '$n DOCUMENTS',
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                compteur,
                style: AppTypography.labelUppercase(
                  color: AppColors.mutedForeground,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text('Documents', style: AppTypography.titleScreen(fontSize: 26)),
            ],
          ),
        ),
        Semantics(
          button: true,
          label: 'Créer un document',
          child: GestureDetector(
            onTap: onAjouter,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(LucideIcons.plus, size: 20, color: AppColors.primaryForeground),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionListe extends StatelessWidget {
  const _SectionListe({
    required this.titre,
    required this.chargement,
    required this.elements,
    required this.messageVide,
    required this.onTap,
  });

  final String titre;
  final bool chargement;
  final List<ElementDocument> elements;
  final String messageVide;
  final ValueChanged<ElementDocument> onTap;

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
            chargement ? titre : '$titre · ${elements.length}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelUppercase(
              color: AppColors.mutedForeground,
              fontSize: 10.5,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          if (chargement)
            const FinancesSkeleton.lignes()
          else if (elements.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  messageVide,
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
              itemCount: elements.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, thickness: 0.8, color: AppColors.border),
              itemBuilder: (context, index) {
                final e = elements[index];
                return DocumentRow(
                  key: ValueKey(e.cle),
                  element: e,
                  onTap: () => onTap(e),
                );
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
