import 'package:flutter/material.dart';

/// OncoNutri+ Design System Theme
/// Based on ui_design_system.txt specifications
class AppTheme {
  // Color Palette - Modern neutral design
  static const Color colorPrimary = Color(0xFF2D2D2D); // Dark charcoal
  static const Color colorPrimary400 = Color(0xFF4A4A4A); // Medium gray
  static const Color colorBackground = Color(0xFFF8F9FA); // Light gray background
  static const Color colorSurface = Color(0xFFFFFFFF);
  static const Color colorCream = Color(0xFFF0F2F5); // Soft gray
  static const Color colorSoftPeach = Color(0xFFE8F5E9); // Soft mint green
  static const Color colorAccent = Color(0xFF4CAF50); // Success green accent
  static const Color colorAccentSecondary = Color(0xFFFFC107); // Warm yellow
  static const Color colorText = Color(0xFF1A1A1A);
  static const Color colorSubtext = Color(0xFF666666);
  static const Color colorBorder = Color(0xFFE0E0E0);
  static const Color colorShadow = Color(0x0A000000); // rgba(0,0,0,0.04)
  static const Color colorSuccess = Color(0xFF4CAF50);
  static const Color colorWarning = Color(0xFFFFC107);
  static const Color colorDanger = Color(0xFFFF5252);
  static const Color colorGlass = Color(0xF5FFFFFF); // rgba(255,255,255,0.96)

  // Dark Mode Colors
  static const Color colorDarkBackground = Color(0xFF121212);
  static const Color colorDarkSurface = Color(0xFF1E1E1E);
  static const Color colorDarkText = Color(0xFFE8E8E8);
  static const Color colorDarkSubtext = Color(0xFFB0B0B0);
  static const Color colorDarkBorder = Color(0xFF2E2E2E);
  static const Color colorDarkPrimary = Color(0xFFF2A694);
  static const Color colorDarkPrimary400 = Color(0xFFF7C7B7);

  // Border Radii - Modern rounded design
  static const double radiusOuter = 24.0;
  static const double radiusCard = 16.0;
  static const double radiusButton = 12.0;
  static const double radiusSmall = 8.0;

  // Spacing
  static const double spaceBase = 8.0;
  static const double spaceSm = 12.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;
  static const double spaceXl = 32.0;
  static const double cardPadding = 20.0;
  static const double horizontalPadding = 24.0;
  static const double gridGap = 12.0;

  // Typography - Modern clean font
  static const String fontFamily = 'SF Pro Display'; // iOS
  static const String fontFamilyAndroid = 'Roboto'; // Android fallback

  static TextStyle get h1 => const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.2,
        color: colorText,
      );

  static TextStyle get h2 => const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: colorText,
      );
  
  static TextStyle get h3 => const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: colorText,
      );

  static TextStyle get body => const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0.1,
        color: colorText,
      );

  static TextStyle get bodyMedium => const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: colorText,
      );
  
  static TextStyle get bodyLarge => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colorText,
      );

  static TextStyle get caption => const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: colorSubtext,
      );
  
  static TextStyle get captionMedium => const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: colorSubtext,
      );
  
  // Shadows - Subtle modern shadows
  static List<BoxShadow> get defaultShadow => [
        BoxShadow(
          color: colorShadow,
          blurRadius: 10,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0x08000000),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get selectedShadow => [
        BoxShadow(
          color: colorSuccess.withOpacity(0.15),
          blurRadius: 16,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: colorShadow.withOpacity(0.1),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ];

  // Animation Durations
  static const Duration fadeInDuration = Duration(milliseconds: 200);
  static const Duration cardPressDuration = Duration(milliseconds: 120);
  static const Duration pageTransitionDuration = Duration(milliseconds: 280);
  static const Duration modalSlideDuration = Duration(milliseconds: 260);

  // Animation Curves
  static const Curve defaultCurve = Curves.easeInOut;

  // Background Gradient
  static LinearGradient get backgroundGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [colorCream, colorSoftPeach],
      );

  // Theme Data
  static ThemeData get lightTheme => ThemeData(
        primaryColor: colorPrimary,
        scaffoldBackgroundColor: colorBackground,
        fontFamily: fontFamily,
        colorScheme: const ColorScheme.light(
          primary: colorPrimary,
          secondary: colorPrimary400,
          surface: colorSurface,
          error: colorDanger,
        ),
        textTheme: TextTheme(
          displayLarge: h1,
          displayMedium: h2,
          bodyLarge: body,
          bodyMedium: bodyMedium,
          bodySmall: caption,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorPrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusButton),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: colorText,
            side: const BorderSide(color: colorBorder, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusButton),
            ),
          ),
        ),
        cardTheme: CardTheme(
          color: colorSurface,
          elevation: 0,
          shadowColor: colorShadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusCard),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: colorSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusButton),
            borderSide: const BorderSide(color: colorBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusButton),
            borderSide: const BorderSide(color: colorBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusButton),
            borderSide: const BorderSide(color: colorPrimary, width: 2),
          ),
        ),
      );

  // Dark Theme
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        primaryColor: colorDarkPrimary,
        scaffoldBackgroundColor: colorDarkBackground,
        fontFamily: fontFamily,
        colorScheme: const ColorScheme.dark(
          primary: colorDarkPrimary,
          secondary: colorDarkPrimary400,
          surface: colorDarkSurface,
          background: colorDarkBackground,
          error: colorDanger,
        ),
        textTheme: TextTheme(
          displayLarge: h1.copyWith(color: colorDarkText),
          displayMedium: h2.copyWith(color: colorDarkText),
          bodyLarge: body.copyWith(color: colorDarkText),
          bodyMedium: bodyMedium.copyWith(color: colorDarkText),
          bodySmall: caption.copyWith(color: colorDarkSubtext),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: colorDarkSurface,
          foregroundColor: colorDarkText,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorDarkPrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusButton),
            ),
            textStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: fontFamily,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: colorDarkText,
            side: const BorderSide(color: colorDarkBorder, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusButton),
            ),
          ),
        ),
        cardTheme: CardTheme(
          color: colorDarkSurface,
          elevation: 0,
          shadowColor: Colors.black45,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusCard),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: colorDarkSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusButton),
            borderSide: const BorderSide(color: colorDarkBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusButton),
            borderSide: const BorderSide(color: colorDarkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusButton),
            borderSide: const BorderSide(color: colorDarkPrimary, width: 2),
          ),
        ),
      );

  // Dark mode background gradient
  static LinearGradient get darkBackgroundGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1A1A1A), Color(0xFF121212)],
      );

  // Context-aware color helpers so widgets that use AppTheme can adapt to
  // the active ThemeMode without needing to query colors manually everywhere.
  static Color primaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? colorDarkPrimary : colorPrimary;
  }

  static Color subtextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? colorDarkSubtext : colorSubtext;
  }

  static Color primary400Color(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? colorDarkPrimary400 : colorPrimary400;
  }

  static Color surfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? colorDarkSurface : colorSurface;
  }

  static Color borderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? colorDarkBorder : colorBorder;
  }

  static LinearGradient backgroundGradientFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkBackgroundGradient : backgroundGradient;
  }
}

