import 'package:flutter/material.dart';
import 'app/theme.dart';
import 'features/home/mealtion_home_page.dart';

void main() {
  runApp(const MealtionApp());
}

class MealtionApp extends StatelessWidget {
  const MealtionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mealtion',
      debugShowCheckedModeBanner: false,
      theme: buildMealtionTheme(),
      home: const MealtionHomePage(),
    );
  }
}
