import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../../auth/data/auth_repository.dart';
import '../../locataires/data/owners_repository.dart';
import '../../locataires/data/locataire_results.dart';
import '../../locataires/models/owner.dart';
import '../data/biens_repository.dart';
import '../data/biens_results.dart';
import '../models/nouveau_immeuble_form.dart';
import '../steps/immeuble_step1_identite.dart';
import '../steps/immeuble_step2_localisation.dart';
import '../steps/immeuble_step3_proprietaire.dart';
import 'immeuble_cree_screen.dart';

/// Écran plein écran du formulaire "Nouvel immeuble" (3 étapes, réduites
/// aux champs réels de `buildings` — voir phase 4.4 §0/§1). La création
/// d'un lot est un flux séparé, enchaîné après succès (voir
/// `ImmeubleCreeScreen`), pas une étape supplémentaire ici.
class NouveauBienScreen extends StatefulWidget {
  const NouveauBienScreen({super.key});

  @override
  State<NouveauBienScreen> createState() => _NouveauBienScreenState();
}

class _NouveauBienScreenState extends State<NouveauBienScreen> {
  final PageController _pageController = PageController();
  final NouveauImmeubleForm _form = NouveauImmeubleForm();
  late final OwnersRepository _ownersRepository;
  int _currentStep = 0;
  bool _submitting = false;

  List<Owner> _owners = [];
  bool _ownersLoading = true;
  String? _ownersError;

  static const List<AppStepItem> _steps = [
    AppStepItem(label: 'Identité', icon: LucideIcons.building),
    AppStepItem(label: 'Localisation', icon: LucideIcons.map_pin),
    AppStepItem(label: 'Propriétaire', icon: LucideIcons.user_check),
  ];

  @override
  void initState() {
    super.initState();
    _ownersRepository = OwnersRepository(
      apiClient: AuthRepository.instance.apiClient,
    );
    _loadOwners();
  }

  Future<void> _loadOwners() async {
    setState(() {
      _ownersLoading = true;
      _ownersError = null;
    });
    final result = await _ownersRepository.list();
    if (!mounted) return;
    switch (result) {
      case OwnersListSuccess(owners: final owners):
        setState(() {
          _owners = owners;
          _ownersLoading = false;
          _form.ownerSelectionRequired = owners.length > 1;
          if (owners.length == 1) {
            _form.ownerId = owners.first.id;
            _form.ownerName = owners.first.displayName;
          }
        });
      case OwnersListFailure(message: final message):
        setState(() {
          _ownersError = message;
          _ownersLoading = false;
        });
    }
  }

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

  Future<void> _onNext() async {
    FocusScope.of(context).unfocus();

    if (_currentStep == 0) {
      if (!_form.isStep1Valid()) {
        _showError('Veuillez renseigner le nom de l\'immeuble.');
        return;
      }
    } else if (_currentStep == 1) {
      if (!_form.isStep2Valid()) {
        _showError('Veuillez renseigner l\'adresse et la ville.');
        return;
      }
    } else if (_currentStep == 2) {
      if (!_form.isStep3Valid()) {
        _showError('Veuillez sélectionner un propriétaire.');
        return;
      }
      await _submit();
      return;
    }

    if (_currentStep < _steps.length - 1) {
      _goToStep(_currentStep + 1);
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);

    final result = await BiensRepository.instance.createImmeuble(
      nom: _form.nom.trim(),
      type: _form.type,
      nombreEtages: _form.nombreEtages,
      totalLots: _form.totalLots,
      description: _form.description.trim(),
      adresse: _form.adresse.trim(),
      quartier: _form.quartier.trim(),
      ville: _form.ville.trim(),
      pays: _form.pays,
      latitude: _form.latitude,
      longitude: _form.longitude,
      ownerId: _form.ownerId,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    switch (result) {
      case CreateImmeubleSuccess(id: final id):
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ImmeubleCreeScreen(
              immeubleId: id,
              nomImmeuble: _form.nom.trim(),
            ),
          ),
        );
      case CreateImmeubleValidationFailed(message: final message):
        _showError(message);
      case CreateImmeubleFailure(message: final message):
        _showError(message);
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
            AppStepperHeader(
              steps: _steps,
              currentStep: _currentStep,
              title: 'Nouvel immeuble',
              subtitle: 'Création d\'un immeuble',
              onClose: _confirmExit,
            ),

            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  ImmeubleStep1Identite(form: _form),
                  ImmeubleStep2Localisation(form: _form),
                  ImmeubleStep3Proprietaire(
                    form: _form,
                    owners: _owners,
                    ownersLoading: _ownersLoading,
                    ownersError: _ownersError,
                    onRetryOwners: _loadOwners,
                  ),
                ],
              ),
            ),

            AppStepperNavBar(
              onBack: _submitting ? () {} : _onBack,
              onNext: _submitting ? () {} : _onNext,
              backLabel: _currentStep == 0 ? 'Annuler' : 'Précédent',
              nextLabel: _submitting
                  ? 'Enregistrement...'
                  : (isLastStep ? 'Enregistrer' : 'Suivant'),
              isNextEnabled: !_submitting,
            ),
          ],
        ),
      ),
    );
  }
}
