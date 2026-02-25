import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  bool _showLatin = true;
  bool _showTranslation = true;
  String _languageCode = 'id'; // Default to Indonesian
  String _arabicFont = 'Amiri'; // Default Arabic Font

  bool get isDarkMode => _isDarkMode;
  bool get showLatin => _showLatin;
  bool get showTranslation => _showTranslation;
  String get languageCode => _languageCode;
  String get arabicFont => _arabicFont;

  final List<String> availableArabicFonts = [
    'Amiri',
    'Scheherazade',
    'Lateef',
    'Cairo',
    'Tajawal',
    'Changa',
  ];

  ThemeProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    _showLatin = prefs.getBool('show_latin') ?? true;
    _showTranslation = prefs.getBool('show_translation') ?? true;
    _languageCode = prefs.getString('language_code') ?? 'id';
    _arabicFont = prefs.getString('arabic_font') ?? 'Amiri';
    notifyListeners();
  }

  Future<void> toggleTheme(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', value);
    notifyListeners();
  }

  Future<void> toggleLatin(bool value) async {
    _showLatin = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_latin', value);
    notifyListeners();
  }

  Future<void> toggleTranslation(bool value) async {
    _showTranslation = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_translation', value);
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    if (_languageCode == code) return;
    _languageCode = code;
    notifyListeners(); // Notify listeners immediately for UI update
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', code);
  }

  Future<void> setArabicFont(String fontName) async {
    if (_arabicFont == fontName) return;
    _arabicFont = fontName;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('arabic_font', fontName);
  }
}
