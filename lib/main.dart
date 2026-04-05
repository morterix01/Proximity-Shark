import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'nav_hub.dart';

void main() {
  runApp(const DuckyAndroidApp());
}

class DuckyAndroidApp extends StatelessWidget {
  const DuckyAndroidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: MaterialApp(
        title: 'Proximity Shark',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          primaryColor: Colors.cyanAccent,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.cyanAccent,
            brightness: Brightness.dark,
            surface: const Color(0xFF0F0F1A),
          ),
          scaffoldBackgroundColor: const Color(0xFF0F0F1A),
          textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        ),
        home: const NavHub(),
      ),
    );
  }
}
