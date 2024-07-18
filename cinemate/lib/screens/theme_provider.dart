import 'package:flutter/material.dart';
import '../theme/theme.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeData _selectedTheme;
  bool _isDarkMode;

  ThemeProvider({bool isDarkMode = false})
      : _isDarkMode = isDarkMode,
        _selectedTheme = isDarkMode ? darkMode : lightMode;

  ThemeData get theme => _selectedTheme;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme(bool isDark) {
    _isDarkMode = isDark;
    _selectedTheme = isDark ? darkMode : lightMode;
    notifyListeners();
  }
}
