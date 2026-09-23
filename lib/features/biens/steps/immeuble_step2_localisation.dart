import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../core/design_system.dart';
import '../models/nouveau_immeuble_form.dart';

/// Étape 2 : Localisation de l'immeuble.
class ImmeubleStep2Localisation extends StatefulWidget {
  const ImmeubleStep2Localisation({super.key, required this.form});
  final NouveauImmeubleForm form;

  @override
  State<ImmeubleStep2Localisation> createState() =>
      _ImmeubleStep2LocalisationState();
}

class _ImmeubleStep2LocalisationState
    extends State<ImmeubleStep2Localisation> {
  late final TextEditingController _adresseCtrl;
  late final TextEditingController _quartierCtrl;
  late final TextEditingController _villeCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;

  @override
  void initState() {
    super.initState();
    final f = widget.form;
    _adresseCtrl = TextEditingController(text: f.adresse);
    _quartierCtrl = TextEditingController(text: f.quartier);
    _villeCtrl = TextEditingController(text: f.ville);
    _latCtrl = TextEditingController(text: f.latitude?.toString() ?? '');
    _lngCtrl = TextEditingController(text: f.longitude?.toString() ?? '');

    _adresseCtrl.addListener(() => f.adresse = _adresseCtrl.text);
    _quartierCtrl.addListener(() => f.quartier = _quartierCtrl.text);
    _villeCtrl.addListener(() => f.ville = _villeCtrl.text);
    _latCtrl.addListener(() => f.latitude = double.tryParse(_latCtrl.text));
    _lngCtrl.addListener(() => f.longitude = double.tryParse(_lngCtrl.text));
  }

  @override
  void dispose() {
    _adresseCtrl.dispose();
    _quartierCtrl.dispose();
    _villeCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ÉTAPE 2',
            style: AppTypography.labelUppercase(
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 4),
          Text('Localisation', style: AppTypography.titleScreen()),
          const SizedBox(height: 24),

          AppTextField(
            controller: _adresseCtrl,
            hintText: 'Ex : 123 Rue de la Paix',
            label: 'Adresse complète',
            isRequired: true,
            prefixIcon: Icon(
              LucideIcons.map_pin,
              size: 18,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 20),

          AppTextField(
            controller: _quartierCtrl,
            hintText: 'Ex : Akpakpa',
            label: 'Quartier',
          ),
          const SizedBox(height: 20),

          AppTextField(
            controller: _villeCtrl,
            hintText: 'Ex : Cotonou',
            label: 'Ville',
            isRequired: true,
          ),
          const SizedBox(height: 20),

          AppDropdown<String>(
            label: 'Pays',
            value: widget.form.pays,
            items: NouveauImmeubleForm.paysListe
                .map((p) => AppDropdownItem(label: p, value: p))
                .toList(),
            onChanged: (v) => setState(() => widget.form.pays = v ?? 'Bénin'),
          ),
          const SizedBox(height: 20),

          const AppInfoBanner(
            text: 'Les coordonnées GPS sont facultatives et permettront '
                'd\'afficher le bien sur une carte.',
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _latCtrl,
                  hintText: '6.3702',
                  label: 'Latitude',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  controller: _lngCtrl,
                  hintText: '2.3912',
                  label: 'Longitude',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
