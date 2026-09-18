import 'package:flutter/material.dart';

import '../../../core/design_system.dart';
import '../../../core/i18n/locale_controller.dart';
import '../models/dashboard_data.dart';

/// Section des 3 cartes KPI du Dashboard
class DashboardKpis extends StatelessWidget {
  final KpiItem encaissements;
  final KpiItem depenses;
  final KpiItem impayes;
  final ValueChanged<String>? onKpiTap;

  const DashboardKpis({
    super.key,
    required this.encaissements,
    required this.depenses,
    required this.impayes,
    this.onKpiTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) {
        return Row(
          children: [
            AppKpiCard(
              label: encaissements.label,
              value: encaissements.value,
              note: encaissements.note,
              isPositiveNote: encaissements.isPositive,
              onTap: onKpiTap != null ? () => onKpiTap!('encaissements') : null,
            ),
            const SizedBox(width: 8),
            AppKpiCard(
              label: depenses.label,
              value: depenses.value,
              note: depenses.note,
              isPositiveNote: depenses.isPositive,
              onTap: onKpiTap != null ? () => onKpiTap!('depenses') : null,
            ),
            const SizedBox(width: 8),
            AppKpiCard(
              label: impayes.label,
              value: impayes.value,
              note: impayes.note,
              isPositiveNote: impayes.isPositive,
              onTap: onKpiTap != null ? () => onKpiTap!('impayes') : null,
            ),
          ],
        );
      },
    );
  }
}
