import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'colors.dart';

ThemeData buildMealtionTheme() {
  return ThemeData(
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.bg,
    textTheme: GoogleFonts.poppinsTextTheme(),
    useMaterial3: true,
  );
}

TextStyle logoStyle(BuildContext context) {
  // Fredoka is used in the splash; keep it here for reuse if needed.
  return GoogleFonts.fredoka(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: AppColors.textMain,
    letterSpacing: 1.2,
  );
}

/// Mealtion logo widget - uses SVG asset
class MealtionLogo extends StatelessWidget {
  const MealtionLogo({super.key, this.height = 48, this.variant = 'peach'});

  final double height;
  final String variant; // 'peach' or 'white'

  @override
  Widget build(BuildContext context) {
    final filename = variant == 'white' 
        ? 'mealtion-logo-white.svg' 
        : 'mealtion-logo-peach.svg';
    return SvgPicture.asset(
      'assets/images/$filename',
      height: height,
      fit: BoxFit.contain,
    );
  }
}
