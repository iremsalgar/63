import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final String apiKey = 'f09947e5d5bbc3a4ba0a6e149efb63f9';
  final TextEditingController _controller = TextEditingController();
  List _searchResults = [];
  List<String> _collections = [];

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  void _loadCollections() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _collections = prefs.getStringList('collections') ?? [];
    });
  }

  void _saveCollections() async {
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

  void _searchMovies(String query) async {
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
        String selectedCollection =
            _collections.isNotEmpty ? _collections[0] : '';
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
                  onChanged: (value) {
                    setState(() {
                      selectedCollection = value!;
                    });
                  },
                  items: _collections
                      .map((collection) => DropdownMenuItem(
                            value: collection,
                            child: Text(collection),
                          ))
                      .toList(),
                ),
              TextField(
                controller: collectionController,
                decoration: const InputDecoration(
                  labelText: 'New Collection Name',
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty && !_collections.contains(value)) {
                    setState(() {
                      _collections.add(value);
                      selectedCollection = value;
                      _saveCollections();
                    });
                  }
                },
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
                if (newCollection.isNotEmpty &&
                    !_collections.contains(newCollection)) {
                  setState(() {
                    _collections.add(newCollection);
                    selectedCollection = newCollection;
                    _saveCollections();
                  });
                }
                if (selectedCollection.isNotEmpty) {
                  _addMovieToCollection(movieId, selectedCollection);
                  Navigator.pop(context);
                }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Movies'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Search',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _searchMovies(_controller.text),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final movie = _searchResults[index];
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
                    trailing: IconButton(
                      icon: const Icon(Icons.favorite_border),
                      onPressed: () => _showAddToCollectionDialog(movie['id']),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
