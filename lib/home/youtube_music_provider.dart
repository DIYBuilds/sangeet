import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

final youtubeExplodeProvider = Provider((ref) {
  final ytExplode = YoutubeExplode();
  ref.onDispose(() {
    ytExplode.close(); // Close the client when the provider is disposed
  });
  return ytExplode;
});

// Specify the type for FutureProvider for better type safety
final youtubeMusicLibraryProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final ytExplode = ref.watch(youtubeExplodeProvider);

  try {
    // NOTE: youtube_explode_dart primarily works with public YouTube data.
    // Accessing a user's private YouTube Music library (liked songs, private playlists)
    // typically requires OAuth 2.0 authentication, which youtube_explode_dart may not directly support for YT Music specific libraries.
    // This example will demonstrate searching for public playlists and fetching their videos.
    // You WILL need to adapt this significantly if you intend to access private user data.

    // Example: Search for public playlists related to "My Library" or a specific genre/artist
    // This is a placeholder for how you might find relevant content.
    // Filter for playlists from the search results
    // Take the first playlist found as an example
    // https://music.youtube.com/playlist?list=RDCLAK5uy_kYgQNqvsOO3uC2rwbkCNEvEpIoJV-VkX8&playnext=1&si=r2Ta0Kn-0GDjwrfn
    const String playlistId = 'RDCLAK5uy_kYgQNqvsOO3uC2rwbkCNEvEpIoJV-VkX8';
    var videos = await ytExplode.playlists.getVideos(playlistId).toList();

    // Convert video data to the desired Map format
    return videos.map((video) {
      return {
        'id': video.id.value,
        'thumbnail': video.thumbnails.standardResUrl,
        'title': video.title,
        'artist': video.author,
        'thumbnailUrl': video.thumbnails.mediumResUrl,
        'duration': video.duration?.inSeconds,
      };
    }).toList();
  } catch (e) {
    print('Error fetching YouTube Music data with youtube_explode_dart: $e');
    return []; // Return empty list on error
  }
});
