import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:signature/signature.dart';

import '../../../core/design_system.dart';
import '../../../core/network/api_exception.dart';
import '../data/baux_repository.dart';
import '../data/baux_results.dart';
import '../models/bail_detail.dart';
import 'bail_actions.dart';

/// Signature électronique d'un bail — `POST /api/locations/:id/sign`.
///
/// Écran dédié (pas une feuille) : le pad a besoin de place, et une feuille
/// modale capterait les gestes verticaux du tracé. Le pad est fourni par le
/// paquet `signature` (canvas pur Dart, export PNG direct) ; le PNG est
/// envoyé en base64, préfixé `data:image/png;base64,` par le repository.
///
/// Fermeture : `Navigator.pop` avec un [IssueActionBail] (voir
/// [EnvoiActionBail]).
class SignerBailScreen extends StatefulWidget {
  const SignerBailScreen({super.key, required this.bail});

  final BailDetail bail;

  @override
  State<SignerBailScreen> createState() => _SignerBailScreenState();
}

class _SignerBailScreenState extends State<SignerBailScreen>
    with EnvoiActionBail {
  final _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    strokeCap: StrokeCap.round,
    strokeJoin: StrokeJoin.round,
    // Fond blanc opaque : signature lisible quel que soit le fond du
    // document ou de l'écran qui l'affichera.
    exportBackgroundColor: Colors.white,
    exportPenColor: Colors.black,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _effacer() {
    _controller.clear();
    setState(() => erreur = null);
  }

  Future<void> _confirmer() async {
    if (envoiEnCours || _controller.isEmpty) return;
    _controller.disabled = true;
    await envoyer(() async {
      final Uint8List? png = await _controller.toPngBytes();
      if (png == null || png.isEmpty) {
        // Ne devrait pas arriver (pad non vide vérifié ci-dessus). Rien
        // n'a été envoyé : issue certaine.
        return const ActionBailFailure(
          'Impossible de lire la signature. Effacez et signez à nouveau.',
          ApiExceptionType.unknown,
        );
      }
      return BauxRepository.instance.signerBail(
        widget.bail.id,
        signatureImageBase64: base64Encode(png),
      );
    });
    if (mounted) _controller.disabled = false;
  }

  @override
  Widget build(BuildContext context) {
    return avecRetourControle(
      Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: envoiEnCours ? null : fermer,
                      icon: Icon(
                        LucideIcons.arrow_left,
                        color: AppColors.foreground,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Signer le bail',
                        style: AppTypography.titleScreen(fontSize: 20),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.bail.referenceBail ?? 'Bail n°${widget.bail.id}',
                        style: AppTypography.body(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      const AppInfoBanner(
                        text:
                            'Signez dans le cadre ci-dessous. Le bail passera '
                            'à « signé » et le propriétaire sera notifié.',
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Signature(
                            key: const Key('signature-pad'),
                            controller: _controller,
                            backgroundColor: Colors.white,
                            placeholder: Text(
                              'Signez ici',
                              style: AppTypography.bodySmall(
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (erreur != null) ...[
                        const SizedBox(height: 14),
                        MessageErreurActionBail(erreur!),
                      ],
                      const SizedBox(height: 14),
                      // Le bouton suit le contenu du pad (vide → désactivé).
                      ValueListenableBuilder<List<Point>>(
                        valueListenable: _controller,
                        builder: (context, points, _) {
                          final vide = points.isEmpty;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AppButton.primary(
                                label: 'Confirmer',
                                isLoading: envoiEnCours,
                                onPressed: envoiEnCours || vide
                                    ? null
                                    : _confirmer,
                              ),
                              const SizedBox(height: 10),
                              AppButton.secondary(
                                label: 'Effacer',
                                onPressed: envoiEnCours || vide
                                    ? null
                                    : _effacer,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
