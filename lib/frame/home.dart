import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_discord_rpc/flutter_discord_rpc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:sangeet/core/core.dart';
import 'package:sangeet/functions/explore/controllers/explore_controller.dart';
import 'package:sangeet/functions/explore/widgets/explore_list.dart';
import 'package:sangeet/functions/explore/widgets/trend_card.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';

import 'package:sangeet/core/constants.dart';
import 'package:sangeet/functions/player/controllers/player_controller.dart';
import 'package:sangeet/functions/player/widgets/base_audio_player.dart';
import 'package:sangeet/functions/shortcuts/actions.dart';

class HomeFrame extends ConsumerStatefulWidget {
  const HomeFrame({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomeFrameState();
}

class _HomeFrameState extends ConsumerState<HomeFrame>
    with TrayListener, WindowListener {
  bool get isTesting => Platform.environment.containsKey('FLUTTER_TEST');

  @override
  void initState() {
    super.initState();
    trayManager.addListener(this);
    windowManager.addListener(this);
    if (!isTesting) {
      FlutterDiscordRPC.instance.connect().catchError((e) {
        debugPrint('Failed To Connect Discord');
      });
    }
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    if (!isTesting) {
      FlutterDiscordRPC.instance.clearActivity();
      FlutterDiscordRPC.instance
          .disconnect()
          .catchError((e) => debugPrint('Failed To Disconnect Discord'));
      FlutterDiscordRPC.instance.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerControllerProvider.notifier).getPlayer;
    final currentWidth = MediaQuery.of(context).size.width;
    return Actions(
      actions: <Type, Action<Intent>>{
        BaseIntent: SongActions(
          audioPlayer: player,
        )
      },
      child: GlobalShortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.keyW, alt: true): BaseIntent(
            keyAction: KeyAction.playPauseMusic,
          ),
          SingleActivator(LogicalKeyboardKey.keyD, alt: true): BaseIntent(
            keyAction: KeyAction.nextTrack,
          ),
          SingleActivator(LogicalKeyboardKey.keyA, alt: true): BaseIntent(
            keyAction: KeyAction.prevTrack,
          ),
        },
        child: Scaffold(
          body: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                    border: Border(
                        right: BorderSide(
                  width: 2,
                  color: Colors.teal.withOpacity(.09),
                ))),
                width: 430,
                height: double.infinity,
                child: Column(
                  children: [
                    Flexible(
                      flex: 1,
                      child: SizedBox(
                        width: double.infinity,
                        height: double.maxFinite,
                        child: ref.watch(getExploreDataProvider).when(
                              data: (data) {
                                final trendings = data.trending;

                                return Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.all(10.0),
                                          child: Text(
                                            'Trending.',
                                            style: TextStyle(
                                              fontSize: 30,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => ref
                                              .read(playerControllerProvider
                                                  .notifier)
                                              .reset(),
                                          icon: const Icon(Icons
                                              .disabled_by_default_rounded),
                                        )
                                      ],
                                    ),
                                    SizedBox(
                                      width: 430,
                                      height:
                                          MediaQuery.of(context).size.height -
                                              165,
                                      child: ListView.builder(
                                        itemCount: trendings.length,
                                        scrollDirection: Axis.vertical,
                                        itemBuilder: (context, index) {
                                          final item = trendings[index];
                                          return TrendCard(
                                            key: Key("trend_${item.id}"),
                                            onTap: () => ref
                                                .watch(playerControllerProvider
                                                    .notifier)
                                                .runRadio(
                                                  radioId: item.id,
                                                  type: MediaType.fromString(
                                                      item.type),
                                                  redirect: () {},
                                                ),
                                            onLike: () {},
                                            onPlay: () {},
                                            image: item.image,
                                            accentColor: item.accentColor,
                                            title: item.title,
                                            subtitle: item.subtitle,
                                            explicitContent:
                                                item.explicitContent,
                                            badgeIcon: item.type == "song"
                                                ? Icons.music_note
                                                : item.type == "playlist"
                                                    ? Icons
                                                        .playlist_play_rounded
                                                    : Icons.album_rounded,
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              },
                              error: (error, stackTrace) {
                                return ErrorText(
                                  error: error.toString(),
                                );
                              },
                              loading: () => const CircularProgressIndicator(),
                            ),
                      ),
                    ),
                    const BaseAudioPlayer()
                  ],
                ),
              ),
              if (currentWidth > 450)
                SizedBox(
                  width: currentWidth - 430,
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.maxFinite,
                        height: MediaQuery.of(context).size.height,
                        child: const ExploreList(),
                      )
                    ],
                  ),
                ),
            ],
          ),
        ),
        // child: Scaffold(
        //   backgroundColor: Colors.transparent,
        //   body: BlurImageContainer(
        //     child: Row(
        //       children: [
        //         NavigationRail(
        //           selectedIndex: index,
        //           onDestinationSelected: (idx) => config.onIndex(idx),
        //           destinations: const [
        //             NavigationRailDestination(
        //               icon: Icon(Icons.home),
        //               label: Text("Home"),
        //             ),
        //             NavigationRailDestination(
        //               icon: Icon(Icons.search),
        //               label: Text("Search"),
        //             ),
        //             NavigationRailDestination(
        //               icon: Icon(Icons.music_note_rounded),
        //               label: Text("Current Playing"),
        //             ),
        //             NavigationRailDestination(
        //               icon: Icon(Icons.settings),
        //               label: Text("Settings"),
        //             ),
        //           ],
        //           leading: Padding(
        //             padding: const EdgeInsets.symmetric(vertical: 8.0),
        //             child: Image.asset(
        //               'assets/app_icon.ico',
        //               width: 35,
        //             ),
        //           ),
        //           labelType: NavigationRailLabelType.none,
        //           backgroundColor: Colors.black,
        //           indicatorColor: Colors.grey.shade900,
        //           unselectedIconTheme: const IconThemeData(color: Colors.grey),
        //           selectedIconTheme: const IconThemeData(color: Colors.white),
        //         ),
        //         Expanded(
        //           child: Column(
        //             children: [
        //               Expanded(
        //                 flex: 1,
        //                 child: IndexedStack(
        //                   index: index,
        //                   children: [
        //                     _buildNavigator(
        //                       0,
        //                       const ExploreView(),
        //                     ),
        //                     _buildNavigator(
        //                       1,
        //                       const SearchView(),
        //                     ),
        //                     _buildNavigator(
        //                       2,
        //                       const CurrentPlayingView(),
        //                     ),
        //                     _buildNavigator(
        //                       3,
        //                       const SettingsView(),
        //                     ),
        //                   ],
        //                 ),
        //               ),
        //               const BaseAudioPlayer(),
        //             ],
        //           ),
        //         ),
        //       ],
        //     ),
        //   ),
        // ),
      ),
    );
  }

  // Widget _buildNavigator(int index, Widget child) {
  //   return Navigator(
  //     key: GlobalKey<NavigatorState>(debugLabel: 'navigator$index'),
  //     onGenerateRoute: (settings) => MaterialPageRoute(
  //       builder: (context) => child,
  //     ),
  //   );
  // }

  @override
  void onTrayIconRightMouseDown() async {
    await trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    final player = ref.watch(playerControllerProvider.notifier).getPlayer;
    if (menuItem.key == SystemTrayActions.hideShow) {
      if (await windowManager.isVisible()) {
        await windowManager.hide();
      } else {
        await windowManager.show();
      }
    }
    if (menuItem.key == SystemTrayActions.exit) {
      await windowManager.destroy();
    }
    if (menuItem.key == SystemTrayActions.playPauseMusic) {
      if (player.playing) {
        await player.pause();
      } else {
        await player.play();
      }
    }
    if (player.playing) {
      if (menuItem.key == SystemTrayActions.nextTrack) {
        await player.seekToNext();
      }
      if (menuItem.key == SystemTrayActions.prevTrack) {
        await player.seekToPrevious();
      }
      if (menuItem.key == SystemTrayActions.openPlaylist) {
        await windowManager.show();
      }
    }

    super.onTrayMenuItemClick(menuItem);
  }

  @override
  void onWindowClose() async {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          elevation: 0,
          shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: const Text('Close this window?'),
          content: const Text('Are you sure you want to close this window?'),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Hide'),
              onPressed: () async {
                Navigator.of(context).pop();
                await windowManager.hide();
              },
            ),
            TextButton(
              child: const Text('Close'),
              onPressed: () async {
                Navigator.of(context).pop();
                await windowManager.destroy();
              },
            ),
          ],
        );
      },
    );
  }
}
