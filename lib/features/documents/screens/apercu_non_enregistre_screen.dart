import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../models/document_item.dart';

/// Aperçu d'un document saisi dans un écran de création **non branché au
/// backend** (contrat, état des lieux, quittance — phase 4.6, étape A :
/// lecture seule). Reprend la feuille A4 de l'ancien `DocumentDetailScreen`,
/// sans ses faux boutons de partage/téléchargement/impression : rien n'a
/// été enregistré, il n'existe aucun fichier à partager.
class ApercuNonEnregistreScreen extends StatelessWidget {
  final DocumentItem document;

  const ApercuNonEnregistreScreen({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      LucideIcons.arrow_left,
                      color: AppColors.foreground,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      document.title,
                      style: AppTypography.titleScreen(fontSize: 20),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                children: [
                  const AppWarningBanner.mockData(),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 1.5),
                      boxShadow: AppShadows.soft,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Center(
                                child: Text(
                                  'H',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'HOPE GESTION',
                                style: AppTypography.labelUppercase(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.warning,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'APERÇU',
                                style: AppTypography.caption(
                                  color: AppColors.warning,
                                  fontSize: 8.5,
                                ).copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Divider(color: AppColors.border, height: 1),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            document.title.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: AppTypography.titleScreen(fontSize: 17),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            'Émis pour : ${document.property}',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall(
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.muted,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              _Ligne(
                                label: 'Bien rattaché',
                                value: document.property,
                              ),
                              const SizedBox(height: 6),
                              _Ligne(
                                label: "Date d'établissement",
                                value:
                                    '${document.date.day.toString().padLeft(2, '0')}/'
                                    '${document.date.month.toString().padLeft(2, '0')}/'
                                    '${document.date.year}',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Ligne extends StatelessWidget {
  final String label;
  final String value;

  const _Ligne({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: AppTypography.caption(color: AppColors.mutedForeground),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption(
              color: AppColors.foreground,
            ).copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
