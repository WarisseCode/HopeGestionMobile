import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/core/widgets/verrou_envoi.dart';

class _Hote extends StatefulWidget {
  const _Hote();

  @override
  State<_Hote> createState() => _HoteState();
}

class _HoteState extends State<_Hote> with VerrouEnvoi {
  @override
  Widget build(BuildContext context) => const SizedBox();
}

void main() {
  testWidgets('un seul envoi à la fois, libération explicite', (tester) async {
    await tester.pumpWidget(const _Hote());
    final etat = tester.state<_HoteState>(find.byType(_Hote));

    expect(etat.envoiEnCours.value, isFalse);
    expect(etat.prendreVerrouEnvoi(), isTrue);
    expect(etat.envoiEnCours.value, isTrue);
    // Double appui : refusé, le verrou reste posé.
    expect(etat.prendreVerrouEnvoi(), isFalse);
    expect(etat.envoiEnCours.value, isTrue);

    etat.libererVerrouEnvoi();
    expect(etat.envoiEnCours.value, isFalse);
    expect(etat.prendreVerrouEnvoi(), isTrue);
  });

  testWidgets('le notifier est libéré avec l\'écran', (tester) async {
    await tester.pumpWidget(const _Hote());
    final notifier = tester.state<_HoteState>(find.byType(_Hote)).envoiEnCours;

    await tester.pumpWidget(const SizedBox());

    // Un ChangeNotifier libéré refuse tout nouvel écouteur.
    expect(() => notifier.addListener(() {}), throwsFlutterError);
  });
}
