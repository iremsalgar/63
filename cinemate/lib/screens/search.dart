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
  Set<int> _favoriteMovies = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteMovies = prefs.getStringList('favoriteMovies') ?? [];
    setState(() {
      _favoriteMovies = favoriteMovies.map((id) => int.parse(id)).toSet();
    });
  }

  void _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(
      'favoriteMovies',
      _favoriteMovies.map((id) => id.toString()).toList(),
    );
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

  void _toggleFavorite(int movieId) {
    setState(() {
      if (_favoriteMovies.contains(movieId)) {
        _favoriteMovies.remove(movieId);
      } else {
        _favoriteMovies.add(movieId);
      }
      _saveFavorites();
    });
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
                return ListTile(
                  title: Text(movie['title']),
                  subtitle: Text(movie['overview'] ?? 'No description'),
                  trailing: IconButton(
                    icon: Icon(
                      _favoriteMovies.contains(movie['id'])
                          ? Icons.favorite
                          : Icons.favorite_border,
                    ),
                    onPressed: () => _toggleFavorite(movie['id']),
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
