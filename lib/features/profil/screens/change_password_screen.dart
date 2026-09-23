import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/auth_results.dart';

/// `POST /auth/change-password`. Le backend n'exige que 6 caractères
/// minimum pour le nouveau mot de passe ici (règle `express-validator` de
/// la route, vérifiée en 4.1) — plus permissif que la politique appliquée à
/// l'inscription (8 car. + majuscule/minuscule/chiffre). Le texte d'aide
/// reflète donc la règle réellement appliquée par CETTE route, pas celle de
/// `register`.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_currentCtrl.text.isEmpty || _newCtrl.text.isEmpty) {
      setState(() => _error = 'Renseignez le mot de passe actuel et le nouveau.');
      return;
    }
    if (_newCtrl.text != _confirmCtrl.text) {
      setState(
        () => _error = 'La confirmation ne correspond pas au nouveau mot de passe.',
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await AuthRepository.instance.changePassword(
      currentPassword: _currentCtrl.text,
      newPassword: _newCtrl.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    switch (result) {
      case ChangePasswordSuccess():
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mot de passe modifié.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      case ChangePasswordWrongCurrent(message: final message):
        setState(() => _error = message);
      case ChangePasswordValidationFailed(message: final message):
        setState(() => _error = message);
      case ChangePasswordFailure(message: final message):
        setState(() => _error = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      LucideIcons.arrow_left,
                      color: AppColors.foreground,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Changer le mot de passe',
                    style: AppTypography.titleScreen(fontSize: 20),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                children: [
                  AppTextField(
                    label: 'Mot de passe actuel',
                    isRequired: true,
                    controller: _currentCtrl,
                    obscureText: true,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Nouveau mot de passe',
                    isRequired: true,
                    controller: _newCtrl,
                    obscureText: true,
                    helperText: '6 caractères minimum',
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Confirmer le nouveau mot de passe',
                    isRequired: true,
                    controller: _confirmCtrl,
                    obscureText: true,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _error!,
                      style: AppTypography.bodySmall(color: AppColors.error),
                    ),
                  ],
                  const SizedBox(height: 24),
                  AppButton.primary(
                    label: 'Modifier le mot de passe',
                    isLoading: _loading,
                    onPressed: _loading ? null : _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
