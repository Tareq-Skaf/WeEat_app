import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/theme_provider.dart';

void main() {
  group('ThemeProvider Tests', () {
    late ThemeProvider provider;

    setUp(() {
      provider = ThemeProvider();
    });

    test('initial state is light mode', () {
      expect(provider.isDarkMode, false);
    });

    test('toggleDarkMode switches mode', () {
      expect(provider.isDarkMode, false);
      provider.toggleDarkMode();
      expect(provider.isDarkMode, true);
      provider.toggleDarkMode();
      expect(provider.isDarkMode, false);
    });

    test('setDarkMode sets specific value', () {
      provider.setDarkMode(true);
      expect(provider.isDarkMode, true);
      provider.setDarkMode(false);
      expect(provider.isDarkMode, false);
    });

    test('light theme has correct background', () {
      expect(provider.background, const Color(0xFFFEF9EE));
    });

    test('dark theme has correct background', () {
      provider.setDarkMode(true);
      expect(provider.background, const Color(0xFF121212));
    });

    test('light theme has correct surface color', () {
      expect(provider.surface, Colors.white);
    });

    test('dark theme has correct surface color', () {
      provider.setDarkMode(true);
      expect(provider.surface, const Color(0xFF1E1E1E));
    });

    test('light theme text is black', () {
      expect(provider.textPrimary, Colors.black);
    });

    test('dark theme text is white', () {
      provider.setDarkMode(true);
      expect(provider.textPrimary, Colors.white);
    });

    test('notifyListeners is called on toggle', () {
      int callCount = 0;
      provider.addListener(() => callCount++);
      provider.toggleDarkMode();
      expect(callCount, 1);
    });
  });
}
