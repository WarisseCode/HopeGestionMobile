import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../models/contact.dart';
import '../models/contacts_repository.dart';
import '../models/nouveau_locataire_form.dart';
import '../steps/locataire_step1_identite.dart';
import '../steps/locataire_step2_documents.dart';
import '../steps/locataire_step3_finances.dart';
import '../steps/locataire_step4_confirmation.dart';
import 'locataire_succes_screen.dart';

/// Écran plein écran du formulaire multi-étapes "Nouveau Locataire / Contact".
class NouveauLocataireScreen extends StatefulWidget {
  const NouveauLocataireScreen({super.key});

  @override
  State<NouveauLocataireScreen> createState() => _NouveauLocataireScreenState();
}

class _NouveauLocataireScreenState extends State<NouveauLocataireScreen> {
  final PageController _pageController = PageController();
  final NouveauLocataireForm _form = NouveauLocataireForm();
  int _currentStep = 0;

  static const List<AppStepItem> _steps = [
    AppStepItem(label: 'Identité', icon: LucideIcons.user),
    AppStepItem(label: 'Documents', icon: LucideIcons.file_text),
    AppStepItem(label: 'Finances', icon: LucideIcons.wallet),
    AppStepItem(label: 'Confirmer', icon: LucideIcons.circle_check),
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
        _showError(
          'Veuillez sélectionner un propriétaire et renseigner le nom et prénom.',
        );
        return;
      }
    } else if (_currentStep == 3) {
      // Enregistrer et afficher le succès
      ContactsRepository.instance.add(
        Contact(
          id: 'c-${DateTime.now().millisecondsSinceEpoch}',
          initials: _form.initials,
          name: _form.nomComplet,
          info: _form.typeProfile,
          type: _form.typeProfile == 'Locataire'
              ? ContactType.tenant
              : ContactType.owner,
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => LocataireSuccesScreen(
            nomLocataire: _form.nomComplet,
            typeProfile: _form.typeProfile,
          ),
        ),
      );
      return;
    }

    if (_currentStep < _steps.length - 1) {
      _goToStep(_currentStep + 1);
    }
  }

  void _onSkip() {
    FocusScope.of(context).unfocus();
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
        title: const Text('Abandonner la création ?'),
        content: const Text(
          'Toutes les informations saisies pour ce profil seront perdues.',
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
    final isOptionalStep = _currentStep == 1 || _currentStep == 2;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header Stepper
            AppStepperHeader(
              steps: _steps,
              currentStep: _currentStep,
              title: 'Nouveau locataire',
              subtitle: 'Création d\'une fiche contact',
              onClose: _confirmExit,
            ),

            // Form Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  LocataireStep1Identite(form: _form),
                  LocataireStep2Documents(form: _form),
                  LocataireStep3Finances(form: _form),
                  LocataireStep4Confirmation(
                    form: _form,
                    onGoToStep: _goToStep,
                  ),
                ],
              ),
            ),

            // Bottom Nav Bar
            AppStepperNavBar(
              onBack: _onBack,
              onNext: _onNext,
              onSkip: isOptionalStep ? _onSkip : null,
              backLabel: _currentStep == 0 ? 'Annuler' : 'Précédent',
              nextLabel: isLastStep ? 'Enregistrer' : 'Suivant',
            ),
          ],
        ),
      ),
    );
  }
}
