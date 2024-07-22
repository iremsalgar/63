import 'dart:convert';
import 'package:cinemate/screens/editProfile.dart';
import 'package:http/http.dart' as http;
import 'package:cinemate/screens/movieDetailPage.dart';
import 'package:cinemate/screens/settings.dart';
import 'package:cinemate/services/collections.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _profileName = "";
  String _username = "";
  String _email = "";
  int _followingCount = 0;
  int _followersCount = 0;
  double _likesCount = 0.0;
  final List<String> _collections = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadCollections();
    _updateFollowerFollowingCounts();
  }

  Future<void> _updateFollowerFollowingCounts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final userDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _followingCount = data['following_count'] ?? 0;
            _followersCount = data['followers_count'] ?? 0;
          });

          // Güncellenmiş takipçi sayısını Firebase'e kaydet
          final followingCount = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('following')
              .get()
              .then((snapshot) => snapshot.size);

          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'following_count': followingCount,
          });

          setState(() {
            _followingCount = followingCount;
          });
        }
      } catch (e) {
        print('Error updating counts: $e');
      }
    }
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final userDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _profileName = data['profileName'] ?? 'No Profile Name';
            _username = data['username'] ?? 'No Username';
            _email = data['email'] ?? 'No Email';
            _followingCount = data['following_count'] ?? 0;
            _followersCount = data['followers_count'] ?? 0;
            _likesCount = data['likes_count']?.toDouble() ?? 0.0;
          });
        }
      } catch (e) {
        print('Error loading profile: $e');
      }
    }
  }

  Future<void> _loadCollections() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final collectionDocs = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('collections')
            .get();

        setState(() {
          _collections.clear();
          _collections
              .addAll(collectionDocs.docs.map((doc) => doc.id).toList());
        });
      } catch (e) {
        print('Error loading collections: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfilePage(),
                ),
              ).then((_) => _loadProfile());
            },
          ),
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
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage('https://via.placeholder.com/150'),
            ),
            const SizedBox(height: 10),
            Text(
              _username,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              _email,
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
                      '$_likesCount',
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
                            return ListTile(
                              title: Text(collectionName),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CollectionPage(
                                      collectionName: collectionName,
                                    ),
                                  ),
                                );
                              },
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
  final FirestoreService _firestoreService =
      FirestoreService(); // FirestoreService'i kullanıyoruz

  @override
  void initState() {
    super.initState();
    _loadCollectionMovies();
  }

  Future<void> _loadCollectionMovies() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final movieIds = await _firestoreService.getCollectionMovies(
          uid, widget.collectionName);
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
  }

  Future<void> _removeMovieFromCollection(String movieId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('collections')
            .doc(widget.collectionName)
            .update({
          'movies': FieldValue.arrayRemove([movieId])
        });
        setState(() {
          _movies.removeWhere((movie) => movie['id'].toString() == movieId);
        });
      } catch (e) {
        print('Error removing movie from collection: $e');
      }
    }
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
                  onLongPress: () {
                    _removeMovieFromCollection(
                        movie['id'].toString()); // ID parametresini ekledim
                  },
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
