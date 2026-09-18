import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../core/design_system.dart';
import '../models/nouveau_bien_form.dart';

/// Étape 1 : Identité du bien (nom, type, étages, lots, description).
class BienStep1Identite extends StatefulWidget {
  const BienStep1Identite({super.key, required this.form});
  final NouveauBienForm form;

  @override
  State<BienStep1Identite> createState() => _BienStep1IdentiteState();
}

class _BienStep1IdentiteState extends State<BienStep1Identite> {
  late final TextEditingController _nomCtrl;
  late final TextEditingController _etagesCtrl;
  late final TextEditingController _lotsCtrl;
  late final TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _nomCtrl = TextEditingController(text: widget.form.nom);
    _etagesCtrl = TextEditingController(text: widget.form.nbEtages.toString());
    _lotsCtrl = TextEditingController(
      text: widget.form.nbLots == 0 ? '' : widget.form.nbLots.toString(),
    );
    _descCtrl = TextEditingController(text: widget.form.description);

    _nomCtrl.addListener(() => widget.form.nom = _nomCtrl.text);
    _etagesCtrl.addListener(
      () => widget.form.nbEtages = int.tryParse(_etagesCtrl.text) ?? 0,
    );
    _lotsCtrl.addListener(
      () => widget.form.nbLots = int.tryParse(_lotsCtrl.text) ?? 0,
    );
    _descCtrl.addListener(() => widget.form.description = _descCtrl.text);
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _etagesCtrl.dispose();
    _lotsCtrl.dispose();
    _descCtrl.dispose();
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
            'ÉTAPE 1',
            style: AppTypography.labelUppercase(
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 4),
          Text('Identité du bien', style: AppTypography.titleScreen()),
          const SizedBox(height: 24),

          // Nom
          AppTextField(
            controller: _nomCtrl,
            hintText: 'Ex : Résidence Les Palmiers',
            label: 'Nom de l\'immeuble',
            isRequired: true,
            prefixIcon: Icon(
              LucideIcons.building,
              size: 18,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 20),

          // Type
          AppDropdown<String>(
            label: 'Type de bien',
            isRequired: true,
            value: widget.form.type,
            items: NouveauBienForm.typesBien
                .map((t) => AppDropdownItem(label: t, value: t))
                .toList(),
            onChanged: (v) => setState(() => widget.form.type = v ?? ''),
          ),
          const SizedBox(height: 20),

          // Nb étages
          AppTextField(
            controller: _etagesCtrl,
            hintText: '0',
            label: 'Nombre d\'étages',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            helperText: 'Indiquez 0 si le bien est de plain-pied',
          ),
          const SizedBox(height: 20),

          // Nb lots
          AppTextField(
            controller: _lotsCtrl,
            hintText: 'Ex : 12',
            label: 'Nombre total de lots',
            isRequired: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            helperText: 'Nombre total d\'appartements ou locaux dans ce bien',
          ),
          const SizedBox(height: 20),

          // Description
          AppTextField(
            controller: _descCtrl,
            hintText: 'Équipements, atouts, informations complémentaires...',
            label: 'Description',
            maxLines: 4,
          ),
        ],
      ),
    );
  }
}
