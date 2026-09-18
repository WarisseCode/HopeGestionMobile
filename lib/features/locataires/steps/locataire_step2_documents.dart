import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../core/design_system.dart';
import '../models/nouveau_locataire_form.dart';

/// Étape 2 : Pièce d'identité et documents (facultative).
class LocataireStep2Documents extends StatefulWidget {
  const LocataireStep2Documents({super.key, required this.form});
  final NouveauLocataireForm form;

  @override
  State<LocataireStep2Documents> createState() =>
      _LocataireStep2DocumentsState();
}

class _LocataireStep2DocumentsState extends State<LocataireStep2Documents> {
  late final TextEditingController _numeroController;
  late final TextEditingController _dateExpController;
  bool _mockDocumentUploaded = false;

  @override
  void initState() {
    super.initState();
    _numeroController = TextEditingController(text: widget.form.numeroId);
    _dateExpController = TextEditingController(
      text: widget.form.dateExpiration,
    );
  }

  @override
  void dispose() {
    _numeroController.dispose();
    _dateExpController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365 * 3)),
      firstDate: DateTime(2000),
      lastDate: DateTime(2040),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.foreground,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final formatted =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      setState(() {
        _dateExpController.text = formatted;
        widget.form.dateExpiration = formatted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.form;

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
          Text('Pièce d\'identité', style: AppTypography.titleScreen()),
          const SizedBox(height: 8),
          Text(
            'Les justificatifs officiels sécurisent la relation contractuelle.',
            style: AppTypography.bodySmall(color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 20),

          const AppInfoBanner(
            text: 'Cette étape est facultative. Vous pouvez passer et ajouter la pièce d\'identité plus tard.',
          ),
          const SizedBox(height: 24),

          // Type de pièce
          AppDropdown<String>(
            label: 'Type de document d\'identité',
            value: f.typeId,
            items: NouveauLocataireForm.typesId
                .map((t) => AppDropdownItem(label: t, value: t))
                .toList(),
            onChanged: (v) => setState(() => f.typeId = v ?? f.typeId),
          ),
          const SizedBox(height: 20),

          // Numéro de pièce
          AppTextField(
            label: 'Numéro de la pièce',
            hintText: 'Ex: 1048294829402',
            prefixIcon: Icon(
              LucideIcons.credit_card,
              size: 18,
              color: AppColors.mutedForeground,
            ),
            controller: _numeroController,
            onChanged: (v) => f.numeroId = v,
          ),
          const SizedBox(height: 20),

          // Date d'expiration
          AppTextField(
            label: 'Date d\'expiration',
            hintText: 'JJ/MM/AAAA',
            prefixIcon: Icon(
              LucideIcons.calendar,
              size: 18,
              color: AppColors.mutedForeground,
            ),
            readOnly: true,
            controller: _dateExpController,
            onTap: _selectDate,
          ),
          const SizedBox(height: 24),

          // Zone Upload
          Text('Scan ou photo de la pièce', style: AppTypography.labelField()),
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              setState(() {
                _mockDocumentUploaded = !_mockDocumentUploaded;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _mockDocumentUploaded
                        ? 'Document numérisé avec succès'
                        : 'Document retiré',
                  ),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            borderRadius: AppRadius.borderMd,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              decoration: BoxDecoration(
                color: _mockDocumentUploaded
                    ? AppColors.positiveSoft
                    : AppColors.inputFill,
                borderRadius: AppRadius.borderMd,
                border: Border.all(
                  color: _mockDocumentUploaded
                      ? AppColors.primary
                      : AppColors.border,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _mockDocumentUploaded
                        ? LucideIcons.circle_check
                        : LucideIcons.upload,
                    size: 36,
                    color: _mockDocumentUploaded
                        ? AppColors.primary
                        : AppColors.mutedForeground,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _mockDocumentUploaded ? 'CNI_recto_verso.pdf (1.8 Mo)' : 'Glissez-déposez le fichier ou cliquez pour parcourir',
                    style: AppTypography.body(
                      fontWeight: _mockDocumentUploaded
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: _mockDocumentUploaded
                          ? AppColors.primaryStrong
                          : AppColors.foreground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _mockDocumentUploaded
                        ? 'Cliquez pour supprimer ou remplacer'
                        : 'Formats acceptés : PDF, JPG, PNG (Max 10 Mo)',
                    style: AppTypography.kpiNote(
                      color: AppColors.mutedForeground,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
