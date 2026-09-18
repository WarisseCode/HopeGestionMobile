import 'locale_controller.dart';

/// Dictionnaire de traduction léger (sans génération de code).
///
/// Convention : chaque clé est le texte français source tel qu'il apparaît
/// dans le code (avec des `{param}` pour les portions dynamiques). En mode
/// français, [t] renvoie toujours la clé telle quelle — aucune duplication
/// nécessaire. En anglais, on renvoie la traduction si elle existe, sinon on
/// retombe sur le français plutôt que d'afficher une clé cassée.
///
/// Périmètre actuel : Dashboard + Paramètres (voir la conversation associée
/// à ce chantier). Le reste de l'app reste en français tant qu'il n'a pas
/// été ajouté ici.
abstract class AppStrings {
  static const Map<String, String> _en = {
    // Dashboard — en-tête
    'Bonjour, {name}': 'Hello, {name}',
    'LUNDI 14 AVRIL': 'MONDAY, APRIL 14',
    'Tableau de bord actualisé': 'Dashboard refreshed',

    // Dashboard — KPIs
    'Encaiss.': 'Received',
    'Dépenses': 'Expenses',
    'Impayés': 'Unpaid',
    '+12% ce mois': '+12% this month',
    '24% du CA': '24% of revenue',
    '3 factures': '3 invoices',
    'Détail KPI : {kpi}': 'KPI detail: {kpi}',

    // Dashboard — Flux 7 jours
    'FLUX · 7 JOURS': 'FLOW · 7 DAYS',
    'Entrées': 'Inflows',
    'Sorties': 'Outflows',

    // Dashboard — Raccourcis Créer
    'CRÉER': 'CREATE',
    'Bien': 'Property',
    'Locataire': 'Tenant',
    'Facture': 'Invoice',
    'Quittance': 'Receipt',

    // Dashboard — Loyers récents
    'LOYERS RÉCENTS': 'RECENT RENTS',
    'Tout voir': 'View all',
    'Voir tous les loyers': 'View all rent payments',
    'Payé': 'Paid',
    'En attente': 'Pending',
    'Impayé': 'Unpaid',

    // Action rapide (modale accessible depuis le Dashboard)
    'ACTION RAPIDE': 'QUICK ACTION',
    'Que créer ?': 'What to create?',
    'Un bien': 'A property',
    'Un locataire': 'A tenant',
    'Une facture': 'An invoice',
    'Une quittance': 'A receipt',
    'Un contrat': 'A contract',
    'Un état des lieux': 'A move-in/move-out report',

    // Paramètres
    'Paramètres': 'Settings',
    'PRÉFÉRENCES': 'PREFERENCES',
    'Thème de l\'application': 'App theme',
    'Sombre': 'Dark',
    'Clair': 'Light',
    'Langue de l\'application': 'App language',
    'Choisir la langue': 'Choose language',
    'Alertes impayés': 'Unpaid alerts',
    'Rappel automatique en cas de retard de loyer':
        'Automatic reminder in case of late rent',
    'Échéances de baux': 'Lease deadlines',
    'Alerte 60 et 30 jours avant la fin d\'un contrat':
        'Alert 60 and 30 days before a lease ends',
    'Notifications push': 'Push notifications',
    'Recevoir les résumés et activités clés':
        'Receive summaries and key activity',
    'SÉCURITÉ': 'SECURITY',
    'Verrouillage biométrique': 'Biometric lock',
    'Face ID ou empreinte au démarrage': 'Face ID or fingerprint at launch',
    'Changer de mot de passe': 'Change password',
    'Dernière modification il y a 3 mois': 'Last changed 3 months ago',
    'Changement de mot de passe disponible en ligne':
        'Password change available online',
    'AUTRES & ASSISTANCE': 'OTHER & SUPPORT',
    'Revoir la présentation': 'Replay the walkthrough',
    'Relancer l\'onboarding de l\'application': 'Restart the app onboarding',
    'Conditions d\'utilisation': 'Terms of use',
    'Conditions d\'utilisation Hope Gestion': 'Hope Gestion terms of use',
    'Politique de confidentialité': 'Privacy policy',
    'Politique de confidentialité Hope Gestion': 'Hope Gestion privacy policy',
  };

  /// Traduit [source] (le texte français tel qu'écrit dans le code) et
  /// remplace les `{param}` par les valeurs fournies dans [params].
  static String t(String source, [Map<String, String>? params]) {
    var text = LocaleController.instance.isEnglish
        ? (_en[source] ?? source)
        : source;
    params?.forEach((key, value) {
      text = text.replaceAll('{$key}', value);
    });
    return text;
  }
}
