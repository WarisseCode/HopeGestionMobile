import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_typography.dart';
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
      backgroundColor: kAuthBackground,
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
                  color: kAuthText.withValues(alpha: 0.35),
                ),
                const SizedBox(height: 16),
                Text(
                  'Connexion au serveur impossible',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.syne(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: kAuthText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vérifiez votre connexion internet, puis réessayez.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13,
                    color: kAuthText.withValues(alpha: 0.55),
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
                      backgroundColor: kAuthPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Réessayer',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
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
