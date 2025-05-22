import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sangeet/home/home_screen.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Must add this line.
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = WindowOptions(
    size: Size(800, 600),
    minimumSize: const Size(600, 700),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sangeet',
      // themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color.fromARGB(255, 215, 217, 215),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 215, 217, 215),
          foregroundColor: Colors.black,
          elevation: 0, // Flat app bar
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(
          0xFF121212,
        ), // Common dark theme background
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F1F1F), // Darker app bar
          foregroundColor: Colors.white,
          elevation: 0, // Flat app bar
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        // Add other dark theme specific properties here
      ),
      // darkTheme: ThemeData.dark(),
      home: const HomeView(),
    );
  }
}
