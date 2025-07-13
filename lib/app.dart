import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'screens/game_screen.dart';

class NexusCoreApp extends StatelessWidget {
  const NexusCoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexus Core',
      theme: AppTheme.darkTheme,
      home: const GameScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}