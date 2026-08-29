import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talent_foot_connect/screens/main_shell.dart';
import 'package:talent_foot_connect/services/auth_service.dart';
import 'package:talent_foot_connect/widgets/register_widgets.dart';

class AcademyRegisterScreen extends StatefulWidget {
  const AcademyRegisterScreen({super.key});

  @override
  State<AcademyRegisterScreen> createState() => _AcademyRegisterScreenState();
}

class _AcademyRegisterScreenState extends State<AcademyRegisterScreen> {
  static const _steps = ['IDENTITÉ', 'PRÉSENT.', 'MÉDIAS'];

  final _auth = AuthService();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _country = TextEditingController();
  final _description = TextEditingController();

  int _step = 0;
  File? _logo;
  File? _photo;
  File? _video;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _city.dispose();
    _country.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickImage({required bool logo}) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    setState(() {
      if (logo) {
        _logo = File(file.path);
      } else {
        _photo = File(file.path);
      }
    });
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.pickFiles(type: FileType.video);
    final path = result?.files.single.path;
    if (path != null) setState(() => _video = File(path));
  }

  bool _validateStep() {
    if (_step == 0) {
      if (_name.text.trim().isEmpty ||
          _email.text.trim().isEmpty ||
          _password.text.length < 6) {
        showAppSnack(
          context,
          'Nom, e-mail et mot de passe (6+ caractères) requis.',
        );
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
      await _auth.signUpAcademy(
        email: _email.text,
        password: _password.text,
        name: _name.text.trim(),
        phone: _emptyToNull(_phone.text),
        city: _emptyToNull(_city.text),
        country: _emptyToNull(_country.text),
        description: _emptyToNull(_description.text),
        logo: _logo,
        photo: _photo,
        video: _video,
      );
      if (!mounted) return;
      await showAppSuccess(
        context,
        title: 'Compte créé',
        message: 'Bienvenue sur TalentFoot Connect. Ton profil académie est prêt.',
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
          if (_step == 1) _buildPresentation(),
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
          title: 'Identité académie',
          subtitle: 'Crée le compte de ta structure.',
        ),
        const SizedBox(height: 28),
        LabeledField(
          label: 'NOM *',
          child: AppTextField(
            controller: _name,
            hint: 'Académie Olympique',
            textCapitalization: TextCapitalization.words,
          ),
        ),
        const SizedBox(height: 12),
        LabeledField(
          label: 'E-MAIL *',
          child: AppTextField(
            controller: _email,
            hint: 'contact@academie.com',
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
          label: 'TÉLÉPHONE',
          child: AppTextField(
            controller: _phone,
            hint: '+33 1 23 45 67 89',
            keyboardType: TextInputType.phone,
          ),
        ),
      ],
    );
  }

  Widget _buildPresentation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepTitle(
          title: 'Présentation',
          subtitle: 'Localisation et description de l\'académie.',
        ),
        const SizedBox(height: 28),
        LabeledField(
          label: 'VILLE',
          child: AppTextField(controller: _city, hint: 'Lyon'),
        ),
        const SizedBox(height: 12),
        LabeledField(
          label: 'PAYS',
          child: AppTextField(controller: _country, hint: 'France'),
        ),
        const SizedBox(height: 12),
        LabeledField(
          label: 'DESCRIPTION',
          child: AppTextField(
            controller: _description,
            hint: 'Présente ta structure…',
            maxLines: 5,
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
          subtitle: 'Logo, photo et vidéo de présentation (optionnel).',
        ),
        const SizedBox(height: 28),
        MediaPickCard(
          title: 'Ajouter un logo',
          subtitle: 'PNG transparent recommandé',
          icon: Icons.shield_outlined,
          file: _logo,
          onTap: () => _pickImage(logo: true),
        ),
        const SizedBox(height: 16),
        MediaPickCard(
          title: 'Ajouter une photo',
          subtitle: 'JPG, PNG',
          icon: Icons.add_a_photo_outlined,
          file: _photo,
          onTap: () => _pickImage(logo: false),
        ),
        const SizedBox(height: 16),
        MediaPickCard(
          title: 'Ajouter une vidéo',
          subtitle: 'MP4, MOV',
          icon: Icons.cloud_upload_outlined,
          file: _video,
          isImage: false,
          onTap: _pickVideo,
        ),
      ],
    );
  }
}
