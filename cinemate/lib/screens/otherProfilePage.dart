import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:cinemate/screens/favoritemoviepage.dart';
import 'package:cinemate/screens/movieDetailPage.dart';
import 'package:cinemate/widgets/outlined_button.dart';
import 'editProfile.dart';
import 'messagePage.dart';
import 'settings.dart';
import 'package:cinemate/screens/favoritemoviepage.dart'; // Import the new page

class OtherProfilePage extends StatefulWidget {
  final String userId;

  const OtherProfilePage({
    required this.userId,
    super.key,
  });

  @override
  _OtherProfilePageState createState() => _OtherProfilePageState();
}

class _OtherProfilePageState extends State<OtherProfilePage> {
  String _profileName = "";
  String _username = "";
  String _email = "";
  File? _profileImageFile;
  bool _isFollowing = false;
  int _followingCount = 0;
  int _followersCount = 0;
  double _likesCount = 0.0;
  final List<String> _collections = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadCollections();
    _checkIfFollowing();
  }

  Future<void> _loadProfile() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

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
      } else {
        print('User document not found');
      }
    } catch (e) {
      print('Error loading profile: $e');
    }
  }

  Future<void> _loadCollections() async {
    try {
      final collectionDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('collections')
          .get();

      setState(() {
        _collections.clear();
        _collections.addAll(collectionDocs.docs.map((doc) => doc.id).toList());
      });
    } catch (e) {
      print('Error loading collections: $e');
    }
  }

  Future<void> _checkIfFollowing() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('following')
          .doc(widget.userId)
          .get();

      setState(() {
        _isFollowing = userDoc.exists;
      });
    }
  }

  Future<void> _toggleFollow() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        if (_isFollowing) {
          // Takibi bırak
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('following')
              .doc(widget.userId)
              .delete();
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .update({
            'followers_count': FieldValue.increment(-1),
          });
          setState(() {
            _followersCount--;
            _isFollowing = false;
          });
        } else {
          // Takip et
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('following')
              .doc(widget.userId)
              .set({});
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .update({
            'followers_count': FieldValue.increment(1),
          });
          setState(() {
            _followersCount++;
            _isFollowing = true;
          });
        }
      } catch (e) {
        print('Error updating follow status: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomOutlinedButton(
                  onPressed: _toggleFollow,
                  icons: _isFollowing
                      ? Icons.check_box
                      : Icons.app_registration_rounded,
                  text: _isFollowing ? "Following" : "Follow",
                  background: _isFollowing ? Colors.green : Colors.amber,
                ),
                const SizedBox(width: 50),
                CustomOutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => MessagePage(
                          recipientId: widget.userId,
                        ),
                      ),
                    );
                  },
                  icons: Icons.send,
                  text: "Message",
                  background: Colors.amber,
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
                                      userId: widget.userId,
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
  final String userId; // Kullanıcı ID'sini geçiyoruz

  const CollectionPage(
      {required this.collectionName, required this.userId, super.key});

  @override
  _CollectionPageState createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  final String apiKey = 'f09947e5d5bbc3a4ba0a6e149efb63f9';
  List _movies = [];

  @override
  void initState() {
    super.initState();
    _loadCollectionMovies();
  }

  Future<void> _loadCollectionMovies() async {
    final collectionDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('collections')
        .doc(widget.collectionName)
        .collection('movies')
        .get();

    final List movieIds = collectionDoc.docs.map((doc) => doc.id).toList();
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
                  onLongPress: () {
                    // Movie uzun basıldığında favoriden çıkarma işlemi yapabilirsiniz.
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
