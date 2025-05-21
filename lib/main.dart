import 'package:context_menus/context_menus.dart';
import 'package:flutter/material.dart';

import 'package:bot_toast/bot_toast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';

import 'package:sangeet/frame/home.dart';
import 'package:sangeet/initialization.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await hotKeyManager.unregisterAll();
  JustAudioMediaKit.ensureInitialized();
  JustAudioMediaKit.ensureInitialized(
    linux: false, // default: true  - dependency: media_kit_libs_linux
    windows: true,
  );
  JustAudioMediaKit.title = 'Sangeet';
  JustAudioMediaKit.prefetchPlaylist = true;
  await initialiseAppFunctions();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ContextMenuOverlay(
      child: MaterialApp(
        title: 'Sangeet',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.lightBlueAccent,
        ),
        darkTheme: ThemeData.dark().copyWith(
            textTheme: GoogleFonts.ubuntuTextTheme(ThemeData.dark().textTheme),
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.lightBlueAccent,
              brightness: Brightness.dark,
            ),
            cardTheme: const CardThemeData(
              color: Colors.transparent,
              elevation: .5,
            )),
        themeMode: ThemeMode.dark,
        home: const HomeFrame(),
        builder: BotToastInit(),
        navigatorObservers: [
          BotToastNavigatorObserver(),
        ],
      ),
    );
  }
}
