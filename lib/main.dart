import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:subtitle_editor/constants.dart';
import 'package:subtitle_editor/splash_screen.dart';

void main() async {
  await Hive.initFlutter();
  await Hive.openBox<String>('subtitles');
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
    return ScreenUtilInit(
      designSize: const Size(393, 852),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return MaterialApp(
          home: const SplashScreen(),
          theme: ThemeData(
            primarySwatch: customSwatch,
            // scaffoldBackgroundColor: kSecondaryColor,
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              elevation: 0,
            ),
            dialogTheme: DialogTheme(
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(8.r), // Set the desired radius here
              ),
            ),

            fontFamily: 'English',
            useMaterial3: false,
          ),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
