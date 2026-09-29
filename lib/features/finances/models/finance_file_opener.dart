import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Ouvre [url] (déjà résolue par `AppConfig.resolveFileUrl`) dans une
/// application externe — lecteur PDF, navigateur. Si l'ouverture échoue
/// (aucune application compatible, ou exception de la plateforme), repli
/// automatique : le lien est copié dans le presse-papiers, avec un message
/// clair. Logique introduite pour `_LienFichier` (T-043) et partagée avec
/// la confirmation d'encaissement (T-044) pour ne pas la dupliquer.
Future<void> ouvrirFichierOuCopier(BuildContext context, String url) async {
  var ouvert = false;
  try {
    ouvert = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    ouvert = false;
  }
  if (ouvert || !context.mounted) return;

  // Solution de repli : copie du lien, avec un message clair sur la raison.
  await Clipboard.setData(ClipboardData(text: url));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        "Impossible d'ouvrir ce fichier : le lien a été copié "
        'dans le presse-papiers',
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
