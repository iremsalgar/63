import 'package:flutter/material.dart';

const Color primaryLightColor = Color(0xFF071952);
const Color secondaryLightColor = Color(0xFF088395);
const Color surfaceLightColor = Color(0xFF37B7C3);
const Color backgroundLightColor = Color(0xFFEBF4F6);

const Color primaryDarkColor = Color(0xFF071952);
const Color secondaryDarkColor = Color(0xFF088395);
const Color surfaceDarkColor = Color(0xFF37B7C3);
const Color backgroundDarkColor = Color(0xFFEBF4F6);

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    primary: primaryLightColor,
    secondary: secondaryLightColor,
    surface: surfaceLightColor,
    background: backgroundLightColor,
  ),
  scaffoldBackgroundColor: backgroundLightColor,
  appBarTheme: AppBarTheme(
    color: primaryLightColor,
  ),
);

ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    primary: primaryDarkColor,
    secondary: secondaryDarkColor,
    surface: surfaceDarkColor,
    background: backgroundDarkColor,
  ),
  scaffoldBackgroundColor: primaryDarkColor,
  appBarTheme: AppBarTheme(
    color: primaryDarkColor,
  ),
);
