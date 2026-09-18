import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../core/design_system.dart';
import '../models/nouveau_bien_form.dart';

/// Étape 2 : Localisation du bien.
class BienStep2Localisation extends StatefulWidget {
  const BienStep2Localisation({super.key, required this.form});
  final NouveauBienForm form;

  @override
  State<BienStep2Localisation> createState() => _BienStep2LocalisationState();
}

class _BienStep2LocalisationState extends State<BienStep2Localisation> {
  late final TextEditingController _adresseCtrl;
  late final TextEditingController _quartierCtrl;
  late final TextEditingController _villeCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;

  @override
  void initState() {
    super.initState();
    _adresseCtrl = TextEditingController(text: widget.form.adresse);
    _quartierCtrl = TextEditingController(text: widget.form.quartier);
    _villeCtrl = TextEditingController(text: widget.form.ville);
    _latCtrl = TextEditingController(text: widget.form.latitude);
    _lngCtrl = TextEditingController(text: widget.form.longitude);

    _adresseCtrl.addListener(() => widget.form.adresse = _adresseCtrl.text);
    _quartierCtrl.addListener(() => widget.form.quartier = _quartierCtrl.text);
    _villeCtrl.addListener(() => widget.form.ville = _villeCtrl.text);
    _latCtrl.addListener(() => widget.form.latitude = _latCtrl.text);
    _lngCtrl.addListener(() => widget.form.longitude = _lngCtrl.text);
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
            items: NouveauBienForm.pays_
                .map((p) => AppDropdownItem(label: p, value: p))
                .toList(),
            onChanged: (v) => setState(() => widget.form.pays = v ?? 'Bénin'),
          ),
          const SizedBox(height: 20),

          const AppInfoBanner(
            text: 'Les coordonnées GPS sont facultatives et permettront d\'afficher le bien sur une carte.',
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
