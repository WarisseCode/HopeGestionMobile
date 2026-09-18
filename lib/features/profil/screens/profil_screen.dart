import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../../auth/screens/login_screen.dart';
import '../../biens/models/bien.dart';
import '../../biens/models/biens_repository.dart';
import '../../locataires/models/contacts_repository.dart';
import '../../parametres/screens/parametres_screen.dart';

const String _currentUserName = 'Warisse OTCHADE';
const String _currentUserInitials = 'WO';

/// Écran du profil utilisateur (Gestionnaire immobilier)
class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Déconnexion',
          style: AppTypography.titleScreen(fontSize: 19),
        ),
        content: Text(
          'Voulez-vous vraiment vous déconnecter de HopeGestion ?',
          style: AppTypography.bodySmall(color: AppColors.mutedForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: AppTypography.bodySmall(color: AppColors.mutedForeground),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Redirige vers l'écran de Login et vide la pile de navigation
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Se déconnecter',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                  Text(
                    'Mon Profil',
                    style: AppTypography.titleScreen(fontSize: 22),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListenableBuilder(
                listenable: Listenable.merge([
                  BiensRepository.instance,
                  ContactsRepository.instance,
                ]),
                builder: (context, _) {
                  final biens = BiensRepository.instance.items;
                  final totalBiens = biens.length;
                  final occupes = biens
                      .where((b) => b.status == BienStatus.occupe)
                      .length;
                  final occupationRate = totalBiens == 0
                      ? 0
                      : ((occupes / totalBiens) * 100).round();
                  final tenants = ContactsRepository.instance.tenantCount;

                  return ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    children: [
                      // Carte Profil principale
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                          boxShadow: AppShadows.soft,
                        ),
                        child: Column(
                          children: [
                            // Avatar avec badge gestionnaire
                            Stack(
                              children: [
                                const AppAvatar(
                                  initials: _currentUserInitials,
                                  size: 80,
                                  isCircle: true,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.card,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      LucideIcons.shield_check,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            Text(
                              _currentUserName,
                              style: AppTypography.titleScreen(fontSize: 20),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Gestionnaire de Patrimoine Immobilier',
                              style: AppTypography.caption(
                                color: AppColors.primary,
                              ).copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Cabinet Hope Gestion · Cotonou, Bénin',
                              style: AppTypography.bodySmall(
                                color: AppColors.mutedForeground,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // 3 Statistiques d'activité
                            Row(
                              children: [
                                _ProfileStatCard(
                                  label: 'BIENS GÉRÉS',
                                  value: '$totalBiens',
                                  icon: LucideIcons.building,
                                ),
                                const SizedBox(width: 8),
                                _ProfileStatCard(
                                  label: 'LOCATAIRES',
                                  value: '$tenants',
                                  icon: LucideIcons.users,
                                ),
                                const SizedBox(width: 8),
                                _ProfileStatCard(
                                  label: 'OCCUPATION',
                                  value: '$occupationRate%',
                                  icon: LucideIcons.chart_pie,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Menu Général
                      _ProfileMenuContainer(
                        children: [
                          _ProfileMenuItem(
                            icon: LucideIcons.user,
                            title: 'Informations personnelles',
                            subtitle:
                                'contact@hopegestion.com · +229 97 00 00 00',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Édition des coordonnées'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                          const _ProfileDivider(),
                          _ProfileMenuItem(
                            icon: LucideIcons.settings,
                            title: 'Paramètres de l\'application',
                            subtitle: 'Devise, notifications, biométrie',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ParametresScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Support & Déconnexion
                      _ProfileMenuContainer(
                        children: [
                          _ProfileMenuItem(
                            icon: LucideIcons.info,
                            title: 'Aide & Assistance Hope Gestion',
                            subtitle: 'FAQ, contact support et assistance',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Support Hope Gestion : support@hopegestion.com',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                          const _ProfileDivider(),
                          _ProfileMenuItem(
                            icon: LucideIcons.log_out,
                            title: 'Se déconnecter',
                            titleColor: AppColors.warning,
                            iconColor: AppColors.warning,
                            onTap: () => _confirmLogout(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ProfileStatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.positiveSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: AppTypography.titleScreen(
                fontSize: 16,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.labelUppercase(
                fontSize: 9,
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuContainer extends StatelessWidget {
  final List<Widget> children;

  const _ProfileMenuContainer({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(children: children),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? titleColor;
  final Color? iconColor;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.titleColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AppColors.primary;

    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: effectiveIconColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: effectiveIconColor, size: 19),
      ),
      title: Text(
        title,
        style: AppTypography.bodyMedium(
          color: titleColor ?? AppColors.foreground,
        ).copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTypography.caption(color: AppColors.mutedForeground),
            )
          : null,
      trailing: Icon(
        LucideIcons.chevron_right,
        size: 18,
        color: AppColors.mutedForeground,
      ),
      onTap: onTap,
    );
  }
}

class _ProfileDivider extends StatelessWidget {
  const _ProfileDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.border,
      indent: 58,
    );
  }
}
