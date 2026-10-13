import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../models/onboarding_page_data.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/widgets/auth_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  /// Si fourni, appelé à la place de la navigation interne vers l'écran de
  /// connexion quand l'onboarding se termine (passé par `AuthGate`, qui
  /// reste ainsi seul propriétaire de la route racine). Si `null` (usage
  /// autonome, ex. tests), le comportement d'origine est conservé.
  const OnboardingScreen({super.key, this.onDone});

  final VoidCallback? onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _current = 0;

  /// Hauteur du logo compact dans la barre du haut.
  static const double _logoHeight = 40;

  void _goNext() {
    if (_current < OnboardingPageData.pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToLogin();
    }
  }

  void _skip() => _navigateToLogin();

  void _navigateToLogin() {
    if (widget.onDone != null) {
      widget.onDone!();
      return;
    }
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAuthBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  // Logo (zone de protection : 1/4 de sa hauteur). La
                  // largeur de 280 px de la charte ne tient pas dans cette
                  // barre à côté de « Passer » : version réduite.
                  Padding(
                    padding: const EdgeInsets.all(_logoHeight / 4),
                    child: Image.asset(
                      AuthLogo.assetPath,
                      height: _logoHeight,
                      semanticLabel: 'Hope Gestion',
                    ),
                  ),
                  const Spacer(),
                  // Passer (hidden on last page)
                  if (_current < OnboardingPageData.pages.length - 1)
                    GestureDetector(
                      onTap: _skip,
                      child: Text(
                        'Passer',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: kAuthText.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── PageView ─────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _current = i),
                itemCount: OnboardingPageData.pages.length,
                itemBuilder: (_, i) {
                  final page = OnboardingPageData.pages[i];
                  return _OnboardingPage(data: page);
                },
              ),
            ),

            // ── Dots ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  OnboardingPageData.pages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _current ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _current
                          ? kAuthPrimary
                          : kAuthPrimary.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // ── Button ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _goNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAuthPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        OnboardingPageData.pages[_current].buttonLabel,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 16,
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
            ),

            // ── Footer tagline ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 20),
              child: Text(
                OnboardingPageData.pages[_current].footerLabel,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  color: kAuthText.withValues(alpha: 0.45),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Individual page content ───────────────────────────────────────────────────

class _OnboardingPage extends StatelessWidget {
  final OnboardingPageData data;
  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Illustration
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Image.asset(data.imagePath, fit: BoxFit.contain),
            ),
          ),

          // Over-title
          Text(
            data.overTitle,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.8,
              color: kAuthPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.15,
              color: kAuthText,
            ),
          ),
          const SizedBox(height: 16),

          // Subtitle
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 14,
              height: 1.6,
              color: kAuthText.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
