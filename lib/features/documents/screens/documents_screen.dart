import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../../dashboard/widgets/quick_action_sheet.dart';
import '../models/document_item.dart';
import '../widgets/document_kpi_card.dart';
import '../widgets/document_row.dart';
import 'document_detail_screen.dart';

/// Écran principal des Documents
/// Conforme à la maquette 06-documents.png
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  DocumentCategory? _selectedCategory;
  late List<DocumentItem> _documents;

  @override
  void initState() {
    super.initState();
    _documents = DocumentItem.mockList;
  }

  List<DocumentItem> get _filteredDocuments {
    if (_selectedCategory == null) return _documents;
    return _documents.where((d) => d.category == _selectedCategory).toList();
  }

  void _onKpiTap(DocumentCategory category) {
    setState(() {
      if (_selectedCategory == category) {
        _selectedCategory = null; // Désélectionner pour afficher tout
      } else {
        _selectedCategory = category;
      }
    });
  }

  void _openQuickActions() {
    QuickActionSheet.showAndNavigate(context);
  }

  @override
  Widget build(BuildContext context) {
    final displayedDocs = _filteredDocuments;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête : Compteur total + Titre + Bouton d'ajout vert
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${DocumentItem.totalDocuments} DOCUMENTS',
                            style: AppTypography.labelUppercase(
                              color: AppColors.mutedForeground,
                              fontSize: 11,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Documents',
                            style: AppTypography.titleScreen(fontSize: 26),
                          ),
                        ],
                      ),
                      // Bouton d'ajout vert en haut à droite
                      GestureDetector(
                        onTap: _openQuickActions,
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
                          child: const Center(
                            child: Icon(
                              LucideIcons.plus,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 3 Cartes KPIs en ligne (Quittances, Contrats, Factures)
                  Row(
                    children: [
                      DocumentKpiCard(
                        label: 'QUITTANCES',
                        count: DocumentItem.quittancesCount,
                        isSelected:
                            _selectedCategory == DocumentCategory.quittance,
                        onTap: () => _onKpiTap(DocumentCategory.quittance),
                      ),
                      const SizedBox(width: 10),
                      DocumentKpiCard(
                        label: 'CONTRATS',
                        count: DocumentItem.contratsCount,
                        isSelected:
                            _selectedCategory == DocumentCategory.contrat,
                        onTap: () => _onKpiTap(DocumentCategory.contrat),
                      ),
                      const SizedBox(width: 10),
                      DocumentKpiCard(
                        label: 'FACTURES',
                        count: DocumentItem.facturesCount,
                        isSelected:
                            _selectedCategory == DocumentCategory.facture,
                        onTap: () => _onKpiTap(DocumentCategory.facture),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Section RÉCENTS
                  Container(
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _selectedCategory == null
                                    ? 'RÉCENTS'
                                    : 'RÉCENTS (${_selectedCategory!.name.toUpperCase()})',
                                style: AppTypography.labelUppercase(
                                  color: AppColors.mutedForeground,
                                  fontSize: 10.5,
                                  letterSpacing: 0.8,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_selectedCategory != null)
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedCategory = null),
                                child: Text(
                                  'Tout afficher',
                                  style: AppTypography.kpiNote(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                  ).copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        if (displayedDocs.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'Aucun document dans cette catégorie',
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
                            itemCount: displayedDocs.length,
                            separatorBuilder: (_, _) => Divider(
                              height: 1,
                              thickness: 0.8,
                              color: AppColors.border,
                            ),
                            itemBuilder: (context, index) {
                              final doc = displayedDocs[index];
                              return DocumentRow(
                                document: doc,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          DocumentDetailScreen(document: doc),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
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
