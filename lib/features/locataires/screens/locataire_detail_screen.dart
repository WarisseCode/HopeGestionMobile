import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../models/contact.dart';
import '../../finances/screens/encaisser_screen.dart';

/// Fiche détaillée d'un locataire ou contact
class LocataireDetailScreen extends StatefulWidget {
  final Contact contact;

  const LocataireDetailScreen({super.key, required this.contact});

  @override
  State<LocataireDetailScreen> createState() => _LocataireDetailScreenState();
}

class _LocataireDetailScreenState extends State<LocataireDetailScreen> {
  int _selectedTab = 0; // 0: Location, 1: Paiements, 2: Pièces

  @override
  Widget build(BuildContext context) {
    final contact = widget.contact;
    final isTenant = contact.type == ContactType.tenant;

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
                      contact.name,
                      style: AppTypography.titleScreen(fontSize: 20),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Appel téléphonique vers ${contact.name}...',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: Icon(
                      LucideIcons.phone,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Ouverture de WhatsApp pour ${contact.name}...',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(
                      LucideIcons.message_circle,
                      size: 20,
                      color: Color(0xFF25D366),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                children: [
                  // Carte Contact Principale
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppShadows.soft,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: AppColors.positiveSoft,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              contact.initials,
                              style: AppTypography.titleScreen(
                                fontSize: 22,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      contact.name,
                                      style: AppTypography.titleScreen(
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isTenant
                                          ? AppColors.positiveSoft
                                          : const Color(0xFFDBEAFE),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isTenant ? 'LOCATAIRE' : 'PROPRIÉTAIRE',
                                      style: AppTypography.caption(
                                        color: isTenant
                                            ? AppColors.primaryStrong
                                            : const Color(0xFF1E40AF),
                                      ).copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                contact.info,
                                style: AppTypography.bodySmall(
                                  color: AppColors.mutedForeground,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '+221 77 123 45 67 · contact@email.com',
                                style: AppTypography.caption(
                                  color: AppColors.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Statut financier si locataire
                  if (isTenant) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.positiveSoft,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.circle_check,
                            color: AppColors.positive,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Situation des loyers : À jour',
                                  style: AppTypography.bodyMedium(
                                    color: AppColors.foreground,
                                  ).copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Prochaine échéance le 05 Octobre 2026',
                                  style: AppTypography.caption(
                                    color: AppColors.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Onglets
                  Row(
                    children: [
                      _ContactTab(
                        label: 'Contrat & Bail',
                        isSelected: _selectedTab == 0,
                        onTap: () => setState(() => _selectedTab = 0),
                      ),
                      const SizedBox(width: 8),
                      _ContactTab(
                        label: 'Paiements',
                        isSelected: _selectedTab == 1,
                        onTap: () => setState(() => _selectedTab = 1),
                      ),
                      const SizedBox(width: 8),
                      _ContactTab(
                        label: 'Pièces & Docs',
                        isSelected: _selectedTab == 2,
                        onTap: () => setState(() => _selectedTab = 2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Contenu onglets
                  if (_selectedTab == 0) ...[
                    _DetailCard(
                      title: 'DÉTAILS DE LA LOCATION',
                      children: [
                        _DetailLine(
                          label: 'Logement occupé',
                          value: contact.info.replaceAll('Locataire · ', ''),
                        ),
                        Divider(color: AppColors.border, height: 1),
                        _DetailLine(
                          label: 'Date de prise d\'effet',
                          value: '01 Janvier 2025',
                        ),
                        Divider(color: AppColors.border, height: 1),
                        _DetailLine(
                          label: 'Loyer mensuel',
                          value: '185 000 FCFA',
                        ),
                        Divider(color: AppColors.border, height: 1),
                        _DetailLine(
                          label: 'Dépôt de garantie',
                          value: '370 000 FCFA (2 mois)',
                        ),
                        Divider(color: AppColors.border, height: 1),
                        _DetailLine(
                          label: 'Mode habituel',
                          value: 'MTN Mobile Money',
                        ),
                      ],
                    ),
                  ] else if (_selectedTab == 1) ...[
                    _DetailCard(
                      title: 'HISTORIQUE DES ENCAISSEMENTS',
                      children: [
                        _PaymentLine(
                          title: 'Loyer Septembre 2026',
                          date: '05 Sept. 2026 · MTN MoMo',
                          amount: '185 000 F',
                          status: 'Validé',
                        ),
                        Divider(color: AppColors.border, height: 1),
                        _PaymentLine(
                          title: 'Loyer Août 2026',
                          date: '03 Août 2026 · Virement',
                          amount: '185 000 F',
                          status: 'Validé',
                        ),
                        Divider(color: AppColors.border, height: 1),
                        _PaymentLine(
                          title: 'Loyer Juillet 2026',
                          date: '04 Juil. 2026 · Espèces',
                          amount: '185 000 F',
                          status: 'Validé',
                        ),
                      ],
                    ),
                  ] else ...[
                    _DetailCard(
                      title: 'DOCUMENTS DU DOSSIER',
                      children: [
                        _DocLine(
                          title: 'Pièce d\'identité (CNI / Passeport)',
                          subtitle: 'Valable jusqu\'en 2029',
                        ),
                        Divider(color: AppColors.border, height: 1),
                        _DocLine(
                          title: 'Contrat de bail signé',
                          subtitle: 'Document officiel PDF',
                        ),
                        Divider(color: AppColors.border, height: 1),
                        _DocLine(
                          title: 'État des lieux d\'entrée contradictoire',
                          subtitle: 'Signé le 02 Janvier 2025',
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Bouton Encaisser en bas
            if (isTenant)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  border: Border(top: BorderSide(color: AppColors.border)),
                  boxShadow: AppShadows.soft,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              EncaisserScreen(initialTenant: contact.name),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(
                      LucideIcons.circle_dollar_sign,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Encaisser un loyer pour ce locataire',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ContactTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ContactTab({
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

class _DetailCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailCard({required this.title, required this.children});

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

class _DetailLine extends StatelessWidget {
  final String label;
  final String value;

  const _DetailLine({required this.label, required this.value});

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

class _PaymentLine extends StatelessWidget {
  final String title;
  final String date;
  final String amount;
  final String status;

  const _PaymentLine({
    required this.title,
    required this.date,
    required this.amount,
    required this.status,
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
                date,
                style: AppTypography.caption(color: AppColors.mutedForeground),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: AppTypography.bodyMedium(color: AppColors.positive)
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                status,
                style: AppTypography.caption(color: AppColors.positive),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocLine extends StatelessWidget {
  final String title;
  final String subtitle;

  const _DocLine({required this.title, required this.subtitle});

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
                  subtitle,
                  style: AppTypography.caption(
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            LucideIcons.chevron_right,
            size: 16,
            color: AppColors.mutedForeground,
          ),
        ],
      ),
    );
  }
}
