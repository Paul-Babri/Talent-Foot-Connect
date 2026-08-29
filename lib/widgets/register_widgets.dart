import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talent_foot_connect/theme/app_colors.dart';

class RegisterScaffold extends StatelessWidget {
  const RegisterScaffold({
    super.key,
    required this.stepIndex,
    required this.stepLabels,
    required this.child,
    required this.footerHint,
  });

  final int stepIndex;
  final List<String> stepLabels;
  final Widget child;
  final String footerHint;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const RegisterHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RegisterProgress(currentIndex: stepIndex, labels: stepLabels),
                  const SizedBox(height: 28),
                  child,
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      footerHint,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                        color: AppColors.textMuted,
                      ),
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

class RegisterHeader extends StatelessWidget {
  const RegisterHeader({super.key});

  @override
  Widget build(BuildContext context) {
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
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'TALENT FOOT',
                style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.2,
                  color: AppColors.mint,
                ),
              ),
              const Spacer(),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegisterProgress extends StatelessWidget {
  const RegisterProgress({
    super.key,
    required this.currentIndex,
    required this.labels,
  });

  final int currentIndex;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20, left: 8, right: 8),
                  child: Stack(
                    children: [
                      Container(height: 2, color: const Color(0x33A1D494)),
                      FractionallySizedBox(
                        widthFactor: currentIndex >= i ? 1 : 0,
                        child: Container(height: 2, color: AppColors.mint),
                      ),
                    ],
                  ),
                ),
              ),
            _ProgressStep(
              number: '${i + 1}',
              label: labels[i],
              active: currentIndex >= i,
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({
    required this.number,
    required this.label,
    required this.active,
  });

  final String number;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: active ? AppColors.mint : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: active ? null : Border.all(color: const Color(0x1AFFFFFF)),
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: active ? AppColors.mintDark : AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: active ? AppColors.mint : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class StepTitle extends StatelessWidget {
  const StepTitle({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.14,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.5,
            color: AppColors.textSecondary.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class LabeledField extends StatelessWidget {
  const LabeledField({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final int maxLines;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      style: GoogleFonts.montserrat(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.montserrat(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textMuted.withValues(alpha: 0.7),
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.mint, width: 1.5),
        ),
      ),
    );
  }
}

class AppDropdown extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final String? value;
  final String hint;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(
            hint,
            style: GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted.withValues(alpha: 0.7),
            ),
          ),
          dropdownColor: AppColors.surface,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.mint),
          style: GoogleFonts.montserrat(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class PrimaryCta extends StatelessWidget {
  const PrimaryCta({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon = Icons.arrow_forward,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: AppColors.orangeDark,
          disabledBackgroundColor: AppColors.orange.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.orangeDark,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(icon, size: 18),
                ],
              ),
      ),
    );
  }
}

class MediaPickCard extends StatelessWidget {
  const MediaPickCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.file,
    this.isImage = true,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final File? file;
  final bool isImage;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x33A1D494), width: 1.5),
        ),
        child: Column(
          children: [
            if (file != null && isImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  file!,
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0x33A1D494),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.mint, size: 24),
              ),
            const SizedBox(height: 12),
            Text(
              file != null ? 'Fichier sélectionné' : title,
              style: GoogleFonts.montserrat(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              file != null ? file!.path.split(RegExp(r'[\\/]')).last : subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showAppSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppColors.surfaceAlt,
      duration: const Duration(seconds: 5),
    ),
  );
}

Future<void> showAppError(BuildContext context, String message) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        'Erreur',
        style: GoogleFonts.montserrat(
          color: AppColors.orange,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        message,
        style: GoogleFonts.inter(color: AppColors.textPrimary, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(
            'OK',
            style: GoogleFonts.montserrat(
              color: AppColors.mint,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

Future<void> showAppSuccess(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        title,
        style: GoogleFonts.montserrat(
          color: AppColors.mint,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        message,
        style: GoogleFonts.inter(color: AppColors.textPrimary, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(
            'CONTINUER',
            style: GoogleFonts.montserrat(
              color: AppColors.orange,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

String mapAuthError(Object error) {
  final raw = error is AuthException ? error.message : error.toString();
  final lower = raw.toLowerCase();

  if (lower.contains('rate limit') || lower.contains('over_email_send')) {
    return 'Trop de tentatives d\'inscription. Attends une minute, '
        'utilise une autre adresse e-mail, ou désactive la confirmation '
        'e-mail dans le dashboard Supabase (Authentication → Providers → Email).';
  }
  if (lower.contains('email') && lower.contains('invalid')) {
    return 'Adresse e-mail refusée par Supabase. Utilise une vraie adresse '
        '(évite test@gmail.com / example.com).';
  }
  if (lower.contains('signups are disabled') ||
      lower.contains('signup is disabled') ||
      lower.contains('email signups')) {
    return 'Les inscriptions e-mail sont désactivées. '
        'Dans Supabase → Authentication → Providers → Email : '
        'garde Email ON, Confirm email OFF, et Allow new users to sign up ON.';
  }
  if (lower.contains('already registered') || lower.contains('already been')) {
    return 'Cet e-mail est déjà utilisé. Connecte-toi ou utilise une autre adresse.';
  }
  if (lower.contains('network') || lower.contains('socket')) {
    return 'Pas de connexion réseau. Vérifie ta connexion internet.';
  }
  return raw;
}
