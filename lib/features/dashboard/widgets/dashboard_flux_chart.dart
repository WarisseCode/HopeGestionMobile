import 'package:flutter/material.dart';

import '../../../core/design_system.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/locale_controller.dart';
import '../models/dashboard_data.dart';

/// Graphique « Flux · 7 jours » fidèle à la maquette 01-dashboard.png
class DashboardFluxChart extends StatefulWidget {
  final String netAmount;
  final List<FluxDayData> daysData;

  const DashboardFluxChart({
    super.key,
    required this.netAmount,
    required this.daysData,
  });

  @override
  State<DashboardFluxChart> createState() => _DashboardFluxChartState();
}

class _DashboardFluxChartState extends State<DashboardFluxChart> {
  int? _selectedDayIndex;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête : Titre + Légende
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.t('FLUX · 7 JOURS'),
                style: AppTypography.labelUppercase(
                  fontSize: 10,
                  color: AppColors.mutedForeground,
                  letterSpacing: 0.8,
                ),
              ),
              Row(
                children: [
                  _buildLegendItem(
                    color: AppColors.primary,
                    label: AppStrings.t('Entrées'),
                  ),
                  const SizedBox(width: 10),
                  _buildLegendItem(
                    color: const Color(0x556B7D7A),
                    label: AppStrings.t('Sorties'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Montant Net
          Row(
            children: [
              Text(
                'Net ',
                style: AppTypography.titleSection(
                  fontSize: 16,
                  color: AppColors.foreground,
                ),
              ),
              Text(
                widget.netAmount,
                style: AppTypography.titleSection(
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Zone des Barres (Hauteur 96px)
          SizedBox(
            height: 110,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(widget.daysData.length, (index) {
                final day = widget.daysData[index];
                final isSelected = _selectedDayIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDayIndex = isSelected ? null : index;
                    });
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Groupe de deux barres
                      SizedBox(
                        height: 84,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Barre Entrées (Teal)
                            _buildBar(
                              percentage: day.inAmount / 100.0,
                              color: isSelected
                                  ? AppColors.primaryStrong
                                  : AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            // Barre Sorties (Gris neutre)
                            _buildBar(
                              percentage: day.outAmount / 100.0,
                              color: isSelected
                                  ? const Color(0x886B7D7A)
                                  : const Color(0x356B7D7A),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Numéro du jour
                      Text(
                        '${day.day}',
                        style:
                            AppTypography.kpiNote(
                              fontSize: 10,
                              color: isSelected
                                  ? AppColors.foreground
                                  : AppColors.mutedForeground,
                            ).copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.kpiNote(
            fontSize: 9.5,
            color: AppColors.mutedForeground,
          ),
        ),
      ],
    );
  }

  Widget _buildBar({required double percentage, required Color color}) {
    // Calcul de la hauteur avec un minimum visible
    final barHeight = (percentage * 80).clamp(12.0, 80.0);

    return Container(
      width: 12,
      height: barHeight,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
      ),
    );
  }
}
