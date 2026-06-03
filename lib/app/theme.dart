import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFF2563EB);
  static const primaryDeep = Color(0xFF0F1D3D);
  static const primarySoft = Color(0xFFEEF4FF);
  static const accent = Color(0xFF14B8A6);
  static const accentDeep = Color(0xFF0F766E);
  static const accentSoft = Color(0xFFECFEFB);
  static const wellness = Color(0xFF0D3B3E);
  static const wellnessSoft = Color(0xFFE7F0DD);
  static const mint = Color(0xFF5EC7A2);
  static const meadow = Color(0xFF6B9B23);
  static const honey = Color(0xFFD28B00);
  static const clay = Color(0xFFC6512D);
  static const lilac = Color(0xFF7E57C2);
  static const admin = Color(0xFF7C3AED);
  static const adminSoft = Color(0xFFF3E8FF);
  static const aiDeep = Color(0xFF312E81);
  static const aiAccent = Color(0xFFC7D2FE);
  static const background = Color(0xFFF7FAF4);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const subtle = Color(0xFF94A3B8);
  static const onDark = Color(0xFFFFFFFF);
  static const onDarkMuted = Color(0xB3FFFFFF);
  static const border = Color(0xFFE2E8F0);
  static const success = Color(0xFF10B981);
  static const successSoft = Color(0xFFECFDF5);
  static const warning = Color(0xFFF59E0B);
  static const warningSoft = Color(0xFFFFFBEB);
  static const danger = Color(0xFFEF4444);
  static const dangerSoft = Color(0xFFFEF2F2);
  static const highBand = Color(0xFFFFF7ED);
  static const lowBand = Color(0xFFFEF2F2);
  static const normalBand = Color(0xFFECFDF5);
}

class AppRadii {
  static const xs = 8.0;
  static const sm = 10.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 22.0;
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

class AppMotion {
  static const fast = Duration(milliseconds: 160);
  static const medium = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 420);

  static const standard = Curves.easeOutCubic;
  static const emphasized = Curves.easeOutQuart;
}

ThemeData buildOptimusTheme() {
  final useGoogleFonts = GoogleFonts.config.allowRuntimeFetching;
  final baseTextTheme = useGoogleFonts
      ? GoogleFonts.interTextTheme()
      : ThemeData.light().textTheme;
  final textTheme = baseTextTheme.copyWith(
    displayLarge: baseTextTheme.displayLarge?.copyWith(
      fontSize: 48,
      height: 0.95,
      fontWeight: FontWeight.w900,
      letterSpacing: 0,
    ),
    displayMedium: baseTextTheme.displayMedium?.copyWith(
      fontSize: 40,
      height: 1,
      fontWeight: FontWeight.w900,
      letterSpacing: 0,
    ),
    headlineLarge: baseTextTheme.headlineLarge?.copyWith(
      fontSize: 30,
      height: 1.05,
      fontWeight: FontWeight.w900,
      letterSpacing: 0,
    ),
    headlineSmall: baseTextTheme.headlineSmall?.copyWith(
      fontSize: 24,
      height: 1.08,
      fontWeight: FontWeight.w900,
      letterSpacing: 0,
    ),
    titleLarge: baseTextTheme.titleLarge?.copyWith(
      fontSize: 22,
      height: 1.18,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    ),
    titleMedium: baseTextTheme.titleMedium?.copyWith(
      fontSize: 16,
      height: 1.25,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    ),
    titleSmall: baseTextTheme.titleSmall?.copyWith(
      fontSize: 14,
      height: 1.25,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    ),
    bodyLarge: baseTextTheme.bodyLarge?.copyWith(
      fontSize: 16,
      height: 1.45,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    ),
    bodyMedium: baseTextTheme.bodyMedium?.copyWith(
      fontSize: 14,
      height: 1.4,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    ),
    bodySmall: baseTextTheme.bodySmall?.copyWith(
      fontSize: 12,
      height: 1.35,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    ),
    labelLarge: baseTextTheme.labelLarge?.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    ),
    labelMedium: baseTextTheme.labelMedium?.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    ),
    labelSmall: baseTextTheme.labelSmall?.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.wellness),
    scaffoldBackgroundColor: AppColors.background,
    textTheme: textTheme.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: _appFont(
        useGoogleFonts: useGoogleFonts,
        color: AppColors.text,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      elevation: 8,
      indicatorColor: AppColors.wellnessSoft,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => _appFont(
          useGoogleFonts: useGoogleFonts,
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
          color: states.contains(WidgetState.selected)
              ? AppColors.text
              : AppColors.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 22,
          color: states.contains(WidgetState.selected)
              ? AppColors.wellness
              : AppColors.muted,
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size.square(44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        textStyle: _appFont(
          useGoogleFonts: useGoogleFonts,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        textStyle: _appFont(
          useGoogleFonts: useGoogleFonts,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        textStyle: _appFont(
          useGoogleFonts: useGoogleFonts,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        minimumSize: WidgetStateProperty.all(const Size(48, 44)),
        textStyle: WidgetStateProperty.all(
          _appFont(useGoogleFonts: useGoogleFonts, fontWeight: FontWeight.w800),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
        ),
        side: WidgetStateProperty.resolveWith(
          (states) => BorderSide(
            color: states.contains(WidgetState.selected)
                ? AppColors.wellness.withValues(alpha: 0.55)
                : AppColors.border,
          ),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.primaryDeep,
      contentTextStyle: _appFont(
        useGoogleFonts: useGoogleFonts,
        color: AppColors.onDark,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      titleTextStyle: _appFont(
        useGoogleFonts: useGoogleFonts,
        color: AppColors.text,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
      contentTextStyle: _appFont(
        useGoogleFonts: useGoogleFonts,
        color: AppColors.muted,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
  );
}

TextStyle _appFont({
  required bool useGoogleFonts,
  Color? color,
  double? fontSize,
  FontWeight? fontWeight,
}) {
  if (useGoogleFonts) {
    return GoogleFonts.inter(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }
  return TextStyle(color: color, fontSize: fontSize, fontWeight: fontWeight);
}

Color roleColor(OptimusRole role) {
  return switch (role) {
    OptimusRole.customer => AppColors.wellness,
    OptimusRole.doctor => AppColors.accentDeep,
    OptimusRole.admin => AppColors.admin,
  };
}

enum OptimusRole { customer, doctor, admin }

// ---------------------------------------------------------------------------
// Dark Mode
// ---------------------------------------------------------------------------

class AppColorsDark {
  static const primary = Color(0xFF60A5FA);
  static const primaryDeep = Color(0xFF1E3A5F);
  static const primarySoft = Color(0xFF1E293B);
  static const accent = Color(0xFF2DD4BF);
  static const accentDeep = Color(0xFF14B8A6);
  static const accentSoft = Color(0xFF0F2928);
  static const wellness = Color(0xFF34D399);
  static const wellnessSoft = Color(0xFF1A2E20);
  static const background = Color(0xFF0F172A);
  static const surface = Color(0xFF1E293B);
  static const text = Color(0xFFF1F5F9);
  static const muted = Color(0xFF94A3B8);
  static const subtle = Color(0xFF64748B);
  static const onDark = Color(0xFFFFFFFF);
  static const border = Color(0xFF334155);
  static const success = Color(0xFF34D399);
  static const successSoft = Color(0xFF0D2818);
  static const warning = Color(0xFFFBBF24);
  static const warningSoft = Color(0xFF2D2006);
  static const danger = Color(0xFFF87171);
  static const dangerSoft = Color(0xFF2D0F0F);
}

ThemeData buildOptimusDarkTheme() {
  final useGoogleFonts = GoogleFonts.config.allowRuntimeFetching;
  final baseTextTheme = useGoogleFonts
      ? GoogleFonts.interTextTheme(ThemeData.dark().textTheme)
      : ThemeData.dark().textTheme;

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColorsDark.wellness,
      brightness: Brightness.dark,
      surface: AppColorsDark.surface,
    ),
    scaffoldBackgroundColor: AppColorsDark.background,
    textTheme: baseTextTheme.apply(
      bodyColor: AppColorsDark.text,
      displayColor: AppColorsDark.text,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColorsDark.background,
      foregroundColor: AppColorsDark.text,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: _appFont(
        useGoogleFonts: useGoogleFonts,
        color: AppColorsDark.text,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColorsDark.surface,
      elevation: 8,
      indicatorColor: AppColorsDark.wellnessSoft,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => _appFont(
          useGoogleFonts: useGoogleFonts,
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
          color: states.contains(WidgetState.selected)
              ? AppColorsDark.text
              : AppColorsDark.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 22,
          color: states.contains(WidgetState.selected)
              ? AppColorsDark.wellness
              : AppColorsDark.muted,
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size.square(44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        textStyle: _appFont(
          useGoogleFonts: useGoogleFonts,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        textStyle: _appFont(
          useGoogleFonts: useGoogleFonts,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        textStyle: _appFont(
          useGoogleFonts: useGoogleFonts,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        minimumSize: WidgetStateProperty.all(const Size(48, 44)),
        textStyle: WidgetStateProperty.all(
          _appFont(useGoogleFonts: useGoogleFonts, fontWeight: FontWeight.w800),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
        ),
        side: WidgetStateProperty.resolveWith(
          (states) => BorderSide(
            color: states.contains(WidgetState.selected)
                ? AppColorsDark.wellness.withValues(alpha: 0.55)
                : AppColorsDark.border,
          ),
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColorsDark.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        side: const BorderSide(color: AppColorsDark.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColorsDark.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: AppColorsDark.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: AppColorsDark.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: AppColorsDark.primary, width: 1.5),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColorsDark.surface,
      contentTextStyle: _appFont(
        useGoogleFonts: useGoogleFonts,
        color: AppColorsDark.text,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColorsDark.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
    ),
  );
}
