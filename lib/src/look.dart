import 'package:flutter/material.dart';

/// Stone paper, deep maroon and a thin gold rule, like a printed darshan pass.
class Look {
  const Look._({
    required this.paper,
    required this.card,
    required this.ink,
    required this.muted,
    required this.line,
    required this.maroon,
    required this.onMaroon,
    required this.gold,
    required this.warn,
  });

  final Color paper, card, ink, muted, line, maroon, onMaroon, gold, warn;

  static const light = Look._(
    paper: Color(0xFFF5EFE4),
    card: Color(0xFFFFFBF4),
    ink: Color(0xFF2A1E17),
    muted: Color(0xFF7A6A5C),
    line: Color(0xFFE2D6C3),
    maroon: Color(0xFF6E1423),
    onMaroon: Color(0xFFFFF4E6),
    gold: Color(0xFFB8860B),
    warn: Color(0xFFB3401E),
  );

  static const dark = Look._(
    paper: Color(0xFF16110E),
    card: Color(0xFF221A15),
    ink: Color(0xFFF3E9DA),
    muted: Color(0xFFB2A190),
    line: Color(0xFF3B2F26),
    maroon: Color(0xFF8E2236),
    onMaroon: Color(0xFFFFF4E6),
    gold: Color(0xFFD9A93A),
    warn: Color(0xFFF08A63),
  );

  static Look of(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? dark : light;

  static const figures = [FontFeature.tabularFigures()];

  TextStyle label() => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.4,
    color: muted,
  );

  ThemeData theme(Brightness b) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: line),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: b,
        primary: maroon,
        onPrimary: onMaroon,
        secondary: gold,
        onSecondary: ink,
        error: warn,
        onError: Colors.white,
        surface: card,
        onSurface: ink,
      ),
      scaffoldBackgroundColor: paper,
      dividerColor: line,
      appBarTheme: AppBarTheme(
        backgroundColor: maroon,
        foregroundColor: onMaroon,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: onMaroon,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: maroon, width: 1.5),
        ),
        filled: true,
        fillColor: card,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: maroon,
          foregroundColor: onMaroon,
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: BorderSide(color: line),
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: maroon),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: paper,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: TextStyle(color: paper),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// The thin gold line under headings.
class GoldRule extends StatelessWidget {
  const GoldRule({super.key});
  @override
  Widget build(BuildContext context) =>
      Container(height: 1.2, color: Look.of(context).gold);
}
