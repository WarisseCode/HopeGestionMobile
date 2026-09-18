import 'package:flutter/material.dart';

/// Rayons de courbure conformes au Design System HopeGestion
abstract class AppRadius {
  /// Rayon extra-petit (8px)
  static const double xs = 8.0;
  static const Radius radiusXs = Radius.circular(xs);
  static const BorderRadius borderXs = BorderRadius.all(radiusXs);

  /// Rayon petit (12px) - utilisé pour boutons, inputs, badges
  static const double sm = 12.0;
  static const Radius radiusSm = Radius.circular(sm);
  static const BorderRadius borderSm = BorderRadius.all(radiusSm);

  /// Rayon par défaut (16px) - utilisé pour les cartes, avatars carrés
  static const double md = 16.0;
  static const Radius radiusMd = Radius.circular(md);
  static const BorderRadius borderMd = BorderRadius.all(radiusMd);

  /// Grand rayon (24px) - utilisé pour les modals, bottom sheets
  static const double lg = 24.0;
  static const Radius radiusLg = Radius.circular(lg);
  static const BorderRadius borderLg = BorderRadius.all(radiusLg);

  /// Très grand rayon (32px)
  static const double xl = 32.0;
  static const Radius radiusXl = Radius.circular(xl);
  static const BorderRadius borderXl = BorderRadius.all(radiusXl);

  /// Rayon complet (pilule / cercle 9999px)
  static const double full = 9999.0;
  static const Radius radiusFull = Radius.circular(full);
  static const BorderRadius borderFull = BorderRadius.all(radiusFull);
}
