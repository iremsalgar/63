import 'package:flutter/material.dart';

const Color primaryLightColor = Colors.white70;
const Color secondaryLightColor = Colors.green;
const Color surfaceLightColor = Colors.white70;
const Color backgroundLightColor = Colors.white70;

const Color primaryDarkColor = Colors.white10;
const Color secondaryDarkColor = Colors.lightBlue;
const Color surfaceDarkColor = Colors.white30;
const Color backgroundDarkColor = Colors.white30;

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
