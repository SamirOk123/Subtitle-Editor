import 'package:flutter/material.dart';
import 'package:subtitle_editor/constants.dart';
import 'package:subtitle_editor/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Color customColor = kPrimaryColor;

    MaterialColor customSwatch = MaterialColor(
      customColor.value,
      <int, Color>{
        50: customColor.withOpacity(0.1),
        100: customColor.withOpacity(0.2),
        200: customColor.withOpacity(0.3),
        300: customColor.withOpacity(0.4),
        400: customColor.withOpacity(0.5),
        500: customColor.withOpacity(0.6),
        600: customColor.withOpacity(0.7),
        700: customColor.withOpacity(0.8),
        800: customColor.withOpacity(0.9),
        900: customColor,
      },
    );
    return MaterialApp(
      home: const HomeScreen(),
      theme: ThemeData(
        primarySwatch: customSwatch,
        scaffoldBackgroundColor: kSecondaryColor,
        appBarTheme: const AppBarTheme(backgroundColor: kPrimaryColor),
        useMaterial3: false,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
