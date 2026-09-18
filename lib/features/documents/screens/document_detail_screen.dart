import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../models/document_item.dart';

/// Écran d'aperçu et de partage d'un document (Quittance, Contrat, Facture)
class DocumentDetailScreen extends StatelessWidget {
  final DocumentItem document;

  const DocumentDetailScreen({super.key, required this.document});

  void _shareWhatsApp(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Préparation du partage WhatsApp pour « ${document.title} »',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _download(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Téléchargement de « ${document.title}.pdf » (${document.size})',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = document.status;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
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
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _shareWhatsApp(context),
                    icon: Icon(
                      LucideIcons.share_2,
                      size: 20,
                      color: AppColors.foreground,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _download(context),
                    icon: Icon(
                      LucideIcons.download,
                      size: 20,
                      color: AppColors.foreground,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                children: [
                  // Statut Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: status.backgroundColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status.label.toUpperCase(),
                          style: AppTypography.caption(color: status.textColor)
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        'Réf : ${document.id.toUpperCase()}',
                        style: AppTypography.caption(
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Simulation Visuelle de la feuille PDF (Feuille A4 stylisée)
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
                        // En-tête du document officiel
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
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
                                    Text(
                                      'HOPE GESTION',
                                      style: AppTypography.labelUppercase(
                                        color: AppColors.primary,
                                        fontSize: 12,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Gestion Immobilière Moderne',
                                  style: AppTypography.caption(
                                    color: AppColors.mutedForeground,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                            // Tampon officiel
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.positive,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'VALIDÉ & CERTIFIÉ',
                                style:
                                    AppTypography.caption(
                                      color: AppColors.positive,
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

                        // Titre du document
                        Center(
                          child: Text(
                            document.title.toUpperCase(),
                            style: AppTypography.titleScreen(fontSize: 17),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            'Émis pour : ${document.property}',
                            style: AppTypography.bodySmall(
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Tableau des détails du document
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.positiveSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              _DocDetailRow(
                                label: 'Bien rattaché',
                                value: document.property,
                              ),
                              const SizedBox(height: 6),
                              _DocDetailRow(
                                label: 'Date d\'établissement',
                                value:
                                    '${document.date.day.toString().padLeft(2, '0')}/${document.date.month.toString().padLeft(2, '0')}/${document.date.year}',
                              ),
                              const SizedBox(height: 6),
                              _DocDetailRow(
                                label: 'Format de fichier',
                                value:
                                    'Document PDF certifié (${document.size})',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Cachet et signature
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Le Bailleur / Mandataire',
                                  style: AppTypography.caption(
                                    color: AppColors.mutedForeground,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Hope Gestion SARL',
                                  style: AppTypography.bodySmall(
                                    color: AppColors.foreground,
                                  ).copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Icon(
                                LucideIcons.stamp,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Actions rapides
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _shareWhatsApp(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(
                        LucideIcons.message_circle,
                        size: 20,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Partager via WhatsApp',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _download(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.foreground,
                            side: BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          icon: const Icon(LucideIcons.download, size: 16),
                          label: const Text('Télécharger'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Impression envoyée vers l\'imprimante',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.foreground,
                            side: BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          icon: const Icon(LucideIcons.printer, size: 16),
                          label: const Text('Imprimer'),
                        ),
                      ),
                    ],
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

class _DocDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DocDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.caption(color: AppColors.mutedForeground),
        ),
        Text(
          value,
          style: AppTypography.caption(color: AppColors.foreground)
              .copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
