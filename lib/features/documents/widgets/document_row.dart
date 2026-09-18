import 'package:flutter/material.dart';

import '../../../core/design_system.dart';
import '../models/document_item.dart';

/// Ligne représentant un document dans la section « RÉCENTS »
class DocumentRow extends StatelessWidget {
  const DocumentRow({super.key, required this.document, this.onTap});

  final DocumentItem document;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Pastille circulaire vert menthe avec icône
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.positiveSoft,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(document.icon, size: 20, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 14),

            // Titre & Bien rattaché
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.title,
                    style: AppTypography.body(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    document.property,
                    style: AppTypography.bodySmall(
                      color: AppColors.mutedForeground,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Badge de statut à droite
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: document.status.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                document.status.label,
                style: AppTypography.kpiNote(
                  color: document.status.textColor,
                  fontSize: 11,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
