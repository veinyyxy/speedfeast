import 'package:flutter/material.dart';

class BuyerAppTheme {
  const BuyerAppTheme({
    required this.brightness,
    required this.primary,
    required this.secondary,
    required this.surface,
    required this.background,
    required this.error,
  });

  static const fallback = BuyerAppTheme(
    brightness: Brightness.light,
    primary: Color(0xFF03A9F4),
    secondary: Color(0xFF0288D1),
    surface: Color(0xFFFFFFFF),
    background: Color(0xFFFFFFFF),
    error: Color(0xFFB3261E),
  );

  final Brightness brightness;
  final Color primary;
  final Color secondary;
  final Color surface;
  final Color background;
  final Color error;

  factory BuyerAppTheme.fromSystemConfigs(Map<String, dynamic> configs) {
    final entry = configs['ui.theme.buyer'];
    final rawValue = entry is Map ? entry['value'] ?? entry : null;
    if (rawValue is! Map) return fallback;
    final value = rawValue.map<String, dynamic>(
      (key, value) => MapEntry(key.toString(), value),
    );
    return BuyerAppTheme(
      brightness: value['brightness']?.toString().toLowerCase() == 'dark'
          ? Brightness.dark
          : Brightness.light,
      primary: _parseColor(value['primary'], fallback.primary),
      secondary: _parseColor(value['secondary'], fallback.secondary),
      surface: _parseColor(value['surface'], fallback.surface),
      background: _parseColor(value['background'], fallback.background),
      error: _parseColor(value['error'], fallback.error),
    );
  }

  ThemeData toThemeData() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      secondary: secondary,
      surface: surface,
      error: error,
    );
    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: primary,
        elevation: 0,
        iconTheme: IconThemeData(color: primary),
        titleTextStyle: TextStyle(
          color: primary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      iconTheme: IconThemeData(color: primary),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: colorScheme.onPrimary,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
      useMaterial3: true,
    );
  }
}

Color _parseColor(dynamic value, Color fallback) {
  final text = value?.toString().trim().toUpperCase() ?? '';
  if (!RegExp(r'^#[0-9A-F]{6}$').hasMatch(text)) return fallback;
  return Color(0xFF000000 | int.parse(text.substring(1), radix: 16));
}
