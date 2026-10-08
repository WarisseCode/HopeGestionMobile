import 'package:flutter/widgets.dart';

/// Verrou anti-double-envoi des formulaires à récapitulatif (contrat,
/// quittance, dépense, encaissement).
///
/// Le verrou est vérifié et posé de façon synchrone avant tout appel
/// réseau : un double appui, même avant le premier repaint, ne peut jamais
/// déclencher une deuxième requête. [envoiEnCours] est un [ValueNotifier]
/// pour que la feuille récapitulatif (route modale distincte, hors du
/// `setState` de l'écran) suive l'état du bouton « Confirmer ».
///
/// Libéré automatiquement dans [dispose] ; la libération après l'envoi
/// ([libererVerrouEnvoi]) reste à la charge de chaque écran.
mixin VerrouEnvoi<T extends StatefulWidget> on State<T> {
  /// `true` pendant un envoi.
  final ValueNotifier<bool> envoiEnCours = ValueNotifier(false);

  /// Pose le verrou. `false` si un envoi est déjà en cours : l'appelant
  /// doit alors abandonner sans rien envoyer.
  bool prendreVerrouEnvoi() {
    if (envoiEnCours.value) return false;
    envoiEnCours.value = true;
    return true;
  }

  /// Rend le bouton « Confirmer » à nouveau utilisable.
  void libererVerrouEnvoi() => envoiEnCours.value = false;

  @override
  void dispose() {
    envoiEnCours.dispose();
    super.dispose();
  }
}
