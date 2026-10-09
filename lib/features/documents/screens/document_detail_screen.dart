import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/config/app_config.dart';
import '../../../core/design_system.dart';
import '../../finances/models/finance_file_opener.dart';
import '../../finances/models/finance_format.dart';
import '../models/document.dart';
import '../models/element_document.dart';
import '../widgets/document_row.dart';

/// Fiche d'un document réel (phase 4.6, étape A — lecture seule) : un
/// fichier de `GET /api/documents` (bouton « Ouvrir ») ou une quittance
/// manuelle de `GET /api/quittances` (données seules : pas de fichier
/// serveur, le web génère son PDF côté navigateur).
class DocumentDetailScreen extends StatelessWidget {
  const DocumentDetailScreen({super.key, required this.element});

  final ElementDocument element;

  @override
  Widget build(BuildContext context) {
    final element = this.element;
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
                    tooltip: 'Retour',
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
                      element.categorie.libelle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleScreen(fontSize: 20),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  _EnTete(element: element),
                  const SizedBox(height: 16),
                  switch (element) {
                    ElementFichier(:final document) => _FicheFichier(
                      document: document,
                    ),
                    ElementQuittanceManuelle(:final quittance) =>
                      _FicheQuittance(quittance: quittance),
                  },
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnTete extends StatelessWidget {
  const _EnTete({required this.element});

  final ElementDocument element;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.positiveSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              iconeCategorie(element.categorie),
              size: 22,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  element.titre,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                AppBadge.neutral(element.categorie.libelle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FicheFichier extends StatelessWidget {
  const _FicheFichier({required this.document});

  final Document document;

  @override
  Widget build(BuildContext context) {
    final url = document.url;
    final lignes = <(String, String)>[
      ('Catégorie', _libelleCategorie(document)),
      if (document.createdAt != null)
        ('Ajouté le', formatDateLongue(document.createdAt!)),
      if (document.tailleOctets != null)
        ('Taille', formatTaille(document.tailleOctets!)),
      if (document.typeMime != null)
        ('Format', libelleFormat(document.typeMime!)),
      if (document.entiteLiee != null) ('Lié à', document.entiteLiee!),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Details(lignes: lignes),
        if (document.description != null &&
            document.description != document.nom) ...[
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DESCRIPTION',
                  style: AppTypography.labelUppercase(
                    color: AppColors.mutedForeground,
                    fontSize: 10.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(document.description!, style: AppTypography.bodySmall()),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        if (url != null)
          AppButton.primary(
            label: 'Ouvrir',
            icon: Icon(
              LucideIcons.external_link,
              size: 18,
              color: AppColors.primaryForeground,
            ),
            onPressed: () =>
                ouvrirFichierOuCopier(context, AppConfig.resolveFileUrl(url)),
          )
        else
          const AppInfoBanner(
            text: "Aucun fichier n'est associé à ce document.",
          ),
      ],
    );
  }

  /// Libellé de la catégorie ; valeur brute du serveur si elle n'est pas
  /// reconnue (« Autre (contrat_signe) »), pour ne rien masquer.
  static String _libelleCategorie(Document d) {
    final brute = d.categorieBrute;
    if (d.categorie == CategorieDocument.autre &&
        brute != null &&
        brute.toLowerCase() != 'autre') {
      return 'Autre ($brute)';
    }
    return d.categorie.libelle;
  }
}

class _FicheQuittance extends StatelessWidget {
  const _FicheQuittance({required this.quittance});

  final QuittanceManuelle quittance;

  @override
  Widget build(BuildContext context) {
    final lignes = <(String, String)>[
      if (quittance.numero != null) ('Numéro', quittance.numero!),
      if (quittance.locataireNom != null)
        ('Locataire', quittance.locataireNom!),
      if (quittance.proprietaireNom != null)
        ('Propriétaire', quittance.proprietaireNom!),
      if (quittance.bien != null) ('Bien', quittance.bien!),
      if (quittance.periode != null) ('Période', quittance.periode!),
      if (quittance.montant != null)
        ('Montant', formatMontant(quittance.montant!)),
      if (quittance.dateEmission != null)
        ("Date d'émission", formatDateLongue(quittance.dateEmission!)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Details(lignes: lignes),
        const SizedBox(height: 16),
        const AppInfoBanner(
          text: 'Le PDF de cette quittance est disponible sur '
              "l'application web.",
        ),
      ],
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.lignes});

  final List<(String, String)> lignes;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          for (var i = 0; i < lignes.length; i++) ...[
            if (i > 0) Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      lignes[i].$1,
                      style: AppTypography.bodySmall(
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      lignes[i].$2,
                      textAlign: TextAlign.end,
                      style: AppTypography.bodySmall(
                        color: AppColors.foreground,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// « PDF », « Image JPEG », sinon le type MIME tel quel.
String libelleFormat(String typeMime) {
  final t = typeMime.toLowerCase();
  if (t == 'application/pdf') return 'PDF';
  if (t.startsWith('image/')) {
    final sousType = t.substring(6).replaceAll('jpg', 'jpeg').toUpperCase();
    return 'Image $sousType';
  }
  return typeMime;
}
