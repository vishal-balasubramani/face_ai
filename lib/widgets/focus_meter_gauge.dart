import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

class FocusMeterGauge extends StatelessWidget {
  final int focusScore;
  final bool animate;

  const FocusMeterGauge({
    Key? key,
    required this.focusScore,
    this.animate = true,
  }) : super(key: key);

  Color _getColor() {
    if (focusScore >= 80) return AppConstants.accentGreen;
    if (focusScore >= 50) return AppConstants.accentOrange;
    return AppConstants.accentRed;
  }

  @override
  Widget build(BuildContext context) {
    return CircularPercentIndicator(
      radius: 80.0,
      lineWidth: 12.0,
      percent: focusScore / 100,
      center: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$focusScore%',
            style: GoogleFonts.orbitron(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            'FOCUS',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
      progressColor: _getColor(),
      backgroundColor: Colors.white.withOpacity(0.1),
      circularStrokeCap: CircularStrokeCap.round,
      animation: animate,
      animationDuration: 1000,
      animateFromLastPercent: true,
    );
  }
}
