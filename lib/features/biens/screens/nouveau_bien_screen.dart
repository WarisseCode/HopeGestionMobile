import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../models/bien.dart';
import '../models/biens_repository.dart';
import '../models/nouveau_bien_form.dart';
import '../steps/bien_step1_identite.dart';
import '../steps/bien_step2_localisation.dart';
import '../steps/bien_step3_gestion.dart';
import '../steps/bien_step4_medias.dart';
import 'bien_succes_screen.dart';

/// Écran plein écran du formulaire multi-étapes "Nouveau Bien".
class NouveauBienScreen extends StatefulWidget {
  const NouveauBienScreen({super.key});

  @override
  State<NouveauBienScreen> createState() => _NouveauBienScreenState();
}

class _NouveauBienScreenState extends State<NouveauBienScreen> {
  final PageController _pageController = PageController();
  final NouveauBienForm _form = NouveauBienForm();
  int _currentStep = 0;

  static const List<AppStepItem> _steps = [
    AppStepItem(label: 'Identité', icon: LucideIcons.building),
    AppStepItem(label: 'Localisation', icon: LucideIcons.map_pin),
    AppStepItem(label: 'Gestion', icon: LucideIcons.user_check),
    AppStepItem(label: 'Médias', icon: LucideIcons.image),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.circle_alert, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
      ),
    );
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onNext() {
    FocusScope.of(context).unfocus();

    if (_currentStep == 0) {
      if (!_form.isStep1Valid()) {
        _showError('Veuillez renseigner le nom du bien et au moins 1 lot.');
        return;
      }
    } else if (_currentStep == 1) {
      if (!_form.isStep2Valid()) {
        _showError('Veuillez renseigner la ville du bien.');
        return;
      }
    } else if (_currentStep == 2) {
      if (!_form.isStep3Valid()) {
        _showError('Veuillez sélectionner un propriétaire.');
        return;
      }
    } else if (_currentStep == 3) {
      // Terminer et enregistrer
      BiensRepository.instance.add(
        Bien(
          id: 'prop-${DateTime.now().millisecondsSinceEpoch}',
          name: _form.nom,
          type:
              '${_form.type} · ${_form.nbLots} lot'
              '${_form.nbLots > 1 ? 's' : ''}',
          price: 'Loyer à définir',
          status: BienStatus.vacant,
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => BienSuccesScreen(nomBien: _form.nom)),
      );
      return;
    }

    if (_currentStep < _steps.length - 1) {
      _goToStep(_currentStep + 1);
    }
  }

  void _onBack() {
    FocusScope.of(context).unfocus();
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    } else {
      _confirmExit();
    }
  }

  void _confirmExit() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abandonner la saisie ?'),
        content: const Text(
          'Toutes les informations renseignées seront perdues.',
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Continuer la saisie'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: Text('Quitter', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLastStep = _currentStep == _steps.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header Stepper
            AppStepperHeader(
              steps: _steps,
              currentStep: _currentStep,
              title: 'Nouveau bien',
              subtitle: 'Création d\'un bien immobilier',
              onClose: _confirmExit,
            ),

            // Form Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  BienStep1Identite(form: _form),
                  BienStep2Localisation(form: _form),
                  BienStep3Gestion(form: _form),
                  BienStep4Medias(form: _form),
                ],
              ),
            ),

            // Bottom Nav Bar
            AppStepperNavBar(
              onBack: _onBack,
              onNext: _onNext,
              backLabel: _currentStep == 0 ? 'Annuler' : 'Précédent',
              nextLabel: isLastStep ? 'Enregistrer' : 'Suivant',
              onSkip: isLastStep ? _onNext : null,
            ),
          ],
        ),
      ),
    );
  }
}
