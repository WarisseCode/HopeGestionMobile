import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';

enum NotificationType {
  impaye,
  contrat,
  paiement,
  alerte;

  String get label {
    switch (this) {
      case NotificationType.impaye:
        return 'Impayé';
      case NotificationType.contrat:
        return 'Contrat';
      case NotificationType.paiement:
        return 'Paiement';
      case NotificationType.alerte:
        return 'Alerte';
    }
  }

  Color get color {
    switch (this) {
      case NotificationType.impaye:
        return AppColors.warning;
      case NotificationType.contrat:
        return const Color(0xFF3B82F6);
      case NotificationType.paiement:
        return AppColors.positive;
      case NotificationType.alerte:
        return const Color(0xFFF59E0B);
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.impaye:
        return LucideIcons.triangle_alert;
      case NotificationType.contrat:
        return LucideIcons.file_text;
      case NotificationType.paiement:
        return LucideIcons.circle_check;
      case NotificationType.alerte:
        return LucideIcons.bell_ring;
    }
  }
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String timeAgo;
  final NotificationType type;
  bool isRead;
  final String? relatedContact;
  final String? relatedProperty;
  final String? amount;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timeAgo,
    required this.type,
    this.isRead = false,
    this.relatedContact,
    this.relatedProperty,
    this.amount,
  });

  static List<AppNotification> get mockList => [
    AppNotification(
      id: 'notif-1',
      title: 'Loyer impayé détecté',
      message: 'Koffi Mensah (Appart. B2 · Immeuble Horizon) accuse 12 jours de retard.',
      timeAgo: 'Il y a 2h',
      type: NotificationType.impaye,
      isRead: false,
      relatedContact: 'Koffi Mensah',
      relatedProperty: 'Immeuble Horizon · Lot B2',
      amount: '180 000 FCFA',
    ),
    AppNotification(
      id: 'notif-2',
      title: 'Paiement reçu par MTN MoMo',
      message:
          'Jean-Luc Akue a réglé son loyer de Septembre pour le Studio Marina.',
      timeAgo: 'Il y a 5h',
      type: NotificationType.paiement,
      isRead: false,
      relatedContact: 'Jean-Luc Akue',
      relatedProperty: 'Résidence Marina · Studio 4',
      amount: '95 000 FCFA',
    ),
    AppNotification(
      id: 'notif-3',
      title: 'Échéance de bail proche',
      message: 'Le contrat de Fatou Diop arrive à terme le 31 Octobre 2026. Prévoir le renouvellement.',
      timeAgo: 'Hier',
      type: NotificationType.contrat,
      isRead: true,
      relatedContact: 'Fatou Diop',
      relatedProperty: 'Villa Les Cocotiers',
    ),
    AppNotification(
      id: 'notif-4',
      title: 'Nouvelle réclamation signalée',
      message:
          'Amadou Traoré signale un problème de plomberie dans la cuisine.',
      timeAgo: 'Il y a 2 jours',
      type: NotificationType.alerte,
      isRead: true,
      relatedContact: 'Amadou Traoré',
      relatedProperty: 'Appartement 1A',
    ),
    AppNotification(
      id: 'notif-5',
      title: 'Rappel révision de loyer',
      message: 'La révision triennale du bail commercial de Sékou Ouattara est échue.',
      timeAgo: 'Il y a 4 jours',
      type: NotificationType.contrat,
      isRead: true,
      relatedContact: 'Sékou Ouattara',
      relatedProperty: 'Local Commercial Akpakpa',
    ),
  ];
}
