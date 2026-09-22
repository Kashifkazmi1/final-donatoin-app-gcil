import 'package:flutter/material.dart';

import 'screens/connect_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DonationApp());
}

class DonationApp extends StatelessWidget {
  const DonationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GCIL Donation App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00457D), // GCIL branding color
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F8F4),
        textTheme: const TextTheme(
          displayLarge:
              TextStyle(fontWeight: FontWeight.w800, letterSpacing: -1.5),
          headlineMedium: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      home: const ConnectScreen(),
    );
  }
}
