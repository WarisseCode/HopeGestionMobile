import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_exception.dart';
import '../data/auth_repository.dart';
import '../data/auth_results.dart';
import '../widgets/auth_widgets.dart';

/// Saisie du code de vérification (OTP) envoyé par email, atteinte soit
/// juste après une inscription, soit depuis l'écran de connexion quand le
/// compte existe mais n'est pas encore vérifié.
///
/// [password] n'est conservé qu'en mémoire (champ de cet État, jamais
/// persisté) pour pouvoir enchaîner sur la connexion mobile une fois le code
/// validé (`AuthRepository.verifyEmail`) ; il est perdu quand cet écran est
/// démonté.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({
    super.key,
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  static const _resendCooldown = Duration(seconds: 30);

  final _otpCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  /// Message du backend pour le seul cas 400 que `resendOtp` puisse renvoyer
  /// en pratique une fois l'email déjà transmis (vérifié dans
  /// `AuthService.resendOtp` : "Cet email est déjà vérifié. Connectez-vous.")
  /// — affiché distinctement d'une erreur réseau/générique ([_error]), avec
  /// une invitation à se reconnecter plutôt qu'à réessayer un renvoi de code.
  String? _alreadyVerifiedMessage;

  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  @override
  void dispose() {
    _otpCtrl.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _submit() async {
    final otp = _otpCtrl.text.trim();
    if (otp.isEmpty) {
      setState(() => _error = 'Saisissez le code reçu par email.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _alreadyVerifiedMessage = null;
    });

    final result = await AuthRepository.instance.verifyEmail(
      widget.email,
      otp,
      widget.password,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    switch (result) {
      case VerifyEmailSuccess():
        // Rien à faire : AuthGate réagit au changement d'état
        // (authenticated) et ramène la pile de navigation à la racine.
        break;
      case VerifyEmailFailure(message: final message):
        setState(() => _error = message);
      case VerifyEmailLoginFailed(loginResult: final loginResult):
        setState(
          () => _error = switch (loginResult) {
            LoginInvalidCredentials(message: final m) => m,
            LoginFailure(message: final m) => m,
            _ => 'Code validé, mais la connexion a échoué. Réessayez.',
          },
        );
    }
  }

  Future<void> _resend() async {
    if (_cooldownSeconds > 0) return;

    final result = await AuthRepository.instance.resendOtp(widget.email);
    if (!mounted) return;

    switch (result) {
      case ResendOtpSuccess():
        setState(() {
          _error = null;
          _alreadyVerifiedMessage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Un nouveau code a été envoyé.')),
        );
        _startCooldown();
      case ResendOtpFailure(message: final message, type: final type):
        setState(() {
          // Seul 400 que `AuthService.resendOtp` puisse renvoyer une fois
          // l'email déjà transmis (voir doc du champ) : pas une erreur à
          // "réessayer", l'utilisateur doit se reconnecter directement.
          if (type == ApiExceptionType.validation) {
            _alreadyVerifiedMessage = message;
            _error = null;
          } else {
            _error = message;
            _alreadyVerifiedMessage = null;
          }
        });
    }
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = _resendCooldown.inSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _cooldownSeconds--;
        if (_cooldownSeconds <= 0) timer.cancel();
      });
    });
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
              const AuthLogo(),
              const SizedBox(height: 28),
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
                      'Vérifiez votre email',
                      style: GoogleFonts.syne(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: kDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Entrez le code à 6 chiffres envoyé à ${widget.email}.',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 13,
                        color: kDark.withValues(alpha: 0.55),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    const AuthFieldLabel('Code de vérification'),
                    const SizedBox(height: 6),
                    AuthTextField(
                      controller: _otpCtrl,
                      hint: '123456',
                      prefixIcon: Icons.pin_outlined,
                      keyboardType: TextInputType.number,
                    ),

                    if (_alreadyVerifiedMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kTeal.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: kTeal.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _alreadyVerifiedMessage!,
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 12,
                                color: kDark,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () => Navigator.of(
                                  context,
                                ).popUntil((route) => route.isFirst),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Aller à la connexion',
                                  style: GoogleFonts.ibmPlexSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: kTeal,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 12,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kTeal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Vérifier',
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Center(
                      child: TextButton(
                        onPressed: _cooldownSeconds > 0 ? null : _resend,
                        child: Text(
                          _cooldownSeconds > 0
                              ? 'Renvoyer le code (${_cooldownSeconds}s)'
                              : 'Renvoyer le code',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: kTeal,
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
