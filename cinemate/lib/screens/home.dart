import 'package:cinemate/services/collections.dart';
import 'package:cinemate/services/favorite_movie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import 'messagePage.dart';
import 'movieDetailPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List _popularMovies = [];
  List<String> _collections = [];
  List<String> favoriteMovieIds = [];
  final FavoriteService favoriteService = FavoriteService();
  final FirestoreService collectionsServices = FirestoreService();
  final String apiKey = 'f09947e5d5bbc3a4ba0a6e149efb63f9';

  @override
  void initState() {
    super.initState();
    _loadPopularMovies();
    _loadCollections();
    _loadFavorites();
  }

  Future<void> _loadCollections() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final collections = await collectionsServices.getCollections(uid);
      setState(() {
        _collections = collections;
      });
    }
  }

  Future<void> _loadFavorites() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final favoritesStream = favoriteService.getFavoriteMovies();
      favoritesStream.listen((snapshot) {
        final favoriteIds = snapshot.docs.map((doc) => doc.id).toList();
        setState(() {
          favoriteMovieIds = favoriteIds;
        });
      });
    }
  }

  Future<void> _loadPopularMovies() async {
    final url = 'https://api.themoviedb.org/3/movie/popular?api_key=$apiKey';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _popularMovies = data['results'];
      });
    }
  }

  Future<void> _addCollection(String collectionName) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && collectionName.isNotEmpty) {
      await collectionsServices.addCollection(uid, collectionName);
      setState(() {
        _collections.add(collectionName);
      });
    }
  }

  Future<void> _addMovieToCollection(int movieId, String collectionName) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await collectionsServices.addMovieToCollection(
          uid, collectionName, movieId.toString());
    }
  }

  void _showAddToCollectionDialog(int movieId) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController collectionController =
            TextEditingController();
        return AlertDialog(
          title: const Text('Add to Collection'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: _collections.isNotEmpty ? _collections.first : null,
                hint: const Text('Select Collection'),
                items: _collections.map((collection) {
                  return DropdownMenuItem<String>(
                    value: collection,
                    child: Text(collection),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _addMovieToCollection(movieId, value);
                    Navigator.pop(context);
                  }
                },
              ),
              TextField(
                controller: collectionController,
                decoration: const InputDecoration(
                  labelText: 'New Collection Name',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newCollection = collectionController.text.trim();
                if (newCollection.isNotEmpty) {
                  await _addCollection(newCollection);
                  _addMovieToCollection(movieId, newCollection);
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _recommendRandomMovie() async {
    final randomPage = Random().nextInt(500) + 1;
    final url =
        'https://api.themoviedb.org/3/discover/movie?api_key=$apiKey&page=$randomPage';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final movies = data['results'];
      final randomMovie = (movies..shuffle()).first;
      _showMovieDetailsPage(randomMovie, false);
    }
  }

  Future<void> _recommendRandomTVShow() async {
    final randomPage = Random().nextInt(500) + 1;
    final url =
        'https://api.themoviedb.org/3/discover/tv?api_key=$apiKey&page=$randomPage';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final tvShows = data['results'];
      final randomTVShow = (tvShows..shuffle()).first;
      _showMovieDetailsPage(randomTVShow, true);
    }
  }

  void _showMovieDetailsPage(Map movie, bool isTVShow) {
    final posterUrl = 'https://image.tmdb.org/t/p/w500${movie['poster_path']}';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailPage(
          movie: movie,
          isTVShow: isTVShow,
          posterUrl: posterUrl,
        ),
      ),
    );
  }

  void _addFavorite(int movieId) async {
    final prefs = await SharedPreferences.getInstance();
    FavoriteService().addFavoriteMovie(movieId.toString());
    final favoriteMovies = prefs.getStringList('favoriteMovies') ?? [];
    if (!favoriteMovies.contains(movieId.toString())) {
      favoriteMovies.add(movieId.toString());
      await prefs.setStringList('favoriteMovies', favoriteMovies);
      setState(() {
        favoriteMovieIds = favoriteMovies;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: const [],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _popularMovies.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _popularMovies.map((movie) {
                        final isFavorite =
                            favoriteMovieIds.contains(movie['id'].toString());
                        final posterUrl =
                            'https://image.tmdb.org/t/p/w500${movie['poster_path']}';
                        return GestureDetector(
                          onTap: () => _showMovieDetailsPage(movie, false),
                          child: Card(
                            child: Column(
                              children: [
                                movie['poster_path'] != null
                                    ? Image.network(
                                        posterUrl,
                                        width: 100,
                                        height: 150,
                                        fit: BoxFit.cover,
                                      )
                                    : const SizedBox(
                                        width: 100,
                                        height: 150,
                                        child: Icon(Icons.movie),
                                      ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    movie['title'],
                                    style: const TextStyle(fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                IconButton(
                                    icon: isFavorite
                                        ? const Icon(Icons.star)
                                        : const Icon(Icons.star_border),
                                    onPressed: () {
                                      if (isFavorite) {
                                        _removeFavorite(movie['id']);
                                      } else {
                                        _addFavorite(movie['id']);
                                        _showAddToCollectionDialog(movie['id']);
                                      }
                                    }),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/image/RemovePopcorn.png',
                  width: 300,
                  height: 300,
                ),
                Positioned(
                  left: 16,
                  bottom: 84,
                  child: GestureDetector(
                    onTap: _recommendRandomTVShow,
                    child: Container(
                      width: 50,
                      height: 50,
                      color: Colors.transparent,
                    ),
                  ),
                ),
                Positioned(
                  right: 17,
                  bottom: 65,
                  child: GestureDetector(
                    onTap: _recommendRandomMovie,
                    child: Container(
                      width: 50,
                      height: 50,
                      color: Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
