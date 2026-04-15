import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Color Palette ───────────────────────────────────────────────────────────
class AppColors {
  // Backgrounds
  static const Color bgDark = Color(0xFF0D1B2A);
  static const Color bgMid = Color(0xFF1B263B);
  static const Color bgCard = Color(0xFF162032);

  // Primary
  static const Color primary = Color(0xFF14C1C7);
  static const Color primaryDark = Color(0xFF109DA2);
  static const Color primaryGlow = Color(0x4014C1C7);

  // Slot Status
  static const Color available = Color(0xFF2ECC71);
  static const Color availableGlow = Color(0x402ECC71);
  static const Color reserved = Color(0xFFF1C40F);
  static const Color reservedGlow = Color(0x40F1C40F);
  static const Color occupied = Color(0xFFE74C3C);
  static const Color occupiedGlow = Color(0x40E74C3C);

  // Glass
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassBase = Color(0x1AFFFFFF);
  static const Color glassDark = Color(0x0DFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFFE8F4F8);
  static const Color textSecondary = Color(0xFF8BA5BE);
  static const Color textMuted = Color(0xFF4A6278);

  // Misc
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFC0392B);
  static const Color white = Color(0xFFFFFFFF);
}

// ─── Glass Decoration Helpers ────────────────────────────────────────────────
class AppDecorations {
  static BoxDecoration glassCard({
    double opacity = 0.12,
    double borderRadius = 20,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: Color.fromRGBO(255, 255, 255, opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? AppColors.glassBorder,
        width: 1.0,
      ),
    );
  }

  static BoxDecoration primaryGlassCard({double borderRadius = 20}) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primary.withOpacity(0.25),
          AppColors.primaryDark.withOpacity(0.10),
        ],
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: AppColors.primary.withOpacity(0.4),
        width: 1.0,
      ),
    );
  }

  static LinearGradient backgroundGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.bgDark, AppColors.bgMid],
  );
}

// ─── Text Styles ─────────────────────────────────────────────────────────────
class AppTextStyles {
  static TextStyle get displayLarge => GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get displayMedium => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get headingMedium => GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get headingSmall => GoogleFonts.outfit(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
      );

  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.5,
      );

  static TextStyle get primaryAccent => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      );
}

// ─── Theme Data ───────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primaryDark,
        surface: AppColors.bgCard,
        error: AppColors.error,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glassDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: AppTextStyles.bodyMedium,
        hintStyle: AppTextStyles.bodyMedium,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: AppTextStyles.labelLarge,
          elevation: 0,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      dividerColor: AppColors.glassBorder,
      useMaterial3: true,
    );
  }
}

// ─── App Strings ─────────────────────────────────────────────────────────────
class AppStrings {
  static const String appName = 'E-Park Mo';
  static const String tagline = 'Smart Parking System';
  static const String college = 'St. Louis College Valenzuela';

  static const String guestEmail = 'guest@epark.com';
  static const String guestPass = 'guest123';
  static const String adminEmail = 'admin@epark.com';
  static const String adminPass = 'admin123';

  static const int reservationMinutes = 15;
  static const int barrierAutoCloseSeconds = 10;
  static const double occupiedDistanceCm = 20.0;
  static const int totalSlots = 6;

  // OTP
  static const int otpLength = 6;
  static const int otpExpirySeconds = 120; // 2 minutes to enter OTP

  // Email OTP Config (Universal Web/Mobile - Free)
  // 1. Setup script.google.com with the code provided
  // 2. Paste your "Web App URL" here:
  static const String googleScriptUrl = 'https://script.google.com/macros/s/AKfycbzzMajz2aWsgM4_XMoq8PN47oSAKhjRuSHLCYhS_vToLkqYMH6KHW91cFhbTLUVwPpNnw/exec';

  // [LEGACY] SMTP Config (No longer used, keep for reference)
  // static const String smtpEmail = 'lorenzstrll@gmail.com'; 
  // static const String smtpPassword = 'wgmowpupwzibhimc';
}
