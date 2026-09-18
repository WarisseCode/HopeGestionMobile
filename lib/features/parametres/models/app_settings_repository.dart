import 'package:flutter/foundation.dart';

/// Source de vérité unique pour les préférences de l'application, partagée
/// par tous les écrans (ex. NotificationsScreen pourra plus tard vérifier
/// `notifPush`/`notifImpayes` avant d'afficher une alerte).
class AppSettingsRepository extends ChangeNotifier {
  AppSettingsRepository._();

  static final AppSettingsRepository instance = AppSettingsRepository._();

  bool notifImpayes = true;
  bool notifEcheances = true;
  bool notifPush = true;
  bool biometrie = false;

  void setNotifImpayes(bool value) {
    notifImpayes = value;
    notifyListeners();
  }

  void setNotifEcheances(bool value) {
    notifEcheances = value;
    notifyListeners();
  }

  void setNotifPush(bool value) {
    notifPush = value;
    notifyListeners();
  }

  void setBiometrie(bool value) {
    biometrie = value;
    notifyListeners();
  }
}
