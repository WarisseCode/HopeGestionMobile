import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/screens/shell_screen.dart';
import '../widgets/auth_widgets.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  void _login() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const ShellScreen()));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF7F5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 32),

              // ── Logo ──────────────────────────────────────────────
              const AuthLogo(),
              const SizedBox(height: 8),
              Text(
                'La gestion immobilière, simplement.',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 13,
                  color: kDark.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 12),

              // Feature pills
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ['Biens', 'Locataires', 'Finances', 'Documents'].map((
                  l,
                ) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: kTeal,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l,
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 12,
                            color: kDark.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 28),

              // ── Card ──────────────────────────────────────────────
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bon retour parmi nous',
                      style: GoogleFonts.syne(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: kDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Connectez-vous pour gérer votre agence et suivre vos activités.',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 13,
                        color: kDark.withValues(alpha: 0.55),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Email
                    const AuthFieldLabel('Adresse e-mail'),
                    const SizedBox(height: 6),
                    AuthTextField(
                      controller: _emailCtrl,
                      hint: 'votre@email.com',
                      prefixIcon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    // Password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const AuthFieldLabel('Mot de passe'),
                        Text(
                          'Mot de passe oublié ?',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: kTeal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    AuthTextField(
                      controller: _passwordCtrl,
                      hint: '••••••••',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscure: _obscure,
                      suffix: GestureDetector(
                        onTap: () => setState(() => _obscure = !_obscure),
                        child: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                          color: kDark.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // CTA
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kTeal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Se connecter',
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // OR divider
                    const AuthOrDivider(),
                    const SizedBox(height: 16),

                    // Google
                    const AuthGoogleButton(label: 'Continuer avec Google'),
                    const SizedBox(height: 20),

                    // Register link
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        ),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "Vous n'avez pas encore de compte ? ",
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 13,
                                  color: kDark.withValues(alpha: 0.55),
                                ),
                              ),
                              TextSpan(
                                text: "S'Inscrire",
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: kTeal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Security note
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 14,
                          color: kDark.withValues(alpha: 0.35),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Vos données sont protégées et sécurisées',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 11,
                            color: kDark.withValues(alpha: 0.35),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
