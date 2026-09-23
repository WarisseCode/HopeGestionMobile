import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../../auth/data/app_user.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/auth_results.dart';

/// Modification des informations personnelles (nom, prénom, email,
/// téléphone) — seuls champs éditables exposés par `PUT /auth/profile`
/// (voir `AuthRepository.updateProfile`). La photo de profil n'a aujourd'hui
/// aucune action d'édition dans `ProfilScreen` (pas d'icône crayon sur
/// l'avatar) : rien à désactiver ici, l'upload reste hors périmètre.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.user});

  final AppUser user;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final _nomCtrl = TextEditingController(text: widget.user.nom);
  late final _prenomCtrl = TextEditingController(text: widget.user.prenom);
  late final _emailCtrl = TextEditingController(text: widget.user.email);
  late final _telephoneCtrl = TextEditingController(
    text: widget.user.telephone ?? '',
  );
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _emailCtrl.dispose();
    _telephoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      // Seule validation que PUT /auth/profile fasse réellement lui-même
      // (vérifié en 4.1) : autant l'anticiper côté client.
      setState(() => _error = 'Email requis.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await AuthRepository.instance.updateProfile(
      nom: _nomCtrl.text.trim(),
      prenom: _prenomCtrl.text.trim(),
      email: email,
      telephone: _telephoneCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    switch (result) {
      case UpdateProfileSuccess():
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      case UpdateProfileValidationFailed(message: final message):
        setState(() => _error = message);
      case UpdateProfileFailure(message: final message):
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
                    'Informations personnelles',
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
                    label: 'Nom',
                    isRequired: true,
                    controller: _nomCtrl,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Prénom',
                    controller: _prenomCtrl,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Adresse e-mail',
                    isRequired: true,
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Téléphone',
                    controller: _telephoneCtrl,
                    keyboardType: TextInputType.phone,
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
                    label: 'Enregistrer',
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
