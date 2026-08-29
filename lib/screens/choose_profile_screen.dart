import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:talent_foot_connect/screens/login_screen.dart';
import 'package:talent_foot_connect/screens/register/academy_register_screen.dart';
import 'package:talent_foot_connect/screens/register/player_register_screen.dart';
import 'package:talent_foot_connect/screens/register/recruiter_register_screen.dart';

class ChooseProfileScreen extends StatelessWidget {
  const ChooseProfileScreen({super.key});

  static const Color _mint = Color(0xFFA1D494);
  static const Color _orangeSoft = Color(0xFFFFB693);
  static const Color _textPrimary = Color(0xFFE2E2E2);
  static const Color _textSecondary = Color(0xFFC2C9BB);
  static const Color _textMuted = Color(0xFF8C9387);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/bg-stadium.jpg', fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xD90A0A0A),
              backgroundBlendMode: BlendMode.overlay,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 0),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Icon(
                            Icons.sports_soccer,
                            size: 72,
                            color: _mint.withValues(alpha: 0.95),
                            shadows: [
                              Shadow(
                                color: _mint.withValues(alpha: 0.3),
                                blurRadius: 13,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'BIENVENUE SUR TALENTFOOT CONNECT',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                              height: 1.43,
                              color: _mint,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Découvre les talents de\ndemain',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                              color: _textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ton réseau professionnel du football.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                              color: _textSecondary.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 40),
                          _ProfileOptionCard(
                            icon: Icons.sports_soccer,
                            iconBg: const Color(0x33A1D494),
                            iconBorder: const Color(0x4DA1D494),
                            iconColor: _mint,
                            title: 'Je suis un\nJoueur',
                            subtitle:
                                'Crée ton profil, partage tes\nstats et trouve ton futur\nclub.',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const PlayerRegisterScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          _ProfileOptionCard(
                            icon: Icons.account_balance_outlined,
                            iconBg: const Color(0x33FE6B00),
                            iconBorder: const Color(0x4DFE6B00),
                            iconColor: _orangeSoft,
                            title: 'Académie',
                            subtitle:
                                'Recherchez les meilleurs talents\navec des données précises.',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const AcademyRegisterScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          _ProfileOptionCard(
                            icon: Icons.handshake_outlined,
                            iconBg: const Color(0x33A1D494),
                            iconBorder: const Color(0x4DA1D494),
                            iconColor: _mint,
                            title: 'Recruteur',
                            subtitle:
                                'Recherchez les meilleurs talents\navec des données précises.',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const RecruiterRegisterScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            },
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Déjà un compte ? ',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.7,
                                      color: _textMuted,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Se connecter',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.7,
                                      color: _textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 32,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: _mint,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 16,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF333535),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 16,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF333535),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ],
                          ),
                        ],
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

class _ProfileOptionCard extends StatelessWidget {
  const _ProfileOptionCard({
    required this.icon,
    required this.iconBg,
    required this.iconBorder,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconBorder;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x1AFFFFFF)),
            color: const Color(0xCC1A1A1A),
            boxShadow: const [
              BoxShadow(color: Color(0x1AA1D494), blurRadius: 35),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: iconBorder),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          height: 1.17,
                          color: ChooseProfileScreen._textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.43,
                          color: ChooseProfileScreen._textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: iconColor.withValues(alpha: 0.7),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
