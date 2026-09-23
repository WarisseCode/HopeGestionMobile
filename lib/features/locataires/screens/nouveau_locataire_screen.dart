import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../../auth/data/auth_repository.dart';
import '../data/locataire_results.dart';
import '../data/locataires_repository.dart';
import '../data/owners_repository.dart';
import '../models/nouveau_locataire_form.dart';
import '../models/owner.dart';
import '../steps/locataire_step1_identite.dart';
import '../steps/locataire_step2_documents.dart';
import '../steps/locataire_step3_finances.dart';
import '../steps/locataire_step4_confirmation.dart';
import 'locataire_succes_screen.dart';

/// Écran plein écran du formulaire multi-étapes "Nouveau Locataire".
/// Branché sur `LocatairesRepository.create` (phase 4.3) — le sélecteur
/// propriétaire (étape 1) est alimenté par `GET /owners` via
/// `OwnersRepository`.
class NouveauLocataireScreen extends StatefulWidget {
  const NouveauLocataireScreen({super.key});

  @override
  State<NouveauLocataireScreen> createState() => _NouveauLocataireScreenState();
}

class _NouveauLocataireScreenState extends State<NouveauLocataireScreen> {
  final PageController _pageController = PageController();
  final NouveauLocataireForm _form = NouveauLocataireForm();
  late final OwnersRepository _ownersRepository;
  int _currentStep = 0;
  bool _submitting = false;

  List<Owner> _owners = [];
  bool _ownersLoading = true;
  String? _ownersError;

  static const List<AppStepItem> _steps = [
    AppStepItem(label: 'Identité', icon: LucideIcons.user),
    AppStepItem(label: 'Documents', icon: LucideIcons.file_text),
    AppStepItem(label: 'Finances', icon: LucideIcons.wallet),
    AppStepItem(label: 'Confirmer', icon: LucideIcons.circle_check),
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
          // Un seul propriétaire : résolu automatiquement côté serveur
          // (tenantGuard.ts) — pré-sélectionné ici uniquement pour
          // l'affichage du récapitulatif (étape 4), pas requis pour la
          // validité de l'étape 1.
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
        _showError(
          _form.ownerSelectionRequired && _form.ownerId == null
              ? 'Veuillez sélectionner un propriétaire et renseigner le nom, prénom et téléphone.'
              : 'Veuillez renseigner le nom, le prénom et le téléphone.',
        );
        return;
      }
    } else if (_currentStep == 3) {
      await _submit();
      return;
    }

    if (_currentStep < _steps.length - 1) {
      _goToStep(_currentStep + 1);
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);

    final result = await LocatairesRepository.instance.create(
      nom: _form.nom.trim(),
      prenoms: _form.prenom.trim(),
      telephonePrincipal: _form.telephone.trim(),
      email: _form.email.trim(),
      nationalite: _form.nationalite.trim(),
      adresseActuelle: _form.adresse.trim(),
      typePiece: _form.typeId,
      numeroPiece: _form.numeroId.trim(),
      dateExpirationPiece: _form.dateExpiration.trim(),
      type: _form.typeProfile,
      modePaiementPreferentiel: _form.modePaiement,
      paiementEchelonne: _form.paiementEchelonne,
      ownerId: _form.ownerId,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    switch (result) {
      case CreateLocataireSuccess():
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => LocataireSuccesScreen(
              nomLocataire: _form.nomComplet,
              typeProfile: _form.typeProfile,
            ),
          ),
        );
      case CreateLocataireDuplicate(message: final message):
        _showError(message);
      case CreateLocataireValidationFailed(message: final message):
        _showError(message);
      case CreateLocataireFailure(message: final message):
        _showError(message);
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
                  LocataireStep1Identite(
                    form: _form,
                    owners: _owners,
                    ownersLoading: _ownersLoading,
                    ownersError: _ownersError,
                    onRetryOwners: _loadOwners,
                  ),
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
              onBack: _submitting ? () {} : _onBack,
              onNext: _submitting ? () {} : _onNext,
              onSkip: isOptionalStep ? _onSkip : null,
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
