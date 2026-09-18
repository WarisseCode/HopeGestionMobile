/// Shared UI building-blocks used by LoginScreen and RegisterScreen.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kTeal = Color(0xFF00BFA5);
const Color kDark = Color(0xFF0E1F1C);

// ── Logo ──────────────────────────────────────────────────────────────────────

class AuthLogo extends StatelessWidget {
  const AuthLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: kTeal,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.home_work_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: 10),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Hope',
                style: GoogleFonts.syne(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: kDark,
                ),
              ),
              TextSpan(
                text: 'Gestion',
                style: GoogleFonts.syne(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: kTeal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Field label ───────────────────────────────────────────────────────────────

class AuthFieldLabel extends StatelessWidget {
  final String text;
  const AuthFieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.ibmPlexSans(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: kDark,
      ),
    );
  }
}

// ── Text field ────────────────────────────────────────────────────────────────

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: GoogleFonts.ibmPlexSans(fontSize: 14, color: kDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.ibmPlexSans(
          fontSize: 14,
          color: kDark.withValues(alpha: 0.35),
        ),
        prefixIcon: Icon(
          prefixIcon,
          size: 18,
          color: kDark.withValues(alpha: 0.4),
        ),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        filled: true,
        fillColor: const Color(0xFFF6F9F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDDE6E4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDDE6E4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kTeal, width: 1.5),
        ),
      ),
    );
  }
}

// ── OR divider ────────────────────────────────────────────────────────────────

class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: kDark.withValues(alpha: 0.12))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OU',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 11,
              letterSpacing: 1.2,
              color: kDark.withValues(alpha: 0.35),
            ),
          ),
        ),
        Expanded(child: Divider(color: kDark.withValues(alpha: 0.12))),
      ],
    );
  }
}

// ── Google button ─────────────────────────────────────────────────────────────

class AuthGoogleButton extends StatelessWidget {
  final String label;
  const AuthGoogleButton({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          side: BorderSide(color: kDark.withValues(alpha: 0.15)),
        ),
        icon: const _GoogleIcon(),
        label: Text(
          label,
          style: GoogleFonts.ibmPlexSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: kDark,
          ),
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(20, 20), painter: _GPainter());
  }
}

class _GPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    final rect = Offset.zero & size;
    const colors = [
      Color(0xFF4285F4),
      Color(0xFF34A853),
      Color(0xFFFBBC04),
      Color(0xFFEA4335),
    ];
    for (var i = 0; i < 4; i++) {
      p.color = colors[i];
      canvas.drawArc(rect, -1.57 + i * 1.57, 1.57, true, p);
    }
    p.color = Colors.white;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.35,
      p,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
