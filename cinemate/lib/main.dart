import 'package:cinemate/widgets/navi_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:cinemate/services/api.dart';

void main() {
  Gemini.init(apiKey: api);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: NaviBar(),
    );
  }
}