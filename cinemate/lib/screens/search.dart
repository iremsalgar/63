import 'dart:convert';
import 'dart:io';

import 'package:cinemate/screens/home.dart';
import 'package:cinemate/screens/otherProfilePage.dart';
import 'package:cinemate/screens/profile.dart';
import 'package:cinemate/services/auth.dart';
import 'package:cinemate/services/collections.dart';
import 'package:cinemate/services/favorite_movie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  List<String> _collections = [];
  List<String> favoriteMovieIds = [];
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _userResults = [];
  final FirestoreService collectionsServices = FirestoreService();
  final FavoriteService favoriteService = FavoriteService();
  String _searchType = 'Movie/TV Show';
  final String _profileName = "";
  final String _username = "";
  bool isMyProfile = false;
  File? _profileImageFile;
  bool onPress = false;
  final int _followingCount = 29;
  final int _followersCount = 5;
  final double _likesCount = 7.5;

  @override
  void initState() {
    super.initState();
    _loadCollections();
    _loadFavorites();
  }

  Future<void> _loadCollections() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final collectionRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('collections');
      final snapshot = await collectionRef.get();
      setState(() {
        _collections = snapshot.docs.map((doc) => doc.id).toList();
      });
    } catch (e) {
      print('Koleksiyonları yüklerken hata: $e');
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

  Future<void> _searchMovies(String query) async {
    const String apiKey = 'f09947e5d5bbc3a4ba0a6e149efb63f9';
    final url =
        'https://api.themoviedb.org/3/search/movie?api_key=$apiKey&query=$query';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        setState(() {
          _searchResults = (data['results'] as List)
              .map((item) => item as Map<String, dynamic>)
              .toList();
        });
      } else {
        print('Filmleri yüklerken hata: ${response.statusCode}');
      }
    } catch (e) {
      print('Filmleri ararken hata: $e');
    }
  }

  Future<void> _searchUsers(String query) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    try {
      final users = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      setState(() {
        _userResults = users.docs.map((doc) {
          final data = doc.data();
          {
            print('Kullanıcı ID: ${doc.id}'); // Debug print
            return {
              'id': doc.id, // Correctly including document ID
              ...data,
            };
          }
        }).toList();
      });
    } catch (e) {
      print('Kullanıcıları ararken hata: $e');
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
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black),
              ),
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
              child: const Text(
                'Add',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
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

  Future<void> _saveCollections() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final collectionRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('collections');
      for (final collection in _collections) {
        final docRef = collectionRef.doc(collection);
        final docSnapshot = await docRef.get();
        if (!docSnapshot.exists) {
          await docRef.set({'movieIds': []});
        }
      }
    } catch (e) {
      print('Koleksiyonları kaydederken hata: $e');
    }
  }

  void _navigateToDetails(Map<String, dynamic> movie) {
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

  Future<void> _addFavorite(int movieId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await favoriteService.addFavoriteMovie(movieId.toString());
      _loadFavorites(); // Güncellemeleri yeniden yükle
    }
  }

  Future<void> _removeFavorite(int movieId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await favoriteService.removeFavoriteMovie(movieId.toString());
      _loadFavorites(); // Güncellemeleri yeniden yükle
    }
  }

  void _onSearch() {
    final query = _controller.text;
    if (_searchType == 'Movie/TV Show') {
      _searchMovies(query);
    } else if (_searchType == 'User') {
      _searchUsers(query);
    }
  }

  void _onProfileTap(String userId) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (userId == uid) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProfilePage(),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtherProfilePage(userId: userId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Search',
          style:
              TextStyle(color: Colors.amber[700], fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ara...',
              ),
              onSubmitted: (value) {
                _onSearch();
              },
            ),
          ),
          DropdownButton<String>(
            value: _searchType,
            onChanged: (String? newValue) {
              setState(() {
                _searchType = newValue!;
              });
            },
            items: <String>['Movie/TV Show', 'User']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          Expanded(
            child: _searchType == 'Movie/TV Show'
                ? ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final movie = _searchResults[index];
                      final movieId = movie['id'];
                      final isFavorite =
                          favoriteMovieIds.contains(movieId.toString());
                      final posterUrl =
                          'https://image.tmdb.org/t/p/w500${movie['poster_path']}';

                      return ListTile(
                        leading: Image.network(posterUrl),
                        title: Text(movie['title']),
                        trailing: IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: Colors.amber,
                          ),
                          onPressed: () {
                            setState(() {
                              if (isFavorite) {
                                _removeFavorite(movieId);
                              } else {
                                _addFavorite(movieId);
                                _showAddToCollectionDialog(movieId);
                              }
                            });
                          },
                        ),
                        onTap: () => _navigateToDetails(movie),
                        onLongPress: () => _showAddToCollectionDialog(movieId),
                      );
                    },
                  )
                : ListView.builder(
                    itemCount: _userResults.length,
                    itemBuilder: (context, index) {
                      final user = _userResults[index];
                      final userId = user['id'];
                      final username = user['username'];

                      return ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(username),
                        onTap: () => _onProfileTap(userId),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
