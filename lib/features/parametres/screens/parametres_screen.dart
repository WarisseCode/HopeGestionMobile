import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/locale_controller.dart';
import '../../../core/theme/theme_controller.dart';
import '../../onboarding/screens/onboarding_screen.dart';
import '../models/app_settings_repository.dart';

/// Écran des paramètres de l'application HopeGestion
class ParametresScreen extends StatefulWidget {
  const ParametresScreen({super.key});

  @override
  State<ParametresScreen> createState() => _ParametresScreenState();
}

class _ParametresScreenState extends State<ParametresScreen> {
  final _settings = AppSettingsRepository.instance;

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.t('Choisir la langue'),
              style: AppTypography.titleScreen(fontSize: 20),
            ),
            const SizedBox(height: 16),
            for (final lang in AppLanguage.values)
              ListTile(
                title: Text(
                  lang == AppLanguage.fr ? 'Français' : 'English',
                  style: AppTypography.bodyMedium(color: AppColors.foreground),
                ),
                trailing: LocaleController.instance.language == lang
                    ? Icon(LucideIcons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  LocaleController.instance.setLanguage(lang);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
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
                    AppStrings.t('Paramètres'),
                    style: AppTypography.titleScreen(fontSize: 22),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListenableBuilder(
                listenable: Listenable.merge([
                  _settings,
                  ThemeController.instance,
                  LocaleController.instance,
                ]),
                builder: (context, _) {
                  return ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    children: [
                      // Section Préférences générales
                      _SectionHeader(title: AppStrings.t('PRÉFÉRENCES')),
                      _SettingsContainer(
                        children: [
                          _SettingsSwitchTile(
                            icon: LucideIcons.moon,
                            title: AppStrings.t('Thème de l\'application'),
                            subtitle: ThemeController.instance.isDark
                                ? AppStrings.t('Sombre')
                                : AppStrings.t('Clair'),
                            value: ThemeController.instance.isDark,
                            onChanged: ThemeController.instance.setDark,
                          ),
                          const _SettingsDivider(),
                          _SettingsTile(
                            icon: LucideIcons.globe,
                            title: AppStrings.t('Langue de l\'application'),
                            subtitle: LocaleController.instance.label,
                            onTap: _showLanguagePicker,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Section Notifications
                      _SectionHeader(title: AppStrings.t('NOTIFICATIONS')),
                      _SettingsContainer(
                        children: [
                          _SettingsSwitchTile(
                            icon: LucideIcons.triangle_alert,
                            title: AppStrings.t('Alertes impayés'),
                            subtitle: AppStrings.t(
                              'Rappel automatique en cas de retard de loyer',
                            ),
                            value: _settings.notifImpayes,
                            onChanged: _settings.setNotifImpayes,
                          ),
                          const _SettingsDivider(),
                          _SettingsSwitchTile(
                            icon: LucideIcons.calendar_clock,
                            title: AppStrings.t('Échéances de baux'),
                            subtitle: AppStrings.t(
                              'Alerte 60 et 30 jours avant la fin d\'un contrat',
                            ),
                            value: _settings.notifEcheances,
                            onChanged: _settings.setNotifEcheances,
                          ),
                          const _SettingsDivider(),
                          _SettingsSwitchTile(
                            icon: LucideIcons.bell,
                            title: AppStrings.t('Notifications push'),
                            subtitle: AppStrings.t(
                              'Recevoir les résumés et activités clés',
                            ),
                            value: _settings.notifPush,
                            onChanged: _settings.setNotifPush,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Section Sécurité
                      _SectionHeader(title: AppStrings.t('SÉCURITÉ')),
                      _SettingsContainer(
                        children: [
                          _SettingsSwitchTile(
                            icon: LucideIcons.scan_face,
                            title: AppStrings.t('Verrouillage biométrique'),
                            subtitle: AppStrings.t(
                              'Face ID ou empreinte au démarrage',
                            ),
                            value: _settings.biometrie,
                            onChanged: _settings.setBiometrie,
                          ),
                          const _SettingsDivider(),
                          _SettingsTile(
                            icon: LucideIcons.lock,
                            title: AppStrings.t('Changer de mot de passe'),
                            subtitle: AppStrings.t(
                              'Dernière modification il y a 3 mois',
                            ),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppStrings.t(
                                      'Changement de mot de passe disponible en ligne',
                                    ),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Section Autres & À propos
                      _SectionHeader(
                        title: AppStrings.t('AUTRES & ASSISTANCE'),
                      ),
                      _SettingsContainer(
                        children: [
                          _SettingsTile(
                            icon: LucideIcons.sparkles,
                            title: AppStrings.t('Revoir la présentation'),
                            subtitle: AppStrings.t(
                              'Relancer l\'onboarding de l\'application',
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const OnboardingScreen(),
                                ),
                              );
                            },
                          ),
                          const _SettingsDivider(),
                          _SettingsTile(
                            icon: LucideIcons.file_text,
                            title: AppStrings.t('Conditions d\'utilisation'),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppStrings.t(
                                      'Conditions d\'utilisation Hope Gestion',
                                    ),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                          const _SettingsDivider(),
                          _SettingsTile(
                            icon: LucideIcons.shield_check,
                            title: AppStrings.t('Politique de confidentialité'),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppStrings.t(
                                      'Politique de confidentialité Hope Gestion',
                                    ),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Version de l'application
                      Center(
                        child: Text(
                          'HopeGestion Mobile · Version 1.0.0 (MVP)',
                          style: AppTypography.caption(
                            color: AppColors.mutedForeground,
                          ),
                        ),
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

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: AppTypography.labelUppercase(
          color: AppColors.mutedForeground,
          fontSize: 11,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsContainer extends StatelessWidget {
  final List<Widget> children;

  const _SettingsContainer({required this.children});

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

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 18),
      ),
      title: Text(
        title,
        style: AppTypography.bodyMedium(color: AppColors.foreground),
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

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 18),
      ),
      title: Text(
        title,
        style: AppTypography.bodyMedium(color: AppColors.foreground),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.caption(color: AppColors.mutedForeground),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.primary,
        activeThumbColor: Colors.white,
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.border,
      indent: 56,
    );
  }
}
