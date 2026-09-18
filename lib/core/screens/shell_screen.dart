import 'package:flutter/material.dart';

import '../widgets/app_bottom_bar.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/biens/screens/biens_screen.dart';
import '../../features/locataires/screens/locataires_screen.dart';
import '../../features/finances/screens/finances_screen.dart';
import '../../features/documents/screens/documents_screen.dart';

/// Écran principal avec navigation par onglets.
/// Utilise un [IndexedStack] pour préserver l état de chaque onglet.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    DashboardScreen(),
    BiensScreen(),
    LocatairesScreen(),
    FinancesScreen(),
    DocumentsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Préserve l état des onglets (pas de rebuild)
          IndexedStack(index: _currentIndex, children: _screens),

          // Barre de nav flottante en bas
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: AppBottomBar(
                currentIndex: _currentIndex,
                onTap: (i) => setState(() => _currentIndex = i),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
