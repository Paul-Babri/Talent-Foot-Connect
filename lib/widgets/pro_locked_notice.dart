import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:talent_foot_connect/theme/app_colors.dart';

/// Carte affichée lorsqu’une section est réservée à l’abonnement PRO.
class ProLockedNotice extends StatelessWidget {
  const ProLockedNotice({
    super.key,
    required this.onUpgrade,
    this.message = 'Réservé à l\'abonnement PRO (2 000 FCFA / mois).',
    this.buttonLabel = 'VOIR L\'OFFRE PRO',
  });

  final VoidCallback onUpgrade;
  final String message;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x33FE6B00)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onUpgrade,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.black,
            ),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}
