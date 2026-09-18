import 'package:flutter/material.dart';

import 'core/design_system.dart';
import 'core/theme/theme_controller.dart';
import 'features/onboarding/screens/onboarding_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HopeGestionApp());
}

class HopeGestionApp extends StatelessWidget {
  final Widget? home;

  const HopeGestionApp({super.key, this.home});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'HopeGestion Mobile',
          debugShowCheckedModeBanner: false,
          showPerformanceOverlay: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeController.instance.themeMode,
          // Flow par défaut : Onboarding → Login → Shell
          home: home ?? const OnboardingScreen(),
        );
      },
    );
  }
}
