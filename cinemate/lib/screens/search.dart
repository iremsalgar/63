import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'movieDetailPage.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  List _searchResults = [];
  List<String> _collections = [];

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  Future<void> _loadCollections() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _collections = prefs.getStringList('collections') ?? [];
    });
  }

  Future<void> _searchMovies(String query) async {
    final String apiKey = 'f09947e5d5bbc3a4ba0a6e149efb63f9';
    final url =
        'https://api.themoviedb.org/3/search/movie?api_key=$apiKey&query=$query';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _searchResults = data['results'];
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
                } else if (selectedCollection.isNotEmpty) {
                  _addMovieToCollection(movieId, selectedCollection);
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

  Future<void> _saveCollections() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('collections', _collections);
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

  void _navigateToDetails(Map movie) {
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
        title: const Text('Search'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Search for a movie',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    _searchMovies(_controller.text);
                  },
                ),
              ),
              onSubmitted: (query) {
                _searchMovies(query);
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final movie = _searchResults[index];
                return ListTile(
                  leading: movie['poster_path'] != null
                      ? Image.network(
                          'https://image.tmdb.org/t/p/w500${movie['poster_path']}',
                          width: 50,
                          height: 75,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.movie),
                  title: Text(movie['title']),
                  subtitle: Text(movie['release_date'] ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite_border),
                    onPressed: () {
                      _showAddToCollectionDialog(movie['id']);
                    },
                  ),
                  onTap: () => _navigateToDetails(movie),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
