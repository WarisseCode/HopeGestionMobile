import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/auth_repository.dart';
import '../widgets/auth_widgets.dart';

/// Affiché quand une session existe localement mais que le serveur n'a pas
/// pu être contacté au démarrage (`AuthState.offline`) : on ne sait pas si
/// le rôle est encore autorisé, donc on ne montre ni le shell ni l'écran de
/// connexion, seulement une invitation à réessayer. Les tokens sont
/// conservés (voir `AuthRepository.restoreSession`).
class OfflineScreen extends StatelessWidget {
  const OfflineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF7F5),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AuthLogo(),
                const SizedBox(height: 28),
                Icon(
                  Icons.wifi_off_rounded,
                  size: 40,
                  color: kDark.withValues(alpha: 0.35),
                ),
                const SizedBox(height: 16),
                Text(
                  'Connexion au serveur impossible',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.syne(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: kDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vérifiez votre connexion internet, puis réessayez.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 13,
                    color: kDark.withValues(alpha: 0.55),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => AuthRepository.instance.retry(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Réessayer',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
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
}
