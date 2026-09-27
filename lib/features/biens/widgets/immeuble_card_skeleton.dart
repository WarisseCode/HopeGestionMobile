import 'package:flutter/material.dart';

import '../../../core/design_system.dart';
import 'immeuble_card.dart';

/// Squelette de chargement reprenant la silhouette d'`ImmeubleCard`
/// (photo à gauche, badge, titre, sous-titre, barre d'occupation), avec une
/// pulsation d'opacité — pas de dépendance « shimmer » ajoutée pour ça.
class ImmeubleCardSkeleton extends StatefulWidget {
  const ImmeubleCardSkeleton({super.key});

  @override
  State<ImmeubleCardSkeleton> createState() => _ImmeubleCardSkeletonState();
}

class _ImmeubleCardSkeletonState extends State<ImmeubleCardSkeleton>
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
      child: AppCard(
        padding: EdgeInsets.zero,
        shadows: const [],
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md - 1),
          child: SizedBox(
            height: ImmeubleCard.minHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ColoredBox(
                  color: AppColors.muted,
                  child: const SizedBox(width: ImmeubleCard.imageWidth),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _bar(width: 64, height: 16, pill: true),
                        const SizedBox(height: 10),
                        _bar(width: 150, height: 12),
                        const SizedBox(height: 8),
                        _bar(width: 100, height: 10),
                        const Spacer(),
                        _bar(height: 4, pill: true),
                        const SizedBox(height: 6),
                        _bar(width: 110, height: 10),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bar({double? width, required double height, bool pill = false}) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: pill ? AppRadius.borderFull : BorderRadius.circular(4),
      ),
    );
  }
}
