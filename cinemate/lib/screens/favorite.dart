import 'package:cinemate/services/favorite_movie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final bool _isAlphabetical = false;
  List favoriteMovies = [];
  bool _isLoading = true;
  List<String> favoriteMovieIds = [];
  bool isFavorite = true;
  final String apiKey = 'f09947e5d5bbc3a4ba0a6e149efb63f9';
  final FavoriteService _favoriteService = FavoriteService();

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

    for (final id in favoriteMovieIds) {
      final url = 'https://api.themoviedb.org/3/movie/$id?api_key=$apiKey';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        favoriteMovies.add(json.decode(response.body));
      }
    }

    setState(() {
      _favoriteMovies = favoriteMovies;
      _originalFavoriteMovies = List.from(favoriteMovies);
      _isLoading = false;
    });
  }

  void _removeFavorite(int movieId) async {
    final prefs = await SharedPreferences.getInstance();
    FavoriteService().removeFavoriteMovie(movieId.toString());
    final favoriteMovies = prefs.getStringList('favoriteMovies') ?? [];
    if (favoriteMovies.contains(movieId.toString())) {
      favoriteMovies.remove(movieId.toString());
      await prefs.setStringList('favoriteMovies', favoriteMovies);
      setState(() {
        favoriteMovieIds = favoriteMovies;
      });
    }
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
        title: Text(
          'Favorite Movies',
          style:
              TextStyle(color: Colors.amber[700], fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
              color: Colors.black,
            ))
          : StreamBuilder<QuerySnapshot>(
              stream: _favoriteService.getFavoriteMovies(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No favorite films yet.'));
                }
                final favoriteMovieIds =
                    snapshot.data!.docs.map((doc) => doc.id).toList();

                // Order `_favoriteMovies` according to `favoriteMovieIds`
                List orderedMovies = favoriteMovieIds
                    .map((id) {
                      return _favoriteMovies.firstWhere(
                          (movie) => movie['id'].toString() == id,
                          orElse: () => null);
                    })
                    .where((movie) => movie != null)
                    .toList();

                return GridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    mainAxisSpacing: 8.0,
                    crossAxisSpacing: 8.0,
                  ),
                  itemCount: orderedMovies.length,
                  itemBuilder: (context, index) {
                    final movie = orderedMovies[index];
                    final posterUrl =
                        'https://image.tmdb.org/t/p/w500${movie['poster_path']}';
                    return GestureDetector(
                      onLongPress: () => _favoriteService.removeFavoriteMovie,
                      onTap: () => _showMovieDetailsPage(movie),
                      child: Card(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            movie['poster_path'] != null
                                ? Image.network(
                                    posterUrl,
                                    width: double.infinity,
                                    height: 180,
                                    fit: BoxFit.cover,
                                  )
                                : const SizedBox(
                                    height: 180,
                                    child: Icon(Icons.movie, size: 50),
                                  ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Text(
                                    textAlign: TextAlign.center,
                                    movie['title'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        _removeFavorite(movie['id']),
                                    icon: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      transitionBuilder: (child, animation) {
                                        return RotationTransition(
                                          turns: Tween(begin: 0.3, end: 1.0)
                                              .animate(animation),
                                          child: child,
                                        );
                                      },
                                      child: const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
