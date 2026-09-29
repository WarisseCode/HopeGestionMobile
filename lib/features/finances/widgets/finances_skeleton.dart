import 'package:flutter/material.dart';

import '../../../core/design_system.dart';

/// Squelettes de chargement de l'écran Finances (carte de synthèse et
/// lignes de mouvements), avec la même pulsation d'opacité que
/// `ImmeubleCardSkeleton` — pas de dépendance « shimmer ».
class FinancesSkeleton extends StatefulWidget {
  const FinancesSkeleton.carte({super.key}) : lignes = 0;
  const FinancesSkeleton.lignes({super.key, this.lignes = 4});

  /// 0 : silhouette de la carte de synthèse ; sinon nombre de lignes.
  final int lignes;

  @override
  State<FinancesSkeleton> createState() => _FinancesSkeletonState();
}

class _FinancesSkeletonState extends State<FinancesSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(_controller),
      child: widget.lignes == 0 ? _carte() : _lignes(widget.lignes),
    );
  }

  Widget _carte() => Container(
    width: double.infinity,
    height: 178,
    decoration: BoxDecoration(
      color: AppColors.muted,
      borderRadius: BorderRadius.circular(24),
    ),
  );

  Widget _lignes(int n) => Column(
    children: [
      for (var i = 0; i < n; i++)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bar(width: 140, height: 12),
                    const SizedBox(height: 8),
                    _bar(width: 90, height: 10),
                  ],
                ),
              ),
              _bar(width: 70, height: 12),
            ],
          ),
        ),
    ],
  );

  Widget _bar({required double width, required double height}) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: AppColors.muted,
      borderRadius: BorderRadius.circular(6),
    ),
  );
}
