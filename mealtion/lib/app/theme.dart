import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
