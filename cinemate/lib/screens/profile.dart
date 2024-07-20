import 'package:cinemate/screens/movieDetailPage.dart';
import 'package:cinemate/screens/profile.dart';
import 'package:cinemate/services/auth.dart';
import 'package:cinemate/services/collections.dart';
import 'package:cinemate/services/favorite_movie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'editProfile.dart';
import 'dart:io';
import 'settings.dart'; // SettingsPage'i ekliyoruz

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  List<String> _collections = [];
  List<String> collectionsMoviesId = [];
  String _profileName = "";
  String _username = "";
  File? _profileImageFile;
  int _followingCount = 29;
  int _followersCount = 5;
  double _likesCount = 7.5;
  CollectionsServices collectionsServices = CollectionsServices();

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadCollections();
  }

  void _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final retrievedUsername = await FirebaseAuthService().getUsername(uid);
      setState(() {
        _profileName = retrievedUsername;
        _username = prefs.getString('username') ?? '@salgar_irem';
        final profileImagePath = prefs.getString('profileImagePath');
        if (profileImagePath != null) {
          _profileImageFile = File(profileImagePath);
        }
        _followingCount = prefs.getInt('followingCount') ?? 29;
        _followersCount = prefs.getInt('followersCount') ?? 5;
        _likesCount = prefs.getDouble('likesCount') ?? 7.5;
      });
    }
  }

  void _addCollections(int movieId) async {
    final prefs = await SharedPreferences.getInstance();
    collectionsServices.addFavoriteCollections(movieId.toString());

    final collectionsMovies = prefs.getStringList('collectionsMovies') ?? [];
    if (collectionsMovies.contains(movieId.toString())) {
      collectionsMovies.add(movieId.toString());
      await prefs.setStringList('favoriteMovies', collectionsMovies);
      setState(() {
        collectionsMoviesId = collectionsMovies;
      });
    }
  }

  void _removeCollections(int movieId) async {
    final prefs = await SharedPreferences.getInstance();
    collectionsServices.removeFavoriteCollections(movieId.toString());

    final collectionsMovies = prefs.getStringList('collectionsMovies') ?? [];
    if (collectionsMovies.contains(movieId.toString())) {
      collectionsMovies.remove(movieId.toString());
      await prefs.setStringList('favoriteMovies', collectionsMovies);
      setState(() {
        collectionsMoviesId = collectionsMovies;
      });
    }
  }

  void _loadCollections() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _collections = prefs.getStringList('collections') ?? [];
    });
  }

  Future<void> _removeCollection(String collectionName) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _collections.remove(collectionName);
      prefs.setStringList('collections', _collections);
      prefs.remove('collection_$collectionName');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfilePage(),
                ),
              ).then((_) =>
                  _loadProfile()); // Profili güncellemek için geri dönünce yeniden yükle
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 50,
              backgroundImage: _profileImageFile != null
                  ? FileImage(_profileImageFile!)
                  : const NetworkImage('https://via.placeholder.com/150')
                      as ImageProvider,
            ),
            const SizedBox(height: 10),
            Text(
              _profileName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              _username,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(
                      '$_followingCount',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'Following',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Column(
                  children: [
                    Text(
                      '$_followersCount',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'Followers',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Column(
                  children: [
                    Text(
                      '$_likesCount M',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'Likes',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Collections',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _collections.isEmpty
                      ? const Text('No collections yet.')
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _collections.length,
                          itemBuilder: (context, index) {
                            final collectionName = _collections[index];
                            return Dismissible(
                              key: Key(collectionName),
                              direction: DismissDirection.endToStart,
                              onDismissed: (direction) {
                                _removeCollections(index);
                              },
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              child: ListTile(
                                title: Text(collectionName),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CollectionPage(
                                          collectionName: collectionName),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CollectionPage extends StatefulWidget {
  final String collectionName;

  const CollectionPage({required this.collectionName, super.key});

  @override
  _CollectionPageState createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  final String apiKey = 'f09947e5d5bbc3a4ba0a6e149efb63f9';
  List _movies = [];
  final FavoriteService _favoriteService = FavoriteService();

  @override
  void initState() {
    super.initState();
    _loadCollectionMovies();
  }

  void _loadCollectionMovies() async {
    final prefs = await SharedPreferences.getInstance();
    final movieIds =
        prefs.getStringList('collection_${widget.collectionName}') ?? [];
    final List movies = [];

    for (final id in movieIds) {
      final url = 'https://api.themoviedb.org/3/movie/$id?api_key=$apiKey';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        movies.add(json.decode(response.body));
      }
    }

    setState(() {
      _movies = movies;
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
        title: Text(widget.collectionName),
      ),
      body: _movies.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                mainAxisSpacing: 8.0,
                crossAxisSpacing: 8.0,
              ),
              itemCount: _movies.length,
              itemBuilder: (context, index) {
                final movie = _movies[index];
                final posterUrl =
                    'https://image.tmdb.org/t/p/w500${movie['poster_path']}';
                return GestureDetector(
                  onLongPress: () => _favoriteService.removeFavoriteMovie,
                  onTap: () => _showMovieDetailsPage(movie),
                  child: Card(
                    child: SingleChildScrollView(
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
                  ),
                );
              },
            ),
    );
  }
}
