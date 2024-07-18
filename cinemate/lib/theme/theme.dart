import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
      surface: Colors.white12,
      primary: Colors.white10,
      secondary: Colors.white),
);

ThemeData darkMode = ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
        surface: Colors.black,
        primary: Colors.black87,
        secondary: Colors.black54));
