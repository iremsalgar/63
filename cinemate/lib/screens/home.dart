import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List _popularMovies = [];
  final String apiKey = 'f09947e5d5bbc3a4ba0a6e149efb63f9';

  @override
  void initState() {
    super.initState();
    _loadPopularMovies();
  }

  void _loadPopularMovies() async {
    final url = 'https://api.themoviedb.org/3/movie/popular?api_key=$apiKey';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _popularMovies = data['results'];
      });
    }
  }

  void _showAddToCollectionDialog(int movieId) {
    showDialog(
      context: context,
      builder: (context) {
        String selectedCollection = '';
        final TextEditingController collectionController =
            TextEditingController();
        return AlertDialog(
          title: const Text('Add to Collection'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                final newCollection = collectionController.text.trim();
                if (newCollection.isNotEmpty) {
                  final collectionKey = 'collection_$newCollection';
                  final collection = prefs.getStringList(collectionKey) ?? [];
                  if (!collection.contains(movieId.toString())) {
                    collection.add(movieId.toString());
                    prefs.setStringList(collectionKey, collection);
                  }
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
    final randomPage = Random().nextInt(500) +
        1; // 500 sayfa aralığında rastgele bir sayfa seç
    final url =
        'https://api.themoviedb.org/3/discover/movie?api_key=$apiKey&page=$randomPage';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final movies = data['results'];
      final randomMovie = (movies..shuffle()).first;
      _showMovieDetailsDialog(randomMovie);
    }
  }

  Future<void> _recommendRandomTVShow() async {
    final randomPage = Random().nextInt(500) +
        1; // 500 sayfa aralığında rastgele bir sayfa seç
    final url =
        'https://api.themoviedb.org/3/discover/tv?api_key=$apiKey&page=$randomPage';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final tvShows = data['results'];
      final randomTVShow = (tvShows..shuffle()).first;
      _showMovieDetailsDialog(randomTVShow);
    }
  }

  void _showMovieDetailsDialog(dynamic movie) {
    final posterUrl = 'https://image.tmdb.org/t/p/w500${movie['poster_path']}';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(movie['title'] ?? movie['name']),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(posterUrl),
              const SizedBox(height: 10),
              Text(movie['overview'] ?? 'No description available.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Column(
        children: [
          _popularMovies.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _popularMovies.map((movie) {
                      final posterUrl =
                          'https://image.tmdb.org/t/p/w500${movie['poster_path']}';
                      return GestureDetector(
                        onTap: () => _showMovieDetailsDialog(movie),
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
                                icon: const Icon(Icons.favorite_border),
                                onPressed: () =>
                                    _showAddToCollectionDialog(movie['id']),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _recommendRandomTVShow,
                child: Container(
                  width: 100,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 164, 25, 15),
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: _recommendRandomMovie,
                child: Container(
                  width: 100,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 21, 92, 150),
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
