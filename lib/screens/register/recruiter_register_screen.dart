import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talent_foot_connect/screens/main_shell.dart';
import 'package:talent_foot_connect/services/auth_service.dart';
import 'package:talent_foot_connect/widgets/register_widgets.dart';

class RecruiterRegisterScreen extends StatefulWidget {
  const RecruiterRegisterScreen({super.key});

  @override
  State<RecruiterRegisterScreen> createState() =>
      _RecruiterRegisterScreenState();
}

class _RecruiterRegisterScreenState extends State<RecruiterRegisterScreen> {
  static const _steps = ['IDENTITÉ', 'PROFIL'];
  static const _types = [
    'Scout',
    'Agent',
    'Directeur sportif',
    'Recruteur club',
    'Autre',
  ];

  final _auth = AuthService();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _country = TextEditingController();
  final _description = TextEditingController();
  final _besoins = TextEditingController();

  int _step = 0;
  String? _type;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _country.dispose();
    _description.dispose();
    _besoins.dispose();
    super.dispose();
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
    if (_step < 1) {
      setState(() => _step += 1);
      return;
    }
    await _submit();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await _auth.signUpRecruiter(
        email: _email.text,
        password: _password.text,
        name: _name.text.trim(),
        phone: _emptyToNull(_phone.text),
        type: _type,
        country: _emptyToNull(_country.text),
        description: _emptyToNull(_description.text),
        besoins: _emptyToNull(_besoins.text),
      );
      if (!mounted) return;
      await showAppSuccess(
        context,
        title: 'Compte créé',
        message:
            'Bienvenue sur TalentFoot Connect. Ton profil recruteur est prêt.',
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
      footerHint: 'ÉTAPE ${_step + 1} SUR 2',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_step == 0) _buildIdentity(),
          if (_step == 1) _buildProfile(),
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
            label: _step == 1 ? 'CRÉER MON COMPTE' : 'CONTINUER',
            onPressed: _next,
            loading: _loading,
            icon: _step == 1 ? Icons.check : Icons.arrow_forward,
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
          title: 'Identité recruteur',
          subtitle: 'Crée ton compte pour scouter les talents.',
        ),
        const SizedBox(height: 28),
        LabeledField(
          label: 'NOM *',
          child: AppTextField(
            controller: _name,
            hint: 'Marc Moreau',
            textCapitalization: TextCapitalization.words,
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
          label: 'TÉLÉPHONE',
          child: AppTextField(
            controller: _phone,
            hint: '+33 6 12 34 56 78',
            keyboardType: TextInputType.phone,
          ),
        ),
        const SizedBox(height: 12),
        LabeledField(
          label: 'TYPE',
          child: AppDropdown(
            value: _type,
            hint: 'Sélectionner un type',
            items: _types,
            onChanged: (v) => setState(() => _type = v),
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
          title: 'Profil recruteur',
          subtitle: 'Indique ton pays et ce que tu recherches.',
        ),
        const SizedBox(height: 28),
        LabeledField(
          label: 'PAYS',
          child: AppTextField(controller: _country, hint: 'France'),
        ),
        const SizedBox(height: 12),
        LabeledField(
          label: 'DESCRIPTION',
          child: AppTextField(
            controller: _description,
            hint: 'Ton parcours, ton club…',
            maxLines: 4,
          ),
        ),
        const SizedBox(height: 12),
        LabeledField(
          label: 'BESOINS',
          child: AppTextField(
            controller: _besoins,
            hint: 'Ex. ailier U19, pied gauche…',
            maxLines: 4,
          ),
        ),
      ],
    );
  }
}
