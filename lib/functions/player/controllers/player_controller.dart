import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_discord_rpc/flutter_discord_rpc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sangeet/core/api_provider.dart';
import 'package:sangeet/core/core.dart';
import 'package:sangeet/functions/player/widgets/common.dart';
import 'package:sangeet/functions/settings/controllers/settings_controller.dart';
import 'package:sangeet_api/models.dart';
import 'package:sangeet_api/modules/song/models/song_model.dart';
import 'package:sangeet_api/sangeet_api.dart';
import 'package:smtc_windows/smtc_windows.dart';

final playerControllerProvider =
    StateNotifierProvider<PlayerController, bool>((ref) {
  return PlayerController(
    settingsController: ref.watch(settingsControllerProvider.notifier),
    api: ref.watch(sangeetAPIProvider),
  );
});

class PlayerController extends StateNotifier<bool> {
  final SettingsController _settingsController;
  final SangeetAPI _api;

  final _player = AudioPlayer(
    handleInterruptions: false,
    androidApplyAudioAttributes: false,
    handleAudioSessionActivation: false,
  );
  final _smtc = SMTCWindows(
    metadata: const MusicMetadata(
      title: 'Not Playing',
      album: '',
      albumArtist: '',
      artist: '',
      thumbnail: 'https://priyanshuverma-dev.github.io/card.png',
    ),
    // Timeline info for the OS media player
    timeline: const PlaybackTimeline(
      startTimeMs: 0,
      endTimeMs: 1000,
      positionMs: 0,
      minSeekTimeMs: 0,
      maxSeekTimeMs: 1000,
    ),
    // Which buttons to show in the OS media player
    config: const SMTCConfig(
      fastForwardEnabled: true,
      nextEnabled: true,
      pauseEnabled: true,
      playEnabled: true,
      rewindEnabled: true,
      prevEnabled: true,
      stopEnabled: true,
    ),
  );
  final playlist = ConcatenatingAudioSource(
    useLazyPreparation: true,
    children: [],
  );

  PlayerController({
    required SettingsController settingsController,
    required SangeetAPI api,
  })  : _settingsController = settingsController,
        _api = api,
        super(false);

  AudioPlayer get getPlayer => _player;
  SMTCWindows get getSMTC => _smtc;
  ConcatenatingAudioSource get getplaylist => playlist;

  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
          _player.positionStream,
          _player.bufferedPositionStream,
          _player.durationStream,
          (position, bufferedPosition, duration) => PositionData(
              position, bufferedPosition, duration ?? Duration.zero));

  Future<void> runRadio({
    required String radioId,
    required MediaType type,
    VoidCallback? redirect,
    List<SongModel>? prevSongs,
    bool playCurrent = false,
  }) async {
    // final session = await AudioSession.instance;
    try {
      // await session.setActive(true);
      List<SongModel> songs = [];

      if (playlist.length > 0) {
        await playlist.clear();
      }
      final quality = await _settingsController.getSongQuality();
      if (prevSongs != null) {
        final songsCopy = prevSongs;
        if (playCurrent) {
          final i = songsCopy.indexWhere((element) => element.id == radioId);
          songsCopy.removeRange(0, i);
        }
        songs = songsCopy;
      } else {
        if (type == MediaType.song) {
          final songsObjects =
              await _api.song.radio(songId: radioId, limit: 12);
          final song = await _api.song.getById(songId: radioId);
          if (songsObjects == null || song == null) {
            throw Error.throwWithStackTrace(
                "Can't load right now", StackTrace.empty);
          }

          songs = [song, ...songsObjects.songs];
        }

        if (type == MediaType.album) {
          final album = await _api.album.getById(albumId: radioId);
          if (album == null) {
            throw Error.throwWithStackTrace(
                "Album not found", StackTrace.empty);
          }
          songs = album.songs;
        }
        if (type == MediaType.playlist) {
          final playlistModel = await _api.playlist.getById(id: radioId);
          if (playlistModel == null) {
            throw Error.throwWithStackTrace(
              "Playlist not found",
              StackTrace.empty,
            );
          }

          songs = playlistModel.songs;
        }
        if (type == MediaType.radio) {
          final radio =
              await _api.song.radio(songId: radioId, featured: true, limit: 12);
          if (radio == null) {
            throw Error.throwWithStackTrace(
              "Radio not found",
              StackTrace.empty,
            );
          }
          songs = radio.songs;
        }
      }

      for (var i = 0; i < songs.length; i++) {
        final uri = songs[i]
            .urls
            .where((element) => element.quality == quality.name)
            .toList()[0]
            .url;

        final song = songs[i];

        await playlist.add(AudioSource.uri(
          Uri.parse(uri),
          tag: song,
        ));
      }

      await _player.setAudioSource(playlist, preload: true);
      redirect?.call();

      await _player.play();
      SongModel song = _player.audioSource?.sequence[_player.currentIndex!].tag;
      await _smtc.enableSmtc();
      await _smtc.updateMetadata(MusicMetadata(
        title: song.title,
        album: song.albumName,
        thumbnail: song.images[1].url,
        artist: song.artists[0].name,
      ));
      await _smtc.setPlaybackStatus(PlaybackStatus.playing);
      await FlutterDiscordRPC.instance.setActivity(
        activity: RPCActivity(
          activityType: ActivityType.listening,
          state: "${song.title} - ${song.albumName}",
          assets: RPCAssets(
            largeImage: song.images[2].url,
            smallText: "${song.title} Playing Now",
          ),
          details:
              "Playing ${song.title} by ${song.artists[0].name} on Sangeet.",
          buttons: [
            const RPCButton(
                label: "Open in Sangeet",
                url: 'https://github.com/priyanshuverma-dev/sangeet')
          ],
        ),
      );

      _player.currentIndexStream.listen((indx) async {
        SongModel currentSong = _player.audioSource?.sequence[indx ?? 0].tag;
        await _smtc.updateMetadata(MusicMetadata(
          title: currentSong.title,
          album: currentSong.albumName,
          thumbnail: currentSong.images[1].url,
          artist: currentSong.artists[0].name,
        ));
        await FlutterDiscordRPC.instance.setActivity(
          activity: RPCActivity(
            activityType: ActivityType.listening,
            state: "${currentSong.title} Playing Now",
            assets: RPCAssets(
              largeImage: currentSong.images[2].url,
              smallText: "${currentSong.title} - ${currentSong.albumName}",
            ),
            details:
                "${currentSong.title} by ${currentSong.artists[0].name} on Sangeet Desktop.",
            buttons: [
              const RPCButton(
                  label: "Open in Sangeet",
                  url: 'https://github.com/priyanshuverma-dev/sangeet')
            ],
          ),
        );
      });

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          _smtc.buttonPressStream.listen((event) async {
            switch (event) {
              case PressedButton.play:
                _smtc.setPlaybackStatus(PlaybackStatus.playing);
                await _player.play();
                break;
              case PressedButton.pause:
                _smtc.setPlaybackStatus(PlaybackStatus.paused);
                await _player.pause();
                break;
              case PressedButton.next:
                await _smtc.setPlaybackStatus(PlaybackStatus.playing);
                await _player.seekToNext();
                break;
              case PressedButton.previous:
                await _smtc.setPlaybackStatus(PlaybackStatus.playing);
                await _player.seekToPrevious();

                break;
              case PressedButton.stop:
                _smtc.setPlaybackStatus(PlaybackStatus.stopped);
                _smtc.disableSmtc();
                await _player.stop();
                break;
              default:
                break;
            }
          });
        } catch (e) {
          debugPrint("Error: $e");
        }
      });
    } on PlayerException catch (e) {
      if (kDebugMode) {
        print("Error message: ${e.message}");
      }
      BotToast.showText(text: "Error: ${e.message}");
    } on PlayerInterruptedException catch (e) {
      if (kDebugMode) {
        print("Connection aborted: ${e.message}");
      }
      BotToast.showText(text: "Error: ${e.message}");
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      BotToast.showText(text: "Error: ${e.toString()}");
    } finally {
      // await session.setActive(false);
    }
  }

  Future<void> loadMoreSongs({
    required String songId,
  }) async {
    try {
      log("CALLED ${playlist.length} AT ${DateTime.timestamp()}");
      if (playlist.length > 20) {
        return;
      }
      await playlist.removeRange(0, 10);

      final songsObjects = await _api.song.radio(songId: songId, limit: 10);
      if (songsObjects == null) {
        throw Error.throwWithStackTrace(
          "Can't load right now",
          StackTrace.empty,
        );
      }

      final quality = await _settingsController.getSongQuality();
      for (var i = 0; i < songsObjects.songs.length; i++) {
        final uri = songsObjects.songs[i].urls
            .where((element) => element.quality == quality.name)
            .toList()[0]
            .url;

        final song = songsObjects.songs[i];

        await playlist.insert(
          playlist.length,
          AudioSource.uri(
            Uri.parse(uri),
            tag: song,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      BotToast.showText(text: "Error: ${e.toString()}");
    }
  }

  Future<void> addSongToQueue({required SongModel song}) async {
    try {
      final quality = await _settingsController.getSongQuality();
      final uri = song.urls
          .where((element) => element.quality == quality.name)
          .toList()[0]
          .url;
      await playlist.add(AudioSource.uri(
        Uri.parse(uri),
        tag: song,
      ));

      BotToast.showText(text: "Added to queue");
    } catch (e) {
      BotToast.showText(text: "Error: ${e.toString()}");
    }
  }

  Future<void> addSongToNext({required SongModel song}) async {
    try {
      final indx = (_player.currentIndex ?? 0) + 1;

      final quality = await _settingsController.getSongQuality();
      final uri = song.urls
          .where((element) => element.quality == quality.name)
          .toList()[0]
          .url;
      await playlist.insert(
        indx,
        AudioSource.uri(
          Uri.parse(uri),
          tag: song,
        ),
      );

      BotToast.showText(text: "Added to play next");
    } catch (e) {
      BotToast.showText(text: "Error: ${e.toString()}");
    }
  }

  Future<void> reset() async {
    await _player.stop();
    await playlist.clear();
    await _smtc.disableSmtc();
  }

  @override
  void dispose() {
    _player.dispose();
    _smtc.dispose();
    super.dispose();
  }
}
