import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../core/design_system.dart';
import '../models/nouveau_immeuble_form.dart';
import '../widgets/photos_picker.dart';

/// Étape 1 : Identité de l'immeuble (nom, type, étages, capacité prévue,
/// photos).
class ImmeubleStep1Identite extends StatefulWidget {
  const ImmeubleStep1Identite({super.key, required this.form});
  final NouveauImmeubleForm form;

  @override
  State<ImmeubleStep1Identite> createState() => _ImmeubleStep1IdentiteState();
}

class _ImmeubleStep1IdentiteState extends State<ImmeubleStep1Identite> {
  late final TextEditingController _nomCtrl;
  late final TextEditingController _etagesCtrl;
  late final TextEditingController _lotsCtrl;
  late final TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    final f = widget.form;
    _nomCtrl = TextEditingController(text: f.nom);
    _etagesCtrl = TextEditingController(text: f.nombreEtages.toString());
    _lotsCtrl = TextEditingController(text: f.totalLots?.toString() ?? '');
    _descCtrl = TextEditingController(text: f.description);

    _nomCtrl.addListener(() => f.nom = _nomCtrl.text);
    _etagesCtrl.addListener(
      () => f.nombreEtages = int.tryParse(_etagesCtrl.text) ?? 0,
    );
    _lotsCtrl.addListener(
      () => f.totalLots = int.tryParse(_lotsCtrl.text),
    );
    _descCtrl.addListener(() => f.description = _descCtrl.text);
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
          Text('Identité de l\'immeuble', style: AppTypography.titleScreen()),
          const SizedBox(height: 24),

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

          AppDropdown<String>(
            label: 'Type de bien',
            value: widget.form.type,
            items: NouveauImmeubleForm.typesImmeuble
                .map((t) => AppDropdownItem(label: t, value: t))
                .toList(),
            onChanged: (v) => setState(() => widget.form.type = v ?? 'Immeuble'),
          ),
          const SizedBox(height: 20),

          AppTextField(
            controller: _etagesCtrl,
            hintText: '0',
            label: 'Nombre d\'étages',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            helperText: 'Indiquez 0 si le bien est de plain-pied',
          ),
          const SizedBox(height: 20),

          AppTextField(
            controller: _lotsCtrl,
            hintText: 'Ex : 12',
            label: 'Capacité prévue (optionnel)',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            helperText:
                'Nombre de lots que vous prévoyez — n\'en crée aucun '
                'automatiquement, purement informatif tant qu\'ils ne sont '
                'pas ajoutés un par un',
          ),
          const SizedBox(height: 20),

          AppTextField(
            controller: _descCtrl,
            hintText: 'Équipements, atouts, informations complémentaires...',
            label: 'Description',
            maxLines: 4,
          ),
          const SizedBox(height: 24),

          PhotosPicker(
            photoUrls: widget.form.photoUrls,
            onChanged: (urls) => setState(() => widget.form.photoUrls = urls),
          ),
        ],
      ),
    );
  }
}
