import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/auth_widgets.dart';

/// Affiché quand la connexion (ou la session restaurée) aboutit à un rôle
/// non pris en charge par la v1 mobile ("réservée aux gestionnaires").
/// Aucun token n'est conservé à ce stade (voir `AuthRepository`) — pas de
/// bouton de retour vers l'app : la seule issue est de fermer et relancer
/// l'app (ce qui remontrera l'onboarding puis la connexion).
class UnsupportedRoleScreen extends StatelessWidget {
  const UnsupportedRoleScreen({super.key});

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
                  Icons.block_rounded,
                  size: 40,
                  color: kDark.withValues(alpha: 0.35),
                ),
                const SizedBox(height: 16),
                Text(
                  'Application réservée aux gestionnaires',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.syne(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: kDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cette application est réservée aux gestionnaires. '
                  'Rendez-vous sur hopegestion.com pour accéder à votre espace.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 13,
                    color: kDark.withValues(alpha: 0.55),
                    height: 1.5,
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
