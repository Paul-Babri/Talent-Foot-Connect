import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talent_foot_connect/screens/main_shell.dart';
import 'package:talent_foot_connect/services/auth_service.dart';
import 'package:talent_foot_connect/services/social_service.dart';
import 'package:talent_foot_connect/services/talent_service.dart';
import 'package:talent_foot_connect/widgets/register_widgets.dart';

class PlayerRegisterScreen extends StatefulWidget {
  const PlayerRegisterScreen({super.key});

  @override
  State<PlayerRegisterScreen> createState() => _PlayerRegisterScreenState();
}

class _PlayerRegisterScreenState extends State<PlayerRegisterScreen> {
  static const _steps = ['IDENTITÉ', 'PROFIL', 'MÉDIAS'];
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

  final _auth = AuthService();
  final _talents = TalentService();
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _club = TextEditingController();
  final _pastClub1 = TextEditingController();
  final _pastYear1 = TextEditingController();
  final _pastClub2 = TextEditingController();
  final _pastYear2 = TextEditingController();
  final _pastClub3 = TextEditingController();
  final _pastYear3 = TextEditingController();
  final _academy = TextEditingController();
  final _city = TextEditingController();
  final _country = TextEditingController();
  final _goals = TextEditingController();
  final _assists = TextEditingController();
  final _description = TextEditingController();

  int _step = 0;
  String? _position;
  File? _photo;
  File? _video;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _height.dispose();
    _weight.dispose();
    _club.dispose();
    _pastClub1.dispose();
    _pastYear1.dispose();
    _pastClub2.dispose();
    _pastYear2.dispose();
    _pastClub3.dispose();
    _pastYear3.dispose();
    _academy.dispose();
    _city.dispose();
    _country.dispose();
    _goals.dispose();
    _assists.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file != null) setState(() => _photo = File(file.path));
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.pickFiles(type: FileType.video);
    final path = result?.files.single.path;
    if (path != null) setState(() => _video = File(path));
  }

  bool _validateStep() {
    if (_step == 0) {
      if (_name.text.trim().isEmpty ||
          _age.text.trim().isEmpty ||
          _phone.text.trim().isEmpty ||
          _email.text.trim().isEmpty ||
          _password.text.length < 6) {
        showAppSnack(
          context,
          'Nom, âge, téléphone, e-mail et mot de passe (6+ caractères) requis.',
        );
        return false;
      }
      if (int.tryParse(_age.text.trim()) == null) {
        showAppSnack(context, 'Âge invalide.');
        return false;
      }
    }
    return true;
  }

  Future<void> _next() async {
    if (!_validateStep()) return;
    if (_step < 2) {
      setState(() => _step += 1);
      return;
    }
    await _submit();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await _auth.signUpPlayer(
        email: _email.text,
        password: _password.text,
        phone: _phone.text,
        name: _name.text.trim(),
        age: int.parse(_age.text.trim()),
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
        photo: _photo,
        video: _video,
      );
      final userId = _auth.currentUser?.id;
      if (userId != null) {
        await _talents.replaceClubHistory(
          playerId: userId,
          clubs: [
            ClubEntry(name: _pastClub1.text, year: _pastYear1.text),
            ClubEntry(name: _pastClub2.text, year: _pastYear2.text),
            ClubEntry(name: _pastClub3.text, year: _pastYear3.text),
          ],
        );
      }
      if (!mounted) return;
      await showAppSuccess(
        context,
        title: 'Compte créé',
        message: 'Bienvenue sur TalentFoot Connect. Ton profil joueur est prêt.',
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const MainShell()),
        (_) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      await showAppError(context, mapAuthError(e));
    } catch (e) {
      if (!mounted) return;
      await showAppError(context, mapAuthError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _emptyToNull(String value) {
    final t = value.trim();
    return t.isEmpty ? null : t;
  }

  @override
  Widget build(BuildContext context) {
    return RegisterScaffold(
      stepIndex: _step,
      stepLabels: _steps,
      footerHint: 'ÉTAPE ${_step + 1} SUR 3',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_step == 0) _buildIdentity(),
          if (_step == 1) _buildProfile(),
          if (_step == 2) _buildMedia(),
          const SizedBox(height: 28),
          if (_step > 0)
            TextButton(
              onPressed: _loading ? null : () => setState(() => _step -= 1),
              child: const Text(
                'Retour',
                style: TextStyle(color: Color(0xFFA1D494)),
              ),
            ),
          PrimaryCta(
            label: _step == 2 ? 'CRÉER MON COMPTE' : 'CONTINUER',
            onPressed: _next,
            loading: _loading,
            icon: _step == 2 ? Icons.check : Icons.arrow_forward,
          ),
        ],
      ),
    );
  }

  Widget _buildIdentity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepTitle(
          title: 'Identité',
          subtitle: 'Crée ton compte joueur pour rejoindre TalentFoot.',
        ),
        const SizedBox(height: 28),
        LabeledField(
          label: 'NOM COMPLET *',
          child: AppTextField(
            controller: _name,
            hint: 'ex. KYLIAN MBAPPÉ',
            textCapitalization: TextCapitalization.characters,
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
          label: 'TÉLÉPHONE *',
          child: AppTextField(
            controller: _phone,
            hint: '+33 6 12 34 56 78',
            keyboardType: TextInputType.phone,
          ),
        ),
        const SizedBox(height: 12),
        LabeledField(
          label: 'E-MAIL *',
          child: AppTextField(
            controller: _email,
            hint: 'toi@email.com',
            keyboardType: TextInputType.emailAddress,
          ),
        ),
        const SizedBox(height: 12),
        LabeledField(
          label: 'MOT DE PASSE *',
          child: AppTextField(
            controller: _password,
            hint: '6 caractères minimum',
            obscureText: true,
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
      ],
    );
  }

  Widget _buildProfile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepTitle(
          title: 'Profil sportif',
          subtitle:
              'Complète ta fiche scouting (tu pourras modifier plus tard).',
        ),
        const SizedBox(height: 28),
        LabeledField(
          label: 'TAILLE (CM)',
          child: AppTextField(
            controller: _height,
            hint: '180',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
        const SizedBox(height: 12),
        LabeledField(
          label: 'POIDS (KG)',
          child: AppTextField(
            controller: _weight,
            hint: '75',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
        const SizedBox(height: 12),
        LabeledField(
          label: 'CLUB ACTUEL',
          child: AppTextField(controller: _club, hint: 'Optionnel'),
        ),
        const SizedBox(height: 12),
        const StepTitle(
          title: 'Anciens clubs',
          subtitle: 'Optionnel : jusqu\'à trois clubs, avec l\'année.',
        ),
        const SizedBox(height: 12),
        _PastClubFields(club: _pastClub1, year: _pastYear1, index: 1),
        const SizedBox(height: 8),
        _PastClubFields(club: _pastClub2, year: _pastYear2, index: 2),
        const SizedBox(height: 8),
        _PastClubFields(club: _pastClub3, year: _pastYear3, index: 3),
        const SizedBox(height: 12),
        LabeledField(
          label: 'ACADEMY',
          child: AppTextField(controller: _academy, hint: 'Nom de l\'académie'),
        ),
        const SizedBox(height: 12),
        LabeledField(
          label: 'VILLE',
          child: AppTextField(controller: _city, hint: 'Paris'),
        ),
        const SizedBox(height: 12),
        LabeledField(
          label: 'PAYS',
          child: AppTextField(controller: _country, hint: 'France'),
        ),
        const SizedBox(height: 12),
        LabeledField(
          label: 'BUTS',
          child: AppTextField(
            controller: _goals,
            hint: '0',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
        const SizedBox(height: 12),
        LabeledField(
          label: 'ASSISTS',
          child: AppTextField(
            controller: _assists,
            hint: '0',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
        const SizedBox(height: 12),
        LabeledField(
          label: 'DESCRIPTION',
          child: AppTextField(
            controller: _description,
            hint: 'Parle de ton style de jeu…',
            maxLines: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildMedia() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepTitle(
          title: 'Médias',
          subtitle: 'Ajoute une photo et une vidéo de highlights (optionnel).',
        ),
        const SizedBox(height: 28),
        MediaPickCard(
          title: 'Ajouter une photo',
          subtitle: 'JPG, PNG recommandés',
          icon: Icons.add_a_photo_outlined,
          file: _photo,
          onTap: _pickPhoto,
        ),
        const SizedBox(height: 16),
        MediaPickCard(
          title: 'Ajouter une vidéo',
          subtitle: 'MP4, MOV (max recommandé 500 Mo)',
          icon: Icons.cloud_upload_outlined,
          file: _video,
          isImage: false,
          onTap: _pickVideo,
        ),
      ],
    );
  }
}

class _PastClubFields extends StatelessWidget {
  const _PastClubFields({
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
            label: 'CLUB $index',
            child: AppTextField(controller: club, hint: 'Ancien club'),
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
