import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talent_foot_connect/screens/main_shell.dart';
import 'package:talent_foot_connect/services/auth_service.dart';
import 'package:talent_foot_connect/theme/app_colors.dart';
import 'package:talent_foot_connect/widgets/register_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      showAppSnack(context, 'E-mail et mot de passe requis.');
      return;
    }

    setState(() => _loading = true);
    try {
      await _auth.signIn(email: _email.text.trim(), password: _password.text);
      if (!mounted) return;
      await showAppSuccess(
        context,
        title: 'Connexion réussie',
        message: 'Content de te revoir sur TalentFoot Connect.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          ClipRect(
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
                      'CONNEXION',
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
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const StepTitle(
                    title: 'Bon retour',
                    subtitle: 'Connecte-toi pour accéder à TalentFoot Connect.',
                  ),
                  const SizedBox(height: 32),
                  LabeledField(
                    label: 'E-MAIL',
                    child: AppTextField(
                      controller: _email,
                      hint: 'toi@email.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LabeledField(
                    label: 'MOT DE PASSE',
                    child: AppTextField(
                      controller: _password,
                      hint: 'Ton mot de passe',
                      obscureText: true,
                    ),
                  ),
                  const SizedBox(height: 32),
                  PrimaryCta(
                    label: 'SE CONNECTER',
                    onPressed: _submit,
                    loading: _loading,
                    icon: Icons.login,
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
