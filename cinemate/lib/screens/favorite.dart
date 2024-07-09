import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  _FavoritePageState createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  final String apiKey = 'f09947e5d5bbc3a4ba0a6e149efb63f9';
  List _favoriteMovies = [];

  @override
  void initState() {
    super.initState();
    _loadFavoritesAndCollections();
  }

  void _loadFavoritesAndCollections() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteMovieIds = prefs.getStringList('favoriteMovies') ?? [];
    final allCollections = prefs.getStringList('collections') ?? [];

    // Tüm koleksiyonlardaki film ID'lerini ekleyin
    for (final collectionName in allCollections) {
      final collectionKey = 'collection_$collectionName';
      final collectionMovieIds = prefs.getStringList(collectionKey) ?? [];
      favoriteMovieIds.addAll(collectionMovieIds);
    }

    final uniqueMovieIds =
        favoriteMovieIds.toSet().toList(); // Tekrarlanan ID'leri kaldırın
    final favoriteMovies = [];

    for (final id in uniqueMovieIds) {
      final url = 'https://api.themoviedb.org/3/movie/$id?api_key=$apiKey';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        favoriteMovies.add(json.decode(response.body));
      }
    }

    setState(() {
      _favoriteMovies = favoriteMovies;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Movies'),
      ),
      body: _favoriteMovies.isEmpty
          ? const Center(child: Text('No favorite films yet.'))
          : ListView.builder(
              itemCount: _favoriteMovies.length,
              itemBuilder: (context, index) {
                final movie = _favoriteMovies[index];
                final posterUrl =
                    'https://image.tmdb.org/t/p/w500${movie['poster_path']}';
                return Card(
                  child: ListTile(
                    leading: movie['poster_path'] != null
                        ? Image.network(posterUrl)
                        : const SizedBox(
                            width: 50, height: 75, child: Icon(Icons.movie)),
                    title: Text(movie['title']),
                    subtitle: Text(movie['overview'] ?? 'No description'),
                  ),
                );
              },
            ),
    );
  }
}
