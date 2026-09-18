import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../models/contact.dart';

/// Ligne de contact dans la liste Locataires / Contacts.
class ContactRow extends StatelessWidget {
  const ContactRow({super.key, required this.contact, this.onTap});

  final Contact contact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar avec initiales
            AppAvatar(initials: contact.initials, size: 44),
            const SizedBox(width: 14),

            // Nom + info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: AppTypography.titleSection(fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    contact.info,
                    style: AppTypography.bodySmall(
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),

            // Chevron
            Icon(
              LucideIcons.chevron_right,
              size: 18,
              color: AppColors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}
