import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:talent_foot_connect/models/app_user_profile.dart';
import 'package:talent_foot_connect/services/entitlement_service.dart';
import 'package:talent_foot_connect/services/profile_service.dart';
import 'package:talent_foot_connect/services/social_service.dart';
import 'package:talent_foot_connect/services/talent_service.dart';
import 'package:talent_foot_connect/screens/offers_screen.dart';
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
  final _talents = TalentService();
  final _entitlements = EntitlementService();
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _phone = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _club = TextEditingController();
  final _pastClub1 = TextEditingController();
  final _pastYear1 = TextEditingController();
  final _pastClub2 = TextEditingController();
  final _pastYear2 = TextEditingController();
  final _pastClub3 = TextEditingController();
  final _pastYear3 = TextEditingController();
  final _acceleration = TextEditingController();
  final _finishing = TextEditingController();
  final _dribble = TextEditingController();
  final _vision = TextEditingController();
  final _academy = TextEditingController();
  final _city = TextEditingController();
  final _country = TextEditingController();
  final _goals = TextEditingController();
  final _assists = TextEditingController();
  final _description = TextEditingController();

  String? _position;
  bool _loading = true;
  bool _saving = false;
  bool _pro = false;

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
      final history = await _talents.clubHistory(widget.profile.id);
      if (history.isNotEmpty) {
        _pastClub1.text = history[0].name;
        _pastYear1.text = history[0].year;
      }
      if (history.length > 1) {
        _pastClub2.text = history[1].name;
        _pastYear2.text = history[1].year;
      }
      if (history.length > 2) {
        _pastClub3.text = history[2].name;
        _pastYear3.text = history[2].year;
      }
      final quota = await _entitlements.fetchQuota();
      _pro = quota.proActive;
      if (_pro) {
        final performance = await _talents.performanceFor(widget.profile.id);
        if (performance != null) {
          _acceleration.text = '${performance.acceleration}';
          _finishing.text = '${performance.finishing}';
          _dribble.text = '${performance.dribble}';
          _vision.text = '${performance.vision}';
        }
      }
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
    _pastClub1.dispose();
    _pastYear1.dispose();
    _pastClub2.dispose();
    _pastYear2.dispose();
    _pastClub3.dispose();
    _pastYear3.dispose();
    _acceleration.dispose();
    _finishing.dispose();
    _dribble.dispose();
    _vision.dispose();
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
      await _talents.replaceClubHistory(
        playerId: widget.profile.id,
        clubs: [
          ClubEntry(name: _pastClub1.text, year: _pastYear1.text),
          ClubEntry(name: _pastClub2.text, year: _pastYear2.text),
          ClubEntry(name: _pastClub3.text, year: _pastYear3.text),
        ],
      );
      if (_pro) {
        final scores = [
          int.tryParse(_acceleration.text.trim()),
          int.tryParse(_finishing.text.trim()),
          int.tryParse(_dribble.text.trim()),
          int.tryParse(_vision.text.trim()),
        ];
        if (scores.every((score) => score != null && score >= 1 && score <= 10)) {
          await _talents.savePerformance(
            playerId: widget.profile.id,
            performance: PlayerPerformance(
              acceleration: scores[0]!,
              finishing: scores[1]!,
              dribble: scores[2]!,
              vision: scores[3]!,
            ),
          );
        }
      }
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
                          label: 'CLUB ACTUEL',
                          child: AppTextField(
                            controller: _club,
                            hint: 'Optionnel',
                          ),
                        ),
                        const SizedBox(height: 12),
                        _PastRow(club: _pastClub1, year: _pastYear1, index: 1),
                        const SizedBox(height: 8),
                        _PastRow(club: _pastClub2, year: _pastYear2, index: 2),
                        const SizedBox(height: 8),
                        _PastRow(club: _pastClub3, year: _pastYear3, index: 3),
                        const SizedBox(height: 16),
                        if (_pro) ...[
                          const StepTitle(
                            title: 'Analyse PRO',
                            subtitle: 'Notes de 1 à 10.',
                          ),
                          const SizedBox(height: 12),
                          _ScoreField(label: 'ACCÉLÉRATION', controller: _acceleration),
                          _ScoreField(label: 'FINITION', controller: _finishing),
                          _ScoreField(label: 'DRIBBLE', controller: _dribble),
                          _ScoreField(label: 'VISION', controller: _vision),
                        ] else
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Analyse de performance',
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                            subtitle: const Text(
                              'Réservée à l\'abonnement PRO.',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                            trailing: const Icon(Icons.lock_outline, color: AppColors.orange),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const OffersScreen(),
                                ),
                              );
                            },
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

class _PastRow extends StatelessWidget {
  const _PastRow({
    required this.club,
    required this.year,
    required this.index,
  });

  final TextEditingController club;
  final TextEditingController year;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: LabeledField(
            label: 'ANCIEN CLUB $index',
            child: AppTextField(controller: club, hint: 'Club'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LabeledField(
            label: 'ANNÉE',
            child: AppTextField(
              controller: year,
              hint: '2022',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
        ),
      ],
    );
  }
}

class _ScoreField extends StatelessWidget {
  const _ScoreField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: LabeledField(
        label: label,
        child: AppTextField(
          controller: controller,
          hint: '1-10',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      ),
    );
  }
}
