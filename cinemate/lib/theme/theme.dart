import 'package:flutter/material.dart';

const Color primaryLightColor = Colors.white70;
const Color secondaryLightColor = Colors.white70;
const Color surfaceLightColor = Colors.amber;
const Color backgroundLightColor = Colors.white70;

const Color primaryDarkColor = Colors.black54;
const Color secondaryDarkColor = Colors.amber;
const Color surfaceDarkColor = Colors.white38;
const Color backgroundDarkColor = Colors.white70;

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: primaryLightColor,
    secondary: secondaryLightColor,
    surface: surfaceLightColor,
  ),
  scaffoldBackgroundColor: backgroundLightColor,
  appBarTheme: const AppBarTheme(
    color: primaryLightColor,
  ),
);

ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: primaryDarkColor,
    secondary: secondaryDarkColor,
    surface: surfaceDarkColor,
  ),
  scaffoldBackgroundColor: primaryDarkColor,
  appBarTheme: const AppBarTheme(
    color: primaryDarkColor,
  ),
);
