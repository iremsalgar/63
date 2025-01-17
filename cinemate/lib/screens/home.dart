import 'package:cinemate/screens/login_screen.dart';
import 'package:cinemate/screens/otherProfilePage.dart';
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
  String _username = "";
  List<String> _collections = [];
  List<String> favoriteMovieIds = [];
  List<Map<String, dynamic>> userMatches = [];
  final FavoriteService favoriteService = FavoriteService();
  final FirestoreService collectionsServices = FirestoreService();
  final String apiKey = 'f09947e5d5bbc3a4ba0a6e149efb63f9';

  Future<void> _loadName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _username = data['username'] ?? 'No Username';
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPopularMovies();
    _loadCollections();
    _loadFavorites();
    _loadUserMatches();
    _loadName();
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
            )
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

  Future<void> _loadUserMatches() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final allUserFavorites = await collectionsServices.getAllUserFavorites();
      final currentUserFavorites = favoriteMovieIds.toSet();
      final userProfiles = await collectionsServices.getAllUserProfiles();

      final matches = allUserFavorites.entries
          .where((entry) => entry.key != uid)
          .map((entry) {
        final commonFavorites =
            entry.value.toSet().intersection(currentUserFavorites).length;
        final userName = userProfiles[entry.key]?['username'] ?? 'Unknown';
        return {
          'userId': entry.key,
          'userName': userName,
          'commonCount': commonFavorites
        };
      }).toList();

      matches.sort((a, b) =>
          (b['commonCount'] as int).compareTo(a['commonCount'] as int));

      setState(() {
        userMatches = matches;
      });
    }
  }

  void _onProfileTap(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtherProfilePage(userId: userId),
      ),
    );
  }

  _buildUserMatchesTable() {
    List<Map<String, dynamic>> top5Matches =
        userMatches.length > 5 ? userMatches.sublist(0, 5) : userMatches;

    return top5Matches.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : DataTable(
            columnSpacing: 24,
            headingRowHeight: 60,
            headingRowColor:
                WidgetStateColor.resolveWith((states) => Colors.black87),
            dataRowHeight: 80,
            columns: const [
              DataColumn(
                label: Text(
                  'User Name',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.amber,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Common Favorites',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.amber,
                  ),
                ),
              ),
            ],
            rows: top5Matches.map((match) {
              return DataRow(
                cells: [
                  DataCell(
                    GestureDetector(
                      onTap: () => _onProfileTap(match['userId']),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.amber, width: 2),
                            ),
                            child: CircleAvatar(
                              backgroundImage: NetworkImage(
                                  'https://example.com/${match['userId']}.jpg'), // Kullanıcı profil resmini temsil eder
                              radius: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              match['userName'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.yellow, size: 24),
                        const SizedBox(width: 6),
                        Text(
                          match['commonCount'].toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                color: WidgetStateColor.resolveWith((states) {
                  return match['commonCount'] % 2 == 0
                      ? Colors.grey[800]!
                      : Colors.black54;
                }),
              );
            }).toList(),
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          style: const ButtonStyle(alignment: Alignment.center),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text("Do You Want To Exit Account?"),
                  content: Text(
                    "Are You Sure?",
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  actions: [
                    TextButton(
                      child: Text(
                        "No",
                        style: TextStyle(color: Colors.amber[700]),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      child: Text(
                        "Yes",
                        style: TextStyle(color: Colors.amber[700]),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const LoginScreen()));
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
        title: Text(
          'Home',
          style:
              TextStyle(color: Colors.amber[700], fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Text(
              "Welcome $_username",
              style: TextStyle(
                  fontSize: 20,
                  color: Colors.amber[700],
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
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
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.amber[700],
                                        fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                IconButton(
                                    icon: isFavorite
                                        ? Icon(Icons.star,
                                            color: Colors.amber[700])
                                        : const Icon(
                                            Icons.star_border,
                                          ),
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
            const SizedBox(height: 10),
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
            const SizedBox(height: 10),
            _buildUserMatchesTable(),
          ],
        ),
      ),
    );
  }
}
