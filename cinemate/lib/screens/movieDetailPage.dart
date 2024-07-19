import 'package:cinemate/services/favorite_movie.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class MovieDetailPage extends StatefulWidget {
  final Map movie;
  final bool isTVShow;
  final String posterUrl;

  const MovieDetailPage({
    required this.movie,
    required this.isTVShow,
    required this.posterUrl,
    super.key,
  });

  @override
  // ignore: library_private_types_in_public_api
  _MovieDetailPageState createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  List _cast = [];

  List<String> favoriteMovieIds = [];
  List<String> _collections = [];

  @override
  void initState() {
    super.initState();
    _loadCast();
    _loadCollections();
    _loadFavorites();
  }

  Future<void> _loadCollections() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _collections = prefs.getStringList('collections') ?? [];
    });
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      favoriteMovieIds = prefs.getStringList('favoriteMovies') ?? [];
    });
  }

  void _loadCast() async {
    final int movieId = widget.movie['id'];
    const String apiKey = 'f09947e5d5bbc3a4ba0a6e149efb63f9';
    final url = widget.isTVShow
        ? 'https://api.themoviedb.org/3/tv/$movieId/credits?api_key=$apiKey'
        : 'https://api.themoviedb.org/3/movie/$movieId/credits?api_key=$apiKey';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _cast = data['cast'];
      });
    }
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

  void _addMovieToCollection(int movieId, String collectionName) async {
    final prefs = await SharedPreferences.getInstance();
    final collectionKey = 'collection_$collectionName';
    final collection = prefs.getStringList(collectionKey) ?? [];
    if (!collection.contains(movieId.toString())) {
      collection.add(movieId.toString());
      prefs.setStringList(collectionKey, collection);
    }
  }

  Future<void> _saveCollections() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('collections', _collections);
  }

  void _showAddToCollectionDialog(int movieId) {
    showDialog(
      context: context,
      builder: (context) {
        String? selectedCollection;
        final TextEditingController collectionController =
            TextEditingController();
        return AlertDialog(
          title: const Text('Add to Collection'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_collections.isNotEmpty)
                DropdownButton<String>(
                  value: selectedCollection,
                  onChanged: (newValue) {
                    setState(() {
                      selectedCollection = newValue!;
                    });
                  },
                  items: _collections
                      .map<DropdownMenuItem<String>>((String collection) {
                    return DropdownMenuItem<String>(
                      value: collection,
                      child: Text(collection),
                    );
                  }).toList(),
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
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newCollection = collectionController.text.trim();
                if (newCollection.isNotEmpty) {
                  if (!_collections.contains(newCollection)) {
                    setState(() {
                      _collections.add(newCollection);
                      _saveCollections();
                    });
                  }
                  _addMovieToCollection(movieId, newCollection);
                } else if (selectedCollection != null) {
                  _addMovieToCollection(movieId, selectedCollection!);
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

  @override
  Widget build(BuildContext context) {
    final isFavorite = favoriteMovieIds.contains(widget.movie['id'].toString());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movie Info'),
        actions: [
          ButtonBar(
            children: [
              IconButton(
                onPressed: () {
                  if (isFavorite) {
                    _removeFavorite(widget.movie['id']);
                  } else {
                    _addFavorite(widget.movie['id']);
                    _showAddToCollectionDialog(widget.movie['id']);
                  }
                },
                icon: Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                  key: ValueKey(isFavorite),
                ),
              )
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.network(widget.posterUrl, height: 300),
              ),
              const SizedBox(height: 16),
              Text(
                widget.movie['title'] ?? widget.movie['name'],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.movie['release_date']?.substring(0, 4) ?? ''} | ${widget.movie['genres']?.map((g) => g['name']).join(', ') ?? ''} | ${widget.movie['runtime']} mins',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text('${widget.movie['vote_average']}'),
                  const SizedBox(width: 4),
                  Text('(${widget.movie['vote_count']} reviews)'),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                widget.movie['overview'] ?? 'No description available.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                'Cast & Crew',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _cast.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _cast.length,
                        itemBuilder: (context, index) {
                          final member = _cast[index];
                          final profileUrl = member['profile_path'] != null
                              ? 'https://image.tmdb.org/t/p/w500${member['profile_path']}'
                              : 'https://via.placeholder.com/80';
                          return Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 8),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  backgroundImage: NetworkImage(profileUrl),
                                  radius: 30,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  member['name'],
                                  style: const TextStyle(fontSize: 12),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
