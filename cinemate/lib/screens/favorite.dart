import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'movieDetailPage.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  _FavoritePageState createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  List _favoriteMovies = [];
  List _originalFavoriteMovies = [];
  bool _isAlphabetical = false;
  final String apiKey = 'f09947e5d5bbc3a4ba0a6e149efb63f9';

  @override
  void initState() {
    super.initState();
    _loadFavoritesAndCollections();
  }

  void _loadFavoritesAndCollections() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteMovieIds = prefs.getStringList('favoriteMovies') ?? [];
    final allCollections = prefs.getStringList('collections') ?? [];

    for (final collectionName in allCollections) {
      final collectionKey = 'collection_$collectionName';
      final collectionMovieIds = prefs.getStringList(collectionKey) ?? [];
      favoriteMovieIds.addAll(collectionMovieIds);
    }

    final uniqueMovieIds = favoriteMovieIds.toSet().toList();
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
      _originalFavoriteMovies =
          List.from(favoriteMovies); // Keep the original order
    });
  }

  void _toggleSortOrder() {
    setState(() {
      _isAlphabetical = !_isAlphabetical;
      if (_isAlphabetical) {
        _favoriteMovies.sort((a, b) => a['title'].compareTo(b['title']));
      } else {
        _favoriteMovies = List.from(_originalFavoriteMovies);
      }
    });
  }

  void _showMovieDetailsPage(Map movie) {
    final posterUrl = 'https://image.tmdb.org/t/p/w500${movie['poster_path']}';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailPage(
          movie: movie,
          isTVShow: false,
          posterUrl: posterUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Movies'),
        actions: [
          IconButton(
            icon: Icon(_isAlphabetical ? Icons.sort_by_alpha : Icons.sort),
            onPressed: _toggleSortOrder,
          ),
        ],
      ),
      body: _favoriteMovies.isEmpty
          ? const Center(child: Text('No favorite films yet.'))
          : GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                mainAxisSpacing: 8.0,
                crossAxisSpacing: 8.0,
              ),
              itemCount: _favoriteMovies.length,
              itemBuilder: (context, index) {
                final movie = _favoriteMovies[index];
                final posterUrl =
                    'https://image.tmdb.org/t/p/w500${movie['poster_path']}';
                return GestureDetector(
                  onTap: () => _showMovieDetailsPage(movie),
                  child: Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        movie['poster_path'] != null
                            ? Image.network(
                                posterUrl,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                              )
                            : const SizedBox(
                                height: 200,
                                child: Icon(Icons.movie, size: 100),
                              ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            movie['title'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
