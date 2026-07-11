import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/compressor_screen.dart';
import 'screens/m3u8_screen.dart';
import 'screens/reformulator_screen.dart';

void main() {
  runApp(const MediaToolboxApp());
}

class MediaToolboxApp extends StatelessWidget {
  const MediaToolboxApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = ThemeData(brightness: Brightness.dark).textTheme;

    return MaterialApp(
      title: 'MediaToolbox',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0E0F1A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C5CFF),
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.interTextTheme(baseTextTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const HomeNavigation(),
    );
  }
}

class HomeNavigation extends StatefulWidget {
  const HomeNavigation({super.key});

  @override
  State<HomeNavigation> createState() => _HomeNavigationState();
}

class _HomeNavigationState extends State<HomeNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    CompressorScreen(),
    M3u8Screen(),
    ReformulatorScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _screens[_currentIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: const Color(0xFF161829),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.video_settings_outlined),
            selectedIcon: Icon(Icons.video_settings),
            label: 'Compresser',
          ),
          NavigationDestination(
            icon: Icon(Icons.movie_filter_outlined),
            selectedIcon: Icon(Icons.movie_filter),
            label: 'M3U8',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Reformuler',
          ),
        ],
      ),
    );
  }
}
