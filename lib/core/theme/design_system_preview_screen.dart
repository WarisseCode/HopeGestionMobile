import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../design_system.dart';

/// Écran catalogue / vitrine du Design System HopeGestion Mobile
/// Permet de vérifier visuellement la conformité avec les 21 maquettes
class DesignSystemPreviewScreen extends StatefulWidget {
  const DesignSystemPreviewScreen({super.key});

  @override
  State<DesignSystemPreviewScreen> createState() =>
      _DesignSystemPreviewScreenState();
}

class _DesignSystemPreviewScreenState extends State<DesignSystemPreviewScreen> {
  int _selectedTab = 0;
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Design System',
          style: AppTypography.titleScreen(fontSize: 19),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.bell, size: 20),
            onPressed: () {},
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: AppAvatar(initials: 'AS', size: 34),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              // Section Branding & Typo
              _buildSectionTitle('1. Typographie & Marque'),
              const SizedBox(height: 8),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HopeGestion',
                      style: AppTypography.displayBrand(
                        color: AppColors.primaryStrong,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'La gestion immobilière, simplement.',
                      style: AppTypography.bodySmall(),
                    ),
                    const Divider(height: 24),
                    Text(
                      'Titre écran (21px) : Bonjour, Awa Sarr',
                      style: AppTypography.titleScreen(),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Titre section (17px) : Mes biens récents',
                      style: AppTypography.titleSection(),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Corps de texte (13.5px) : Suivi des paiements et des baux.',
                      style: AppTypography.body(),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'LUNDI 14 AVRIL · FLUX 7 JOURS',
                      style: AppTypography.labelUppercase(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section Palette de Couleurs
              _buildSectionTitle('2. Palette de Couleurs'),
              const SizedBox(height: 8),
              AppCard(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildColorSwatch('Primary', AppColors.primary),
                    _buildColorSwatch(
                      'Primary Strong',
                      AppColors.primaryStrong,
                    ),
                    _buildColorSwatch(
                      'Secondary',
                      AppColors.secondary,
                      isDarkText: true,
                    ),
                    _buildColorSwatch('Positive', AppColors.positive),
                    _buildColorSwatch(
                      'Positive Soft',
                      AppColors.positiveSoft,
                      isDarkText: true,
                    ),
                    _buildColorSwatch('Warning', AppColors.warning),
                    _buildColorSwatch(
                      'Warning Soft',
                      AppColors.warningSoft,
                      isDarkText: true,
                    ),
                    _buildColorSwatch('Foreground', AppColors.foreground),
                    _buildColorSwatch('Muted Text', AppColors.mutedForeground),
                    _buildColorSwatch(
                      'Border',
                      AppColors.border,
                      isDarkText: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section Cartes KPIs (Grille de 3 comme sur la maquette 01-dashboard.png)
              _buildSectionTitle('3. Cartes KPI (Dashboard)'),
              const SizedBox(height: 8),
              const Row(
                children: [
                  AppKpiCard(
                    label: 'Encaiss.',
                    value: '2,45 M',
                    note: '+12% ce mois',
                    isPositiveNote: true,
                  ),
                  SizedBox(width: 8),
                  AppKpiCard(
                    label: 'Dépenses',
                    value: '890 K',
                    note: '24% du CA',
                  ),
                  SizedBox(width: 8),
                  AppKpiCard(
                    label: 'Impayés',
                    value: '320 K',
                    note: '3 factures',
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Section Badges de Statuts
              _buildSectionTitle('4. Badges de Statuts'),
              const SizedBox(height: 8),
              const AppCard(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppBadge.positive('Payé'),
                    AppBadge.positive('OCCUPÉ', isUppercase: true),
                    AppBadge.warning('En attente'),
                    AppBadge.warning('À relancer'),
                    AppBadge.danger('Impayé'),
                    AppBadge.neutral('VACANT', isUppercase: true),
                    AppBadge.info('Nouveau'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section Boutons
              _buildSectionTitle('5. Boutons & Actions'),
              const SizedBox(height: 8),
              AppCard(
                child: Column(
                  children: [
                    AppButton.primary(
                      label: 'Se connecter',
                      trailingIcon: Icon(
                        LucideIcons.arrow_right,
                        size: 18,
                        color: AppColors.primaryForeground,
                      ),
                      onPressed: () {},
                    ),
                    const SizedBox(height: 10),
                    AppButton.secondary(
                      label: 'Continuer avec Google',
                      icon: Icon(
                        LucideIcons.globe,
                        size: 18,
                        color: AppColors.foreground,
                      ),
                      onPressed: () {},
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton.ghost(
                            label: 'Annuler',
                            onPressed: () {},
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppButton.danger(
                            label: 'Supprimer',
                            icon: Icon(
                              LucideIcons.trash,
                              size: 16,
                              color: AppColors.primaryForeground,
                            ),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section Formulaires & Saisie
              _buildSectionTitle('6. Saisie & Formulaires'),
              const SizedBox(height: 8),
              AppCard(
                child: Column(
                  children: [
                    AppTextField(
                      label: 'Adresse e-mail',
                      hintText: 'votre@email.com',
                      prefixIcon: Icon(
                        LucideIcons.mail,
                        size: 18,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                    SizedBox(height: 12),
                    AppTextField(
                      label: 'Mot de passe',
                      hintText: '••••••••',
                      obscureText: true,
                      prefixIcon: Icon(
                        LucideIcons.lock,
                        size: 18,
                        color: AppColors.mutedForeground,
                      ),
                      suffixIcon: Icon(
                        LucideIcons.eye,
                        size: 18,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section Raccourcis Création (Grille 4 actions de la maquette)
              _buildSectionTitle('7. Raccourcis Créer (4 actions)'),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildQuickActionButton(
                    label: 'Bien',
                    icon: LucideIcons.building,
                    onTap: () {},
                  ),
                  const SizedBox(width: 8),
                  _buildQuickActionButton(
                    label: 'Locataire',
                    icon: LucideIcons.user_plus,
                    onTap: () {},
                  ),
                  const SizedBox(width: 8),
                  _buildQuickActionButton(
                    label: 'Facture',
                    icon: LucideIcons.file_text,
                    onTap: () {},
                  ),
                  const SizedBox(width: 8),
                  _buildQuickActionButton(
                    label: 'Quittance',
                    icon: LucideIcons.receipt,
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),

          // Floating Action Button
          Positioned(
            right: 24,
            bottom: 92,
            child: AppFab(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Action Rapide cliquée !'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),

          // Barre de navigation flottante
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AppBottomBar(
              currentIndex: _selectedTab,
              onTap: (index) {
                setState(() => _selectedTab = index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.titleSection(color: AppColors.foreground),
    );
  }

  Widget _buildColorSwatch(
    String name,
    Color color, {
    bool isDarkText = false,
  }) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.borderSm,
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDarkText
                  ? AppColors.foreground
                  : AppColors.primaryForeground,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.bodyMedium(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
