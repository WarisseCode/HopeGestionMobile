import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Double du presse-papiers pour les tests widget.
///
/// `flutter_test` n'installe aucun gestionnaire par défaut pour le canal
/// `SystemChannels.platform` : sans double, `Clipboard.setData`/`getData`
/// restent en attente indéfiniment (vérifié isolément — aucune exception,
/// aucun timeout signalé par `pumpAndSettle`, simplement aucune réponse).
/// Installe un faux gestionnaire mémorisant le dernier texte copié.
class FakeClipboard {
  String? text;

  /// À appeler dans `setUp` : installe ce double comme gestionnaire du canal.
  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      switch (call.method) {
        case 'Clipboard.setData':
          text = (call.arguments as Map)['text'] as String?;
          return null;
        case 'Clipboard.getData':
          return <String, dynamic>{'text': text};
        case 'Clipboard.hasStrings':
          return <String, dynamic>{'value': text != null && text!.isNotEmpty};
        default:
          return null;
      }
    });
  }
}
