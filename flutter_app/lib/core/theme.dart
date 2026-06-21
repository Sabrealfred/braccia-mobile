import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// "Onyx & Gold" design tokens — the single source of truth for the app theme.
/// Mirrors the high-fidelity prototype (Braccia Capital CRM — Redesign).
class AppColors {
  // Onyx (dark surfaces)
  static const onyx900 = Color(0xFF0C0D11); // deepest backdrop
  static const onyx800 = Color(0xFF15161B); // dark gradient base
  static const onyx700 = Color(0xFF16171C); // dark headers / nav
  static const onyx600 = Color(0xFF23252E); // card gradient top
  static const onyx650 = Color(0xFF191A20); // card gradient bottom
  static const ink = Color(0xFF17181B); // primary text on light

  // Ivory (light surfaces)
  static const ivory = Color(0xFFF6F5F1); // app light bg / text on dark
  static const surface = Color(0xFFFFFFFF); // white cards

  // Gold
  static const gold300 = Color(0xFFE3C477);
  static const gold500 = Color(0xFFC79A3E);
  static const goldInk = Color(0xFF1A1206); // text on gold
  static const goldText = Color(0xFF9A7320); // gold text on light
  static const goldTextSoft = Color(0xFF946F17);
  static const goldOnDark = Color(0xFFCFAE6A);

  // Status colors
  static const green = Color(0xFF2E7D65);
  static const greenOnDark = Color(0xFF7FD0AD);
  static const red = Color(0xFFC0473D);
  static const redOnDark = Color(0xFFD2564B);
  static const blue = Color(0xFF3D6A90);
  static const blueOnDark = Color(0xFF4D7EA8);
  static const purple = Color(0xFF7A5F7D);
  static const purpleOnDark = Color(0xFF8B6F8E);

  // Hairlines / borders
  static const hairline = Color(0xFFECE9E1);
  static const hairlineSoft = Color(0xFFF3F1EA);

  // Muted text
  static const muted = Color(0xFF8B8C93);
  static const mutedOnDark = Color(0xFF9A9BA1);
  static const mutedLight = Color(0xFFA09F97);

  // Gradients
  static const goldGradient = LinearGradient(
    begin: Alignment(-0.7, -1),
    end: Alignment(0.7, 1),
    colors: [gold300, gold500],
  );

  static const goldGradientVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [gold300, gold500],
  );

  static const darkCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [onyx600, onyx650],
  );

  static const heroHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [onyx600, onyx800],
  );

  /// Radial app backdrop seen on the AI screen + login.
  static const aiBackdrop = RadialGradient(
    center: Alignment(0, -1),
    radius: 1.1,
    colors: [onyx600, onyx800, Color(0xFF101116)],
    stops: [0.0, 0.6, 1.0],
  );
}

class AppRadii {
  static const card = 18.0;
  static const cardLarge = 24.0;
  static const pill = 20.0;
  static const tile = 17.0;
  static const input = 13.0;
  static const inner = 11.0;
}

class AppSpacing {
  static const screenH = 20.0;
  static const screenTop = 54.0;
  static const bottomClearance = 120.0;
}

/// Text styles — DM Serif Display (display) + DM Sans (UI).
class AppText {
  static TextStyle serif({
    double size = 24,
    Color color = AppColors.ink,
    FontStyle style = FontStyle.normal,
    double height = 1.1,
  }) =>
      GoogleFonts.dmSerifDisplay(
        fontSize: size,
        color: color,
        fontStyle: style,
        height: height,
      );

  static TextStyle sans({
    double size = 13.5,
    Color color = AppColors.ink,
    FontWeight weight = FontWeight.w400,
    double? letterSpacing,
    double height = 1.4,
  }) =>
      GoogleFonts.dmSans(
        fontSize: size,
        color: color,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        height: height,
      );

  /// Uppercase eyebrow label.
  static TextStyle eyebrow(Color color) => GoogleFonts.dmSans(
        fontSize: 11,
        color: color,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.4,
        height: 1.2,
      );
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.ivory,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.gold500,
        secondary: AppColors.gold300,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
        error: AppColors.red,
      ),
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      splashFactory: InkRipple.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
