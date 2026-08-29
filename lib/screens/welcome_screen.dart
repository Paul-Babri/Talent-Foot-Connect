import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:talent_foot_connect/screens/choose_profile_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const Color _mint = Color(0xFF9AFF9A);
  static const Color _orange = Color(0xFFFF6A00);
  static const Color _buttonText = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/bg-stadium.jpg', fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xCC000000),
                  Color(0x99000000),
                  Color(0xB3000000),
                  Color(0xE6000000),
                ],
                stops: [0.0, 0.35, 0.65, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.topRight,
                    child: _CornerLabel(text: 'V2.0', corner: _Corner.topRight),
                  ),
                  const SizedBox(height: 24),
                  Icon(
                    Icons.sports_soccer,
                    size: 40,
                    color: _mint.withValues(alpha: 0.95),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'TALENTFOOT',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2.4,
                      color: _mint,
                    ),
                  ),
                  Text(
                    'CONNECT',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 44.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2.4,
                      height: 1.15,
                      color: _mint,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Un réseau, \n des talents, de nouvelles opportunités.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 56,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _orange,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ChooseProfileScreen(),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: _buttonText,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'COMMENCER',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'SCOUTING  •  TALENTS  •  OPPORTUNITÉS',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.8,
                      color: const Color.fromARGB(130, 194, 201, 187),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Align(
                    alignment: Alignment.bottomLeft,
                    child: _CornerLabel(
                      text: 'TALENTFOOT CONNECT',
                      corner: _Corner.bottomLeft,
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

enum _Corner { topRight, bottomLeft }

class _CornerLabel extends StatelessWidget {
  const _CornerLabel({required this.text, required this.corner});

  final String text;
  final _Corner corner;

  @override
  Widget build(BuildContext context) {
    const lineColor = Color.fromARGB(25, 194, 201, 187);
    const textColor = Color.fromARGB(130, 194, 201, 187);

    return CustomPaint(
      painter: _CornerBorderPainter(corner: corner, color: lineColor),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Text(
          text,
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            letterSpacing: 1.5,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

class _CornerBorderPainter extends CustomPainter {
  const _CornerBorderPainter({required this.corner, required this.color});

  final _Corner corner;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    const arm = 60.0;

    if (corner == _Corner.topRight) {
      canvas.drawLine(
        Offset(size.width - arm, 0),
        Offset(size.width, 0),
        paint,
      );
      canvas.drawLine(Offset(size.width, 0), Offset(size.width, arm), paint);
    } else {
      canvas.drawLine(
        Offset(0, size.height - arm),
        Offset(0, size.height),
        paint,
      );
      canvas.drawLine(Offset(0, size.height), Offset(arm, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CornerBorderPainter oldDelegate) {
    return oldDelegate.corner != corner || oldDelegate.color != color;
  }
}
