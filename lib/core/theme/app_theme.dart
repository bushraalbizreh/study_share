import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static const Color ink = Color(0xFF1F5E5A);
  static const Color highlighter = Color(0xFFF2C14E);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = isDark
        ? const ColorScheme(
            brightness: Brightness.dark,
            primary: Color(0xFF7FD1C7),
            onPrimary: Color(0xFF00302C),
            primaryContainer: Color(0xFF1B4A46),
            onPrimaryContainer: Color(0xFFD3EBE7),
            secondary: highlighter,
            onSecondary: Color(0xFF2A2100),
            secondaryContainer: Color(0xFF4A3A0A),
            onSecondaryContainer: Color(0xFFFBEAC0),
            error: Color(0xFFFFB4AB),
            onError: Color(0xFF690005),
            surface: Color(0xFF142120),
            onSurface: Color(0xFFE8F1EF),
            onSurfaceVariant: Color(0xFFA3B8B5),
            outline: Color(0xFF5E7673),
            outlineVariant: Color(0xFF263836),
          )
        : const ColorScheme(
            brightness: Brightness.light,
            primary: ink,
            onPrimary: Colors.white,
            primaryContainer: Color(0xFFD3EBE7),
            onPrimaryContainer: Color(0xFF0B2E2B),
            secondary: highlighter,
            onSecondary: Color(0xFF2A2100),
            secondaryContainer: Color(0xFFFBEAC0),
            onSecondaryContainer: Color(0xFF3A2D00),
            error: Color(0xFFB3261E),
            onError: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF11201F),
            onSurfaceVariant: Color(0xFF566966),
            outline: Color(0xFF8AA09D),
            outlineVariant: Color(0xFFD8E1DF),
          );

    final base = ThemeData(brightness: brightness).textTheme;
    final body = GoogleFonts.readexProTextTheme(base).apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    final display = GoogleFonts.reemKufiTextTheme(base);
    final textTheme = body.copyWith(
      headlineMedium: display.headlineMedium?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: display.headlineSmall?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: display.titleLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
    );

    final radius = BorderRadius.circular(14);
    OutlineInputBorder border(Color c, [double w = 1.2]) =>
        OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: c, width: w));

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF0B1413)
          : const Color(0xFFF1F6F5),
      extensions: <ThemeExtension<dynamic>>[
        isDark ? StatusColors.dark : StatusColors.light,
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: scheme.onSurface,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: border(scheme.outlineVariant),
        enabledBorder: border(scheme.outlineVariant),
        focusedBorder: border(scheme.primary, 2),
        errorBorder: border(scheme.error),
        focusedErrorBorder: border(scheme.error, 2),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: radius),
          side: BorderSide(color: scheme.primary, width: 1.5),
          textStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: scheme.outlineVariant),
        selectedColor: scheme.primary,
        labelStyle: textTheme.labelLarge,
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(color: scheme.onPrimary),
        checkmarkColor: scheme.onPrimary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.secondaryContainer,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelSmall),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
    );
  }
}

/// Colors for the four study-group statuses (never color alone: chips also
/// carry a text label).
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({required this.pairs});

  final Map<String, (Color, Color)> pairs;

  static const light = StatusColors(
    pairs: {
      'Open': (Color(0xFFDDF3EF), Color(0xFF0B5A4D)),
      'Pending': (Color(0xFFFFEFC7), Color(0xFF7A4A00)),
      'Accepted': (Color(0xFFDCF3E2), Color(0xFF176534)),
      'Rejected': (Color(0xFFFBE0E0), Color(0xFF9B1C1C)),
    },
  );

  static const dark = StatusColors(
    pairs: {
      'Open': (Color(0xFF16413C), Color(0xFF9BE3D8)),
      'Pending': (Color(0xFF4A3A0A), Color(0xFFFFD98A)),
      'Accepted': (Color(0xFF173F25), Color(0xFF9BE0AF)),
      'Rejected': (Color(0xFF4F1C1C), Color(0xFFFFB4AB)),
    },
  );

  (Color, Color) of(String status) =>
      pairs[status] ?? pairs['Open'] as (Color, Color);

  @override
  StatusColors copyWith({Map<String, (Color, Color)>? pairs}) =>
      StatusColors(pairs: pairs ?? this.pairs);

  @override
  StatusColors lerp(ThemeExtension<StatusColors>? other, double t) =>
      other is StatusColors ? (t < 0.5 ? this : other) : this;
}
