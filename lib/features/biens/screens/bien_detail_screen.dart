import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../models/bien.dart';
import '../../finances/screens/encaisser_screen.dart';

/// Fiche détaillée d'un bien immobilier.
class BienDetailScreen extends StatefulWidget {
  final Bien bien;

  const BienDetailScreen({super.key, required this.bien});

  @override
  State<BienDetailScreen> createState() => _BienDetailScreenState();
}

class _BienDetailScreenState extends State<BienDetailScreen> {
  int _selectedTabIndex = 0; // 0: Aperçu & Lots, 1: Finances, 2: Documents

  @override
  Widget build(BuildContext context) {
    final bien = widget.bien;
    final isOccupe = bien.status == BienStatus.occupe;

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
                      bien.name,
                      style: AppTypography.titleScreen(fontSize: 20),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lien du bien copié'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: Icon(
                      LucideIcons.share_2,
                      size: 20,
                      color: AppColors.foreground,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Édition du bien disponible'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: Icon(
                      LucideIcons.pencil,
                      size: 20,
                      color: AppColors.foreground,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                children: [
                  // Carte Visuelle Hero
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: AppColors.positiveSoft,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                      image: bien.imageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(bien.imageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: Stack(
                      children: [
                        if (bien.imageUrl == null)
                          Center(
                            child: Icon(
                              LucideIcons.building,
                              size: 64,
                              color: AppColors.primary.withValues(alpha: 0.35),
                            ),
                          ),
                        // Badge Statut
                        Positioned(
                          top: 14,
                          left: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isOccupe
                                  ? AppColors.primary
                                  : AppColors.card,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isOccupe
                                    ? Colors.transparent
                                    : AppColors.border,
                              ),
                              boxShadow: AppShadows.soft,
                            ),
                            child: Text(
                              bien.status.label,
                              style: AppTypography.caption(
                                color: isOccupe
                                    ? Colors.white
                                    : AppColors.foreground,
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Titre & Type
                  Text(
                    bien.name,
                    style: AppTypography.titleScreen(fontSize: 22),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.map_pin,
                        size: 14,
                        color: AppColors.mutedForeground,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        bien.type,
                        style: AppTypography.bodySmall(
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3 Cartes Métriques Clés
                  Row(
                    children: [
                      _MetricBox(
                        label: 'LOYER MENSUEL',
                        value: bien.price.replaceAll(' / mois', ''),
                        subtext: '/ mois',
                        highlight: true,
                      ),
                      const SizedBox(width: 8),
                      _MetricBox(
                        label: 'LOTS',
                        value: isOccupe ? '3 / 3' : '0 / 1',
                        subtext: 'occupés',
                      ),
                      const SizedBox(width: 8),
                      _MetricBox(
                        label: 'OCCUPATION',
                        value: isOccupe ? '100%' : '0%',
                        subtext: 'taux actuel',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Onglets locaux
                  Row(
                    children: [
                      _LocalTab(
                        label: 'Lots & Baux',
                        isSelected: _selectedTabIndex == 0,
                        onTap: () => setState(() => _selectedTabIndex = 0),
                      ),
                      const SizedBox(width: 8),
                      _LocalTab(
                        label: 'Finances',
                        isSelected: _selectedTabIndex == 1,
                        onTap: () => setState(() => _selectedTabIndex = 1),
                      ),
                      const SizedBox(width: 8),
                      _LocalTab(
                        label: 'Documents',
                        isSelected: _selectedTabIndex == 2,
                        onTap: () => setState(() => _selectedTabIndex = 2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Contenu selon l'onglet
                  if (_selectedTabIndex == 0) ...[
                    // Lots & Locataires
                    _CardContainer(
                      title: 'LOTS ET LOCATAIRES ACTUELS',
                      children: [
                        _LotItem(
                          lotName: 'Lot 101 · Étage 1',
                          tenantName: isOccupe
                              ? 'Yacine Diop'
                              : 'Aucun occupant',
                          rent: bien.price,
                          isOccupe: isOccupe,
                          statusNote: isOccupe
                              ? 'Loyer à jour'
                              : 'Disponible à la location',
                        ),
                        if (isOccupe) ...[
                          Divider(color: AppColors.border, height: 1),
                          _LotItem(
                            lotName: 'Lot 102 · Rez-de-chaussée',
                            tenantName: 'Koffi Mensah',
                            rent: '140 000 F / mois',
                            isOccupe: true,
                            statusNote: 'Retard de 12 jours',
                            isLate: true,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Caractéristiques du bien
                    _CardContainer(
                      title: 'CARACTÉRISTIQUES DU BIEN',
                      children: [
                        _DetailRow(
                          label: 'Type de bien',
                          value: bien.type.split('·').first.trim(),
                        ),
                        Divider(color: AppColors.border, height: 1),
                        _DetailRow(
                          label: 'Localisation',
                          value: bien.name.split('—').last.trim(),
                        ),
                        Divider(color: AppColors.border, height: 1),
                        _DetailRow(
                          label: 'Propriétaire',
                          value: 'Mamadou Camara',
                        ),
                        Divider(color: AppColors.border, height: 1),
                        _DetailRow(
                          label: 'Mandat de gestion',
                          value: 'Exclusif · #MD-2024-08',
                        ),
                      ],
                    ),
                  ] else if (_selectedTabIndex == 1) ...[
                    // Finances
                    _CardContainer(
                      title: 'DERNIERS PAIEMENTS REÇUS',
                      children: [
                        _FinanceMiniRow(
                          title: 'Loyer Septembre 2026',
                          tenant: 'Yacine Diop',
                          date: '05 Sept. 2026',
                          amount: '+ 185 000 FCFA',
                          isPositive: true,
                        ),
                        Divider(color: AppColors.border, height: 1),
                        _FinanceMiniRow(
                          title: 'Entretien plomberie',
                          tenant: 'Artisan Moussa',
                          date: '28 Août 2026',
                          amount: '- 25 000 FCFA',
                          isPositive: false,
                        ),
                      ],
                    ),
                  ] else ...[
                    // Documents
                    _CardContainer(
                      title: 'DOCUMENTS DU BIEN',
                      children: [
                        _DocMiniRow(
                          title: 'Bail de location — Lot 101',
                          date: '01 Janvier 2025',
                        ),
                        Divider(color: AppColors.border, height: 1),
                        _DocMiniRow(
                          title: 'Titre Foncier & Plan cadastral',
                          date: '15 Mars 2022',
                        ),
                        Divider(color: AppColors.border, height: 1),
                        _DocMiniRow(
                          title: 'État des lieux d\'entrée',
                          date: '03 Janvier 2025',
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Barre d'action fixe en bas
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border(top: BorderSide(color: AppColors.border)),
                boxShadow: AppShadows.soft,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Historique complet des états des lieux',
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
                      icon: const Icon(LucideIcons.file_text, size: 16),
                      label: const Text('Baux & Docs'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EncaisserScreen(
                              initialBien: bien.name,
                              initialMontant: bien.price.replaceAll(
                                RegExp(r'[^0-9]'),
                                '',
                              ),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      icon: const Icon(
                        LucideIcons.circle_dollar_sign,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Encaisser un loyer',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final String subtext;
  final bool highlight;

  const _MetricBox({
    required this.label,
    required this.value,
    required this.subtext,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: highlight ? AppColors.positiveSoft : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: highlight
                ? AppColors.primary.withValues(alpha: 0.2)
                : AppColors.border,
          ),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.labelUppercase(
                fontSize: 9,
                color: AppColors.mutedForeground,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTypography.titleScreen(
                fontSize: 16,
                color: highlight ? AppColors.primary : AppColors.foreground,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtext,
              style: AppTypography.caption(color: AppColors.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocalTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LocalTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.foreground,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardContainer extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _CardContainer({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.labelUppercase(
              color: AppColors.mutedForeground,
              fontSize: 10.5,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _LotItem extends StatelessWidget {
  final String lotName;
  final String tenantName;
  final String rent;
  final bool isOccupe;
  final String statusNote;
  final bool isLate;

  const _LotItem({
    required this.lotName,
    required this.tenantName,
    required this.rent,
    required this.isOccupe,
    required this.statusNote,
    this.isLate = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isOccupe
                  ? (isLate
                        ? AppColors.warning.withValues(alpha: 0.12)
                        : AppColors.positiveSoft)
                  : AppColors.border.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOccupe ? LucideIcons.user : LucideIcons.key_round,
              size: 18,
              color: isOccupe
                  ? (isLate ? AppColors.warning : AppColors.primary)
                  : AppColors.mutedForeground,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lotName,
                  style: AppTypography.bodyMedium(color: AppColors.foreground)
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '$tenantName · $statusNote',
                  style: AppTypography.caption(
                    color: isLate
                        ? AppColors.warning
                        : AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          Text(
            rent,
            style: AppTypography.bodySmall(color: AppColors.foreground)
                .copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall(color: AppColors.mutedForeground),
          ),
          Text(
            value,
            style: AppTypography.bodySmall(color: AppColors.foreground)
                .copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _FinanceMiniRow extends StatelessWidget {
  final String title;
  final String tenant;
  final String date;
  final String amount;
  final bool isPositive;

  const _FinanceMiniRow({
    required this.title,
    required this.tenant,
    required this.date,
    required this.amount,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyMedium(color: AppColors.foreground)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                '$tenant · $date',
                style: AppTypography.caption(color: AppColors.mutedForeground),
              ),
            ],
          ),
          Text(
            amount,
            style: AppTypography.bodyMedium(
              color: isPositive ? AppColors.positive : AppColors.foreground,
            ).copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _DocMiniRow extends StatelessWidget {
  final String title;
  final String date;

  const _DocMiniRow({required this.title, required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(LucideIcons.file_text, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodySmall(color: AppColors.foreground)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  date,
                  style: AppTypography.caption(
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            LucideIcons.download,
            size: 16,
            color: AppColors.mutedForeground,
          ),
        ],
      ),
    );
  }
}
