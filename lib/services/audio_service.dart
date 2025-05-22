import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:sangeet/home/home_screen.dart'; // For providers like youtubeExplodeProvider, playingSongIdProvider, currentPlayingSongProvider
import 'package:sangeet/home/queue_provider.dart'; // For songQueueProvider
import 'package:sangeet/home/youtube_music_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'package:flutter/foundation.dart';

final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService(ref);
});

class AudioService {
  final Ref _ref;
  AudioService(this._ref);

  AudioPlayer get _audioPlayer => _ref.read(audioPlayerProvider);
  yt.YoutubeExplode get _ytExplode => _ref.read(youtubeExplodeProvider);

  Future<void> playSong(
    Map<String, dynamic> song, {
    BuildContext? context,
  }) async {
    final playingSongId = _ref.read(playingSongIdProvider);
    final songId = song['id'] as String;

    // Indicate loading state
    _ref.read(isLoadingSongProvider.notifier).state = true;

    if (playingSongId == songId && _audioPlayer.state == PlayerState.playing) {
      await _audioPlayer.pause();
      _ref.read(isLoadingSongProvider.notifier).state = false;
    } else if (playingSongId == songId &&
        _audioPlayer.state == PlayerState.paused) {
      await _audioPlayer.resume();
      _ref.read(isLoadingSongProvider.notifier).state = false;
    } else {
      try {
        var manifest = await _ytExplode.videos.streamsClient.getManifest(
          songId,
        );
        var streamInfo = manifest.audioOnly.withHighestBitrate();
        final urlString = streamInfo.url.toString();

        if (urlString.isNotEmpty) {
          await _audioPlayer.play(UrlSource(urlString));
          _ref.read(playingSongIdProvider.notifier).state = songId;
          _ref.read(currentPlayingSongProvider.notifier).state = song;
        } else {
          if (kDebugMode) {
            print('Error: Audio stream URL is empty for songId: $songId');
          }
          // Optionally show a snackbar if context is available
          // if (context != null) {
          //   ScaffoldMessenger.of(context).showSnackBar(
          //     const SnackBar(content: Text('Error: Audio stream URL is empty.')),
          //   );
          // }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error setting audio source for $songId: $e');
        }
        // Optionally show a snackbar if context is available
        // if (context != null) {
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     SnackBar(content: Text('Error playing song: ${e.toString()}')),
        //   );
        // }
      } finally {
        _ref.read(isLoadingSongProvider.notifier).state = false;
      }
    }
  }

  void playNextFromQueue() {
    final nextSong = _ref.read(songQueueProvider.notifier).getNextSong();
    if (nextSong != null) {
      playSong(nextSong);
      _ref.read(songQueueProvider.notifier).playNextSong(); // Remove from queue
    } else {
      _ref.read(playingSongIdProvider.notifier).state = null;
      _ref.read(currentPlayingSongProvider.notifier).state = null;
    }
  }

  void playPreviousFromQueueOrRestart() {
    // This is a simplified version. A more robust solution would involve tracking play history.
    if (_audioPlayer.state == PlayerState.playing ||
        _audioPlayer.state == PlayerState.paused) {
      // If a song is playing or paused, restart it.
      _audioPlayer.seek(Duration.zero);
      if (_ref.read(isPlayingProvider) == false &&
          _audioPlayer.state == PlayerState.paused) {
        _audioPlayer.resume();
      }
    } else {
      // If no song is active, try to play the first song in the queue if available.
      final queue = _ref.read(songQueueProvider);
      if (queue.isNotEmpty) {
        playSong(queue.first);
        // Optionally, you might want to adjust the queue (e.g., move this song to current and remove)
      }
    }
  }
}

// Provider to track if a song is currently being loaded
final isLoadingSongProvider = StateProvider<bool>((ref) => false);
