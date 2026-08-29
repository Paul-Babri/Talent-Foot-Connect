import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:talent_foot_connect/models/app_user_profile.dart';
import 'package:talent_foot_connect/services/profile_service.dart';
import 'package:talent_foot_connect/theme/app_colors.dart';
import 'package:talent_foot_connect/widgets/register_widgets.dart';

class PlayerAccountScreen extends StatefulWidget {
  const PlayerAccountScreen({super.key, required this.profile});

  final AppUserProfile profile;

  @override
  State<PlayerAccountScreen> createState() => _PlayerAccountScreenState();
}

class _PlayerAccountScreenState extends State<PlayerAccountScreen> {
  static const _positions = [
    'Gardien',
    'Défenseur central',
    'Latéral droit',
    'Latéral gauche',
    'Milieu défensif',
    'Milieu offensif',
    'Ailier droit',
    'Ailier gauche',
    'Attaquant',
  ];

  final _profileService = ProfileService();
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _phone = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _club = TextEditingController();
  final _academy = TextEditingController();
  final _city = TextEditingController();
  final _country = TextEditingController();
  final _goals = TextEditingController();
  final _assists = TextEditingController();
  final _description = TextEditingController();

  String? _position;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final row = await _profileService.fetchPlayerRow(widget.profile.id);
      _name.text = (row?['name'] as String?) ?? widget.profile.displayName;
      _age.text = '${row?['age'] ?? ''}';
      _phone.text = widget.profile.phone ?? '';
      _height.text = row?['height_cm']?.toString() ?? '';
      _weight.text = row?['weight_kg']?.toString() ?? '';
      _club.text = (row?['club'] as String?) ?? '';
      _academy.text = (row?['academy'] as String?) ?? '';
      _city.text = (row?['city'] as String?) ?? '';
      _country.text = (row?['country'] as String?) ?? '';
      _goals.text = '${row?['goals'] ?? 0}';
      _assists.text = '${row?['assists'] ?? 0}';
      _description.text = (row?['description'] as String?) ?? '';
      final pos = row?['position'] as String?;
      _position = _positions.contains(pos) ? pos : null;
    } catch (e) {
      if (mounted) await showAppError(context, mapAuthError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _phone.dispose();
    _height.dispose();
    _weight.dispose();
    _club.dispose();
    _academy.dispose();
    _city.dispose();
    _country.dispose();
    _goals.dispose();
    _assists.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final age = int.tryParse(_age.text.trim());
    if (name.isEmpty || age == null) {
      await showAppError(context, 'Nom et âge sont requis.');
      return;
    }

    setState(() => _saving = true);
    try {
      await _profileService.updatePlayerAccount(
        userId: widget.profile.id,
        name: name,
        age: age,
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        position: _position,
        heightCm: int.tryParse(_height.text.trim()),
        weightKg: int.tryParse(_weight.text.trim()),
        club: _emptyToNull(_club.text),
        academy: _emptyToNull(_academy.text),
        city: _emptyToNull(_city.text),
        country: _emptyToNull(_country.text),
        goals: int.tryParse(_goals.text.trim()),
        assists: int.tryParse(_assists.text.trim()),
        description: _emptyToNull(_description.text),
      );
      if (!mounted) return;
      await showAppSuccess(
        context,
        title: 'Compte mis à jour',
        message: 'Tes informations joueur ont été enregistrées.',
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      await showAppError(context, mapAuthError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _emptyToNull(String value) {
    final t = value.trim();
    return t.isEmpty ? null : t;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.mint),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const StepTitle(
                          title: 'Mon compte',
                          subtitle:
                              'Modifie tes informations personnelles et sportives.',
                        ),
                        const SizedBox(height: 24),
                        if (widget.profile.email != null) ...[
                          LabeledField(
                            label: 'E-MAIL',
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0x1AFFFFFF),
                                ),
                              ),
                              child: Text(
                                widget.profile.email!,
                                style: GoogleFonts.montserrat(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        LabeledField(
                          label: 'NOM *',
                          child: AppTextField(
                            controller: _name,
                            hint: 'Ton nom',
                            textCapitalization: TextCapitalization.words,
                          ),
                        ),
                        const SizedBox(height: 12),
                        LabeledField(
                          label: 'ÂGE *',
                          child: AppTextField(
                            controller: _age,
                            hint: '19',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(2),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        LabeledField(
                          label: 'TÉLÉPHONE',
                          child: AppTextField(
                            controller: _phone,
                            hint: '+33 6 12 34 56 78',
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(height: 12),
                        LabeledField(
                          label: 'POSTE',
                          child: AppDropdown(
                            value: _position,
                            hint: 'Sélectionner un poste',
                            items: _positions,
                            onChanged: (v) => setState(() => _position = v),
                          ),
                        ),
                        const SizedBox(height: 12),
                        LabeledField(
                          label: 'TAILLE (CM)',
                          child: AppTextField(
                            controller: _height,
                            hint: '180',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        LabeledField(
                          label: 'POIDS (KG)',
                          child: AppTextField(
                            controller: _weight,
                            hint: '75',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        LabeledField(
                          label: 'CLUB',
                          child: AppTextField(
                            controller: _club,
                            hint: 'Club actuel',
                          ),
                        ),
                        const SizedBox(height: 12),
                        LabeledField(
                          label: 'ACADEMY',
                          child: AppTextField(
                            controller: _academy,
                            hint: 'Académie',
                          ),
                        ),
                        const SizedBox(height: 12),
                        LabeledField(
                          label: 'VILLE',
                          child: AppTextField(controller: _city, hint: 'Paris'),
                        ),
                        const SizedBox(height: 12),
                        LabeledField(
                          label: 'PAYS',
                          child: AppTextField(
                            controller: _country,
                            hint: 'France',
                          ),
                        ),
                        const SizedBox(height: 12),
                        LabeledField(
                          label: 'BUTS',
                          child: AppTextField(
                            controller: _goals,
                            hint: '0',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        LabeledField(
                          label: 'ASSISTS',
                          child: AppTextField(
                            controller: _assists,
                            hint: '0',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        LabeledField(
                          label: 'DESCRIPTION',
                          child: AppTextField(
                            controller: _description,
                            hint: 'Parle de ton jeu…',
                            maxLines: 4,
                          ),
                        ),
                        const SizedBox(height: 28),
                        PrimaryCta(
                          label: 'ENREGISTRER',
                          onPressed: _save,
                          loading: _saving,
                          icon: Icons.check,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.5, sigmaY: 10.5),
        child: Container(
          height: 64 + MediaQuery.paddingOf(context).top,
          padding: EdgeInsets.only(
            top: MediaQuery.paddingOf(context).top,
            left: 16,
            right: 16,
          ),
          decoration: const BoxDecoration(
            color: Color(0xCC0C0F0F),
            border: Border(bottom: BorderSide(color: Color(0x1AFFFFFF))),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'MON COMPTE',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
