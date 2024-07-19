import 'package:cinemate/services/favorite_movie.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'movieDetailPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  List _searchResults = [];
  List<String> _collections = [];
  List<String> favoriteMovieIds = [];
  List _userResults = [];
  String _searchType = 'Movie/TV Show';

  @override
  void initState() {
    super.initState();
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

  Future<void> _searchMovies(String query) async {
    const String apiKey = 'f09947e5d5bbc3a4ba0a6e149efb63f9';
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

  Future<void> _searchUsers(String query) async {
    final users = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    setState(() {
      _userResults = users.docs.map((doc) => doc.data()).toList();
    });
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

  void _onSearch() {
    final query = _controller.text;
    if (_searchType == 'Movie/TV Show') {
      _searchMovies(query);
    } else {
      _searchUsers(query);
    }
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
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          labelText: 'Search',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: _onSearch,
                          ),
                        ),
                        onSubmitted: (query) => _onSearch(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    DropdownButton<String>(
                      value: _searchType,
                      items: <String>['Movie/TV Show', 'User']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _searchType = newValue!;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length + _userResults.length,
              itemBuilder: (context, index) {
                if (_searchType == 'Movie/TV Show' &&
                    index < _searchResults.length) {
                  final movie = _searchResults[index];
                  final isFavorite =
                      favoriteMovieIds.contains(movie['id'].toString());
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
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          return RotationTransition(
                            turns:
                                Tween(begin: 0.3, end: 1.0).animate(animation),
                            child: child,
                          );
                        },
                        child: Icon(
                          isFavorite ? Icons.star : Icons.star_border,
                          key: ValueKey(isFavorite),
                        ),
                      ),
                      onPressed: () {
                        if (isFavorite) {
                          _removeFavorite(movie['id']);
                        } else {
                          _addFavorite(movie['id']);
                          _showAddToCollectionDialog(movie['id']);
                        }
                      },
                    ),
                    onTap: () => _navigateToDetails(movie),
                  );
                } else if (_searchType == 'User' &&
                    index < _userResults.length) {
                  final user = _userResults[index];
                  return ListTile(
                    leading: user['profileImageUrl'] != null
                        ? Image.network(
                            user['profileImageUrl'],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.person),
                    title: Text(user['username']),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
