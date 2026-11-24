import 'package:material_ui/material_ui.dart';

/// Palette taken from the Classicum app mock-up.
class Palette {
  static const ink = Color(0xFF141414);
  static const cream = Color(0xFFF3EEE4);
  static const paper = Color(0xFFFBF8F2);
  static const gold = Color(0xFFC9A24A);
  static const muted = Color(0xFF5E5A52);
  static const line = Color(0xFFDDD5C4);
  static const stone = Color(0xFF8C8576);
  static const darkCard = Color(0xFF1F1E1B);
}

const serif = 'EBGaramond';
const sans = 'Inter';

ThemeData buildTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: Palette.gold,
        brightness: Brightness.light,
      ).copyWith(
        primary: Palette.ink,
        onPrimary: Palette.cream,
        secondary: Palette.gold,
        surface: Palette.cream,
        onSurface: Palette.ink,
        error: const Color(0xFF9B2C2C),
      );
  const inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(color: Palette.ink),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Palette.cream,
    fontFamily: sans,
    dividerColor: Palette.line,
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Palette.paper,
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Palette.gold, width: 3),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: const StadiumBorder(),
        backgroundColor: Palette.ink,
        foregroundColor: Palette.cream,
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
        shape: const StadiumBorder(),
        foregroundColor: Palette.ink,
        side: const BorderSide(color: Palette.ink),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Palette.ink,
      contentTextStyle: TextStyle(color: Palette.cream),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

TextStyle displayStyle(double size, {Color color = Palette.ink}) => TextStyle(
  fontFamily: serif,
  fontSize: size,
  height: 0.95,
  letterSpacing: -0.03 * size,
  color: color,
);

TextStyle eyebrowStyle({Color color = Palette.muted}) => TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w600,
  letterSpacing: 2.4,
  color: color,
);
