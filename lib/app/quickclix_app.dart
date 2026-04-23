import 'package:flutter/material.dart';
import 'package:quickclix/screens/home/quickclix_home_page.dart';
import 'package:quickclix/theme/app_colors.dart';

class QuickclixApp extends StatelessWidget {
  const QuickclixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quickclix',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.ink,
          surface: AppColors.paper,
        ),
        scaffoldBackgroundColor: AppColors.paper,
        fontFamily: 'sans-serif',
        useMaterial3: true,
      ),
      home: const QuickclixHomePage(),
    );
  }
}
