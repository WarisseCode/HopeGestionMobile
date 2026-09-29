import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// Double de `UrlLauncherPlatform` pour les tests widget : pas d'implémentation
/// native disponible en test (`MissingPluginException` sinon). Enregistre les
/// URLs demandées et renvoie [result] (ou lève si [throws]), pour couvrir le
/// succès, l'échec « aucune application » et l'échec « exception plateforme ».
class FakeUrlLauncher extends UrlLauncherPlatform {
  FakeUrlLauncher({this.result = true, this.throws = false});

  final bool result;
  final bool throws;
  final List<String> launched = [];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    if (throws) throw Exception('Échec de test (launchUrl)');
    return result;
  }

  @override
  Future<bool> canLaunch(String url) async => result;
}
