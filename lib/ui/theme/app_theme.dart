import 'package:flutter/material.dart';

import 'book_palette.dart';

/// Material 3 carries structure and behaviour; the Exercise Book world comes
/// in through colour roles, the type scale and shape.
class AppTheme {
  const AppTheme._();

  static const fontFamily = 'Atkinson';
  static const figures = [FontFeature.tabularFigures()];

  static ThemeData light() => _build(BookPalette.light, Brightness.light);

  static ThemeData dark() => _build(BookPalette.dark, Brightness.dark);

  static ThemeData _build(BookPalette book, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: book.covers.first,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    ).copyWith(
      primary: book.ink,
      onPrimary: book.paper,
      surface: book.paper,
      onSurface: book.ink,
      onSurfaceVariant: book.inkSoft,
      outline: book.inkSoft,
      outlineVariant: book.rule,
      error: book.behind,
      tertiary: book.margin,
    );
    final text = _textTheme(book.ink);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: book.paper,
      fontFamily: fontFamily,
      textTheme: text,
      extensions: [book],
      appBarTheme: AppBarTheme(
        backgroundColor: book.paper,
        foregroundColor: book.ink,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: text.titleLarge,
        centerTitle: false,
      ),
      dividerTheme: DividerThemeData(color: book.rule, thickness: 1, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Color.alphaBlend(book.rule.withValues(alpha: 0.35), book.paper),
        indicatorColor: book.rule,
        labelTextStyle: WidgetStatePropertyAll(text.labelMedium),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: book.ink,
        foregroundColor: book.paper,
        extendedTextStyle: text.labelLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: const UnderlineInputBorder(),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: book.inkSoft)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: book.ink, width: 2)),
        labelStyle: TextStyle(color: book.inkSoft),
        floatingLabelStyle: TextStyle(color: book.ink),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: book.rule),
        labelStyle: text.labelLarge,
        backgroundColor: book.paper,
        selectedColor: book.rule,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: book.paper,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: book.ink,
        contentTextStyle: text.bodyMedium?.copyWith(color: book.paper),
        actionTextColor: book.paper,
      ),
      cardTheme: CardThemeData(
        color: book.labelPlate,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: book.rule),
        ),
      ),
    );
  }

  static TextTheme _textTheme(Color ink) {
    TextStyle style(double size, FontWeight weight, {double height = 1.25}) => TextStyle(
          fontFamily: fontFamily,
          fontSize: size,
          fontWeight: weight,
          height: height,
          color: ink,
        );
    return TextTheme(
      displayLarge: style(56, FontWeight.w800, height: 1.05).copyWith(fontFeatures: figures),
      displayMedium: style(44, FontWeight.w800, height: 1.08).copyWith(fontFeatures: figures),
      displaySmall: style(34, FontWeight.w700, height: 1.1).copyWith(fontFeatures: figures),
      headlineLarge: style(30, FontWeight.w700),
      headlineMedium: style(26, FontWeight.w700),
      headlineSmall: style(22, FontWeight.w700),
      titleLarge: style(20, FontWeight.w700),
      titleMedium: style(17, FontWeight.w600),
      titleSmall: style(15, FontWeight.w600),
      bodyLarge: style(17, FontWeight.w400, height: 1.4),
      bodyMedium: style(15, FontWeight.w400, height: 1.4),
      bodySmall: style(13, FontWeight.w400, height: 1.35),
      labelLarge: style(15, FontWeight.w600),
      labelMedium: style(13, FontWeight.w600),
      labelSmall: style(12, FontWeight.w600),
    );
  }
}
