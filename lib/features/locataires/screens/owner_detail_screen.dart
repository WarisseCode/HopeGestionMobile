import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/config/app_config.dart';
import '../../../core/design_system.dart';
import '../../../core/network/api_exception.dart';
import '../../biens/data/biens_repository.dart';
import '../../biens/data/biens_results.dart';
import '../../biens/models/immeuble.dart';
import '../../biens/screens/immeuble_detail_screen.dart';
import '../../biens/widgets/immeuble_card.dart';
import '../data/locataire_results.dart';
import '../data/owners_repository.dart';
import '../models/owner.dart';

/// Fiche d'un propriétaire en lecture seule — coordonnées via
/// `GET /api/owners/:id`, biens filtrés côté client sur
/// `BiensRepository.instance.immeubles` (`ownerId == owner.id`).
/// `GET /api/owners/:id/properties` n'est pas utilisé : données faussées
/// côté backend (pas de filtre corbeille, collision `total_lots`).
/// Pas de modification/suppression ici (hors périmètre).
class OwnerDetailScreen extends StatefulWidget {
  const OwnerDetailScreen({super.key, required this.ownerId});

  final int ownerId;

  @override
  State<OwnerDetailScreen> createState() => _OwnerDetailScreenState();
}

class _OwnerDetailScreenState extends State<OwnerDetailScreen> {
  bool _loading = true;
  String? _errorTitle;
  String? _errorMessage;
  ApiExceptionType? _errorType;
  Owner? _owner;

  bool _biensLoading = false;
  String? _biensError;

  @override
  void initState() {
    super.initState();
    _load();
    if (BiensRepository.instance.immeubles.isEmpty) {
      _loadBiens();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorTitle = null;
      _errorMessage = null;
      _errorType = null;
    });
    final result = await OwnersRepository.instance.getDetail(widget.ownerId);
    if (!mounted) return;
    switch (result) {
      case OwnerDetailSuccess(owner: final owner):
        setState(() {
          _owner = owner;
          _loading = false;
        });
      case OwnerDetailFailure(message: final message, type: final type):
        final (title, detail) = switch (type) {
          ApiExceptionType.forbidden => (
            'Accès refusé à ce propriétaire',
            'Ce propriétaire n\'est pas rattaché à votre compte.',
          ),
          ApiExceptionType.notFound => (
            'Propriétaire introuvable',
            'Ce propriétaire n\'existe pas ou a été désactivé.',
          ),
          ApiExceptionType.network ||
          ApiExceptionType.timeout => ('Connexion impossible', message),
          _ => ('Impossible de charger ce propriétaire', message),
        };
        setState(() {
          _errorTitle = title;
          _errorMessage = detail;
          _errorType = type;
          _loading = false;
        });
    }
  }

  Future<void> _loadBiens() async {
    setState(() {
      _biensLoading = true;
      _biensError = null;
    });
    final result = await BiensRepository.instance.listImmeubles();
    if (!mounted) return;
    setState(() {
      _biensLoading = false;
      _biensError = switch (result) {
        ImmeublesListSuccess() => null,
        ImmeublesListFailure(message: final message) => message,
      };
    });
  }

  /// 404 = propriétaire désactivé/inexistant, 403 = non rattaché : réessayer
  /// ne changera rien, seul le retour est proposé.
  bool get _retryable =>
      _errorType != ApiExceptionType.forbidden &&
      _errorType != ApiExceptionType.notFound;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final owner = _owner;
    if (_errorTitle != null || owner == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _topBar(context, ''),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _errorTitle ??
                              'Impossible de charger ce propriétaire',
                          textAlign: TextAlign.center,
                          style: AppTypography.titleScreen(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage ?? 'Erreur inconnue.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall(
                            color: AppColors.mutedForeground,
                          ),
                        ),
                        if (_retryable) ...[
                          const SizedBox(height: 20),
                          AppButton.primary(
                            label: 'Réessayer',
                            onPressed: _load,
                            isFullWidth: false,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(context, owner.displayName),
            Expanded(
              child: ListenableBuilder(
                listenable: BiensRepository.instance,
                builder: (context, _) {
                  final biens = BiensRepository.instance.immeubles
                      .where((i) => i.ownerId == owner.id)
                      .toList();
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                    children: [
                      _identityCard(owner),
                      const SizedBox(height: 16),
                      _coordonneesCard(owner),
                      const SizedBox(height: 20),
                      Text(
                        'BIENS (${biens.length})',
                        style: AppTypography.labelUppercase(
                          color: AppColors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._biensSection(biens),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(LucideIcons.arrow_left, color: AppColors.foreground),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: AppTypography.titleScreen(fontSize: 20),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _identityCard(Owner owner) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          _avatar(owner),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  owner.displayName,
                  style: AppTypography.titleScreen(fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  _typeLabel(owner.type),
                  style: AppTypography.bodySmall(
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(Owner owner) {
    final photo = owner.photo;
    if (photo == null || photo.isEmpty) return _initialsAvatar(owner);
    return ClipOval(
      child: Image.network(
        AppConfig.resolveFileUrl(photo),
        width: 58,
        height: 58,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _initialsAvatar(owner),
      ),
    );
  }

  Widget _initialsAvatar(Owner owner) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: AppColors.positiveSoft,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          owner.initials,
          style: AppTypography.titleScreen(
            fontSize: 22,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _coordonneesCard(Owner owner) {
    final adresse = [owner.address, owner.city]
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .join(', ');
    final lines = <(String, String)>[
      ('Téléphone', _orDash(owner.phone)),
      ('Email', _orDash(owner.email)),
      ('Adresse', adresse.isEmpty ? 'Non renseignée' : adresse),
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COORDONNÉES',
            style: AppTypography.labelUppercase(
              color: AppColors.mutedForeground,
              fontSize: 10.5,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < lines.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(
                      lines[i].$1,
                      style: AppTypography.bodySmall(
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      lines[i].$2,
                      textAlign: TextAlign.right,
                      style: AppTypography.bodySmall(
                        color: AppColors.foreground,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            if (i < lines.length - 1)
              Divider(color: AppColors.border, height: 1),
          ],
        ],
      ),
    );
  }

  List<Widget> _biensSection(List<Immeuble> biens) {
    if (biens.isEmpty && _biensLoading) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      ];
    }
    if (biens.isEmpty && _biensError != null) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(
                'Impossible de charger les biens',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall(color: AppColors.foreground),
              ),
              const SizedBox(height: 4),
              Text(
                _biensError!,
                textAlign: TextAlign.center,
                style: AppTypography.caption(color: AppColors.mutedForeground),
              ),
              const SizedBox(height: 12),
              AppButton.primary(
                label: 'Réessayer',
                onPressed: _loadBiens,
                isFullWidth: false,
              ),
            ],
          ),
        ),
      ];
    }
    if (biens.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text(
              'Aucun bien rattaché à ce propriétaire.',
              style: AppTypography.bodySmall(color: AppColors.mutedForeground),
            ),
          ),
        ),
      ];
    }
    return [
      for (final immeuble in biens) ...[
        ImmeubleCard(
          immeuble: immeuble,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ImmeubleDetailScreen(immeubleId: immeuble.id),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    ];
  }
}

String _orDash(String? value) =>
    value == null || value.trim().isEmpty ? 'Non renseigné' : value.trim();

String _typeLabel(String? type) {
  switch (type) {
    case null:
    case '':
    case 'individual':
      return 'Particulier';
    case 'company':
      return 'Société';
    default:
      return type;
  }
}
