import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }

  // Light Theme
  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFEF9EE),
    primaryColor: const Color(0xFF6F8574),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6F8574),
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 20),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: DividerThemeData(color: Colors.grey[200], thickness: 1),
  );

  // Dark Theme
  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212),
    primaryColor: const Color(0xFF6F8574),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6F8574),
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: DividerThemeData(color: Colors.grey[800], thickness: 1),
    dialogTheme: DialogThemeData(backgroundColor: const Color(0xFF1E1E1E)),
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Color(0xFF1E1E1E)),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF2D2D2D),
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );

  // Helper colors
  Color get background => _isDarkMode ? const Color(0xFF121212) : const Color(0xFFFEF9EE);
  Color get surface => _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
  Color get textPrimary => _isDarkMode ? Colors.white : Colors.black;
  Color get textSecondary => _isDarkMode ? Colors.white70 : Colors.grey[600]!;
  Color get divider => _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!;
  Color get cardBg => _isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
}