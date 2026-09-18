import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/onboarding_page_data.dart';
import '../../auth/screens/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _current = 0;

  static const _teal = Color(0xFF00BFA5);
  static const _bgColor = Color(0xFFEAF7F5);
  static const _dark = Color(0xFF0E1F1C);

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
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  // Logo
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _teal,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.home_work_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Hope ',
                          style: GoogleFonts.syne(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _dark,
                          ),
                        ),
                        TextSpan(
                          text: 'Gestion',
                          style: GoogleFonts.syne(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _teal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Passer (hidden on last page)
                  if (_current < OnboardingPageData.pages.length - 1)
                    GestureDetector(
                      onTap: _skip,
                      child: Text(
                        'Passer',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _dark.withValues(alpha: 0.5),
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
                          ? _teal
                          : _teal.withValues(alpha: 0.25),
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
                    backgroundColor: _teal,
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
                        style: GoogleFonts.ibmPlexSans(
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
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 12,
                  color: _dark.withValues(alpha: 0.45),
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

  static const _teal = Color(0xFF00BFA5);
  static const _dark = Color(0xFF0E1F1C);

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
            style: GoogleFonts.ibmPlexSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.8,
              color: _teal,
            ),
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.syne(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.15,
              color: _dark,
            ),
          ),
          const SizedBox(height: 16),

          // Subtitle
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 14,
              height: 1.6,
              color: _dark.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
