import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for the song queue
final songQueueProvider =
    StateNotifierProvider<SongQueueNotifier, List<Map<String, dynamic>>>((ref) {
      return SongQueueNotifier();
    });

class SongQueueNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  SongQueueNotifier() : super([]);

  void addSong(Map<String, dynamic> song) {
    state = [...state, song];
  }

  void removeSong(String songId) {
    state = state.where((song) => song['id'] != songId).toList();
  }

  void clearQueue() {
    state = [];
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = state.removeAt(oldIndex);
    state.insert(newIndex, item);
  }

  Map<String, dynamic>? getNextSong() {
    if (state.isNotEmpty) {
      return state.first;
    }
    return null;
  }

  void playNextSong() {
    if (state.isNotEmpty) {
      state = state.sublist(1);
    }
  }
}
