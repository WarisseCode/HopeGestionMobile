import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/screens/shell_screen.dart';
import '../widgets/auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _lastNameCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _terms = false;

  void _register() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const ShellScreen()));
  }

  @override
  void dispose() {
    _lastNameCtrl.dispose();
    _firstNameCtrl.dispose();
    _phoneCtrl.dispose();
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
                    Align(
                      alignment: Alignment.topRight,
                      child: Text(
                        'ÉTAPE 1 SUR 1',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 11,
                          letterSpacing: 1.4,
                          color: kDark.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    Text(
                      'Créez votre espace',
                      style: GoogleFonts.syne(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: kDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Commencez à piloter votre activité immobilière depuis votre mobile.',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 13,
                        color: kDark.withValues(alpha: 0.55),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Nom + Prénom
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const AuthFieldLabel('Nom'),
                              const SizedBox(height: 6),
                              AuthTextField(
                                controller: _lastNameCtrl,
                                hint: 'OTCHADE',
                                prefixIcon: Icons.person_outline_rounded,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const AuthFieldLabel('Prénom'),
                              const SizedBox(height: 6),
                              AuthTextField(
                                controller: _firstNameCtrl,
                                hint: 'Warisse',
                                prefixIcon: Icons.person_outline_rounded,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Téléphone
                    const AuthFieldLabel('Téléphone'),
                    const SizedBox(height: 6),
                    AuthTextField(
                      controller: _phoneCtrl,
                      hint: '+229 01 97 00 00 00',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

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
                    const AuthFieldLabel('Mot de passe'),
                    const SizedBox(height: 6),
                    AuthTextField(
                      controller: _passwordCtrl,
                      hint: '8 caractères minimum',
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
                    const SizedBox(height: 16),

                    // Terms
                    GestureDetector(
                      onTap: () => setState(() => _terms = !_terms),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _terms ? kTeal : Colors.transparent,
                              border: Border.all(
                                color: _terms
                                    ? kTeal
                                    : kDark.withValues(alpha: 0.25),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: _terms
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "J'accepte les conditions d'utilisation et la politique de confidentialité.",
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 12,
                                color: kDark.withValues(alpha: 0.6),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // CTA
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _register,
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
                              'Créer mon compte',
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

                    // OR
                    const AuthOrDivider(),
                    const SizedBox(height: 16),

                    // Google
                    const AuthGoogleButton(label: "S'inscrire avec Google"),
                    const SizedBox(height: 20),

                    // Login link
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Vous avez déjà un compte ? ',
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 13,
                                  color: kDark.withValues(alpha: 0.55),
                                ),
                              ),
                              TextSpan(
                                text: 'Se connecter',
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
