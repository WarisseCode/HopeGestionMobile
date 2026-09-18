import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../models/app_notification.dart';

/// Écran des notifications et alertes impayés
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<AppNotification> _notifications;
  int _activeFilter = 0; // 0: Toutes, 1: Impayés, 2: Paiements, 3: Contrats

  final List<String> _filters = [
    'Toutes',
    'Impayés',
    'Paiements',
    'Baux & Contrats',
  ];

  @override
  void initState() {
    super.initState();
    _notifications = AppNotification.mockList;
  }

  List<AppNotification> get _filteredNotifications {
    switch (_activeFilter) {
      case 1:
        return _notifications
            .where((n) => n.type == NotificationType.impaye)
            .toList();
      case 2:
        return _notifications
            .where((n) => n.type == NotificationType.paiement)
            .toList();
      case 3:
        return _notifications
            .where((n) => n.type == NotificationType.contrat)
            .toList();
      default:
        return _notifications;
    }
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        n.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Toutes les notifications ont été marquées comme lues'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showRelanceSheet(AppNotification notif) {
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
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: AppRadius.borderFull,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'RELANCE LOCATAIRE',
              style: AppTypography.labelUppercase(
                color: AppColors.mutedForeground,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Relancer ${notif.relatedContact ?? "le locataire"}',
              style: AppTypography.titleScreen(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              'Montant dû : ${notif.amount ?? "Non précisé"} · ${notif.relatedProperty ?? ""}',
              style: AppTypography.bodySmall(color: AppColors.mutedForeground),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.message_circle,
                  color: Color(0xFF25D366),
                  size: 20,
                ),
              ),
              title: Text(
                'Envoyer un rappel WhatsApp',
                style: AppTypography.bodyMedium(color: AppColors.foreground),
              ),
              subtitle: Text(
                'Modèle de rappel courtois pré-rempli',
                style: AppTypography.caption(color: AppColors.mutedForeground),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Rappel WhatsApp préparé pour ${notif.relatedContact}',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            Divider(color: AppColors.border, height: 1),
            ListTile(
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.phone,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              title: Text(
                'Appeler directement',
                style: AppTypography.bodyMedium(color: AppColors.foreground),
              ),
              subtitle: Text(
                'Joindre le locataire par téléphone',
                style: AppTypography.caption(color: AppColors.mutedForeground),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Appel vers ${notif.relatedContact}...'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredNotifications;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Notifications',
                              style: AppTypography.titleScreen(fontSize: 22),
                            ),
                            if (_unreadCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$_unreadCount',
                                  style: AppTypography.caption(
                                    color: Colors.white,
                                  ).copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_unreadCount > 0)
                    TextButton(
                      onPressed: _markAllAsRead,
                      child: Text(
                        'Tout lire',
                        style: AppTypography.bodySmall(color: AppColors.primary)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),

            // Filtres horizontaux
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: List.generate(_filters.length, (index) {
                  final isSelected = _activeFilter == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_filters[index]),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _activeFilter = index),
                      backgroundColor: AppColors.card,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.foreground,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      showCheckmark: false,
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 10),

            // Liste des notifications
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.bell_off,
                            size: 48,
                            color: AppColors.mutedForeground.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Aucune notification dans cette catégorie',
                            style: AppTypography.bodyMedium(
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final notif = list[index];
                        return _NotificationCard(
                          notification: notif,
                          onTap: () {
                            setState(() => notif.isRead = true);
                          },
                          onRelanceTap: () => _showRelanceSheet(notif),
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

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onRelanceTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onRelanceTap,
  });

  @override
  Widget build(BuildContext context) {
    final type = notification.type;

    return Container(
      decoration: BoxDecoration(
        color: notification.isRead ? AppColors.card : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.isRead
              ? AppColors.border
              : AppColors.primary.withValues(alpha: 0.3),
          width: notification.isRead ? 1 : 1.5,
        ),
        boxShadow: AppShadows.soft,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icône ronde de type
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: type.color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(type.icon, color: type.color, size: 20),
                    ),
                    const SizedBox(width: 12),

                    // Titre & message
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  notification.title,
                                  style:
                                      AppTypography.bodyMedium(
                                        color: AppColors.foreground,
                                      ).copyWith(
                                        fontWeight: notification.isRead
                                            ? FontWeight.w600
                                            : FontWeight.w700,
                                      ),
                                ),
                              ),
                              Text(
                                notification.timeAgo,
                                style: AppTypography.caption(
                                  color: AppColors.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification.message,
                            style: AppTypography.bodySmall(
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (!notification.isRead) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),

                // Bouton d'action contextuel pour les impayés
                if (type == NotificationType.impaye) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: onRelanceTap,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.warning,
                          side: BorderSide(color: AppColors.warning),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                        ),
                        icon: const Icon(LucideIcons.send, size: 14),
                        label: const Text(
                          'Relancer',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
