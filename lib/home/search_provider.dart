import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'youtube_music_provider.dart'; // For youtubeExplodeProvider

// Provider for the current search query
final searchQueryProvider = StateProvider<String>((ref) => '');

// Provider to fetch search results based on the query
final searchMusicProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final searchQuery = ref.watch(searchQueryProvider);
      final ytExplode = ref.watch(youtubeExplodeProvider);

      if (searchQuery.trim().isEmpty) {
        return []; // Return empty list if search query is empty
      }

      try {
        // Using searchVideos to get video results directly
        var search = await ytExplode.search.searchContent(searchQuery);
        var searchVideos = search.whereType<SearchVideo>().toList();

        return searchVideos.map((video) {
          return {
            'id': video.id.value,
            'title': video.title,
            'artist': video.author, // Video author as artist
            'thumbnailUrl': video.thumbnails.first.url,
            'duration': video.duration,
          };
        }).toList();
      } catch (e) {
        print('Error searching music for query "$searchQuery": $e');
        // Optionally, you could return a custom error state or rethrow
        throw Exception('Failed to search music: $e');
      }
    });
