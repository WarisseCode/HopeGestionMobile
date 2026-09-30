import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../models/document.dart';
import '../models/element_document.dart';

/// Icône d'une catégorie de document (liste et fiche).
IconData iconeCategorie(CategorieDocument categorie) => switch (categorie) {
  CategorieDocument.bail => LucideIcons.file_pen,
  CategorieDocument.quittance => LucideIcons.receipt,
  CategorieDocument.facture => LucideIcons.file_text,
  CategorieDocument.identite => LucideIcons.id_card,
  CategorieDocument.proprietaire => LucideIcons.user_round,
  CategorieDocument.genere => LucideIcons.file_check,
  CategorieDocument.autre => LucideIcons.file,
};

/// Ligne d'un document dans la liste de `DocumentsScreen`.
class DocumentRow extends StatelessWidget {
  const DocumentRow({super.key, required this.element, this.onTap});

  final ElementDocument element;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.positiveSoft,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  iconeCategorie(element.categorie),
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    element.titre,
                    style: AppTypography.body(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (element.sousTitre.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      element.sousTitre,
                      style: AppTypography.bodySmall(
                        color: AppColors.mutedForeground,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              LucideIcons.chevron_right,
              size: 18,
              color: AppColors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}
