import 'dart:convert';
import 'package:cinemate/screens/editProfile.dart';
import 'package:cinemate/screens/movieDetailPage.dart';
import 'package:cinemate/screens/settings.dart';
import 'package:cinemate/services/collections.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

// ProfilePage
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

  Future<void> _createFollowersCollectionIfNotExists(String uid) async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);

    // Check if followers collection exists
    final followersSnapshot = await userDoc.collection('followers').get();

    if (followersSnapshot.docs.isEmpty) {
      // Add a dummy document to create the collection
      await userDoc.collection('followers').doc('dummy').set({
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _updateFollowerFollowingCounts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final userDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (userDoc.exists) {
          await _createFollowersCollectionIfNotExists(uid);

          final followersSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('followers')
              .get();
          final followingSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('following')
              .get();

          final followersCount = followersSnapshot.size;
          final followingCount = followingSnapshot.size;

          setState(() {
            _followersCount = followersCount;
            _followingCount = followingCount;
          });

          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'followers_count': followersCount,
            'following_count': followingCount,
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

  Future<void> _showFollowers() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final followersSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('followers')
            .get();

        final followers = followersSnapshot.docs.map((doc) => doc.id).toList();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserListPage(
              title: 'Followers',
              userIds: followers,
            ),
          ),
        );
      } catch (e) {
        print('Error fetching followers: $e');
      }
    }
  }

  Future<void> _showFollowing() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final followingSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('following')
            .get();

        final following = followingSnapshot.docs.map((doc) => doc.id).toList();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserListPage(
              title: 'Following',
              userIds: following,
            ),
          ),
        );
      } catch (e) {
        print('Error fetching following: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style:
              TextStyle(color: Colors.amber[700], fontWeight: FontWeight.bold),
        ),
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
                TextButton(
                  onPressed: _showFollowing,
                  child: Column(
                    children: [
                      Text(
                        '$_followingCount',
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Following',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                TextButton(
                  onPressed: _showFollowers,
                  child: Column(
                    children: [
                      Text(
                        '$_followersCount',
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Followers',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  children: [
                    Text(
                      '$_likesCount',
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
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

// UserListPage
class UserListPage extends StatelessWidget {
  final String title;
  final List<String> userIds;

  const UserListPage({required this.title, required this.userIds, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: userIds.length,
        itemBuilder: (context, index) {
          final userId = userIds[index];
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ListTile(title: Text('Loading...'));
              } else if (snapshot.hasError) {
                return const ListTile(title: Text('Error loading user'));
              } else if (snapshot.hasData) {
                final userData = snapshot.data?.data() as Map<String, dynamic>?;
                final userName = userData?['username'] ?? 'Unknown';
                final email = userData?['email'] ?? 'Unknown';
                return ListTile(
                  title: Text(userName),
                  subtitle: Text(email),
                );
              } else {
                return const ListTile(title: Text('User not found'));
              }
            },
          );
        },
      ),
    );
  }
}

// CollectionPage
class CollectionPage extends StatefulWidget {
  final String collectionName;

  const CollectionPage({required this.collectionName, super.key});

  @override
  _CollectionPageState createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  final String apiKey = 'f09947e5d5bbc3a4ba0a6e149efb63f9';
  List _movies = [];
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadCollectionMovies();
  }

  Future<void> _loadCollectionMovies() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final movieIds = await _firestoreService.getCollectionMovies(
            uid, widget.collectionName);
        final movies = await _fetchMoviesDetails(movieIds);
        setState(() {
          _movies = movies;
        });
      } catch (e) {
        print('Error loading collection movies: $e');
      }
    }
  }

  Future<List> _fetchMoviesDetails(List<String> movieIds) async {
    final List movies = [];
    for (String movieId in movieIds) {
      final response = await http.get(Uri.parse(
          'https://api.themoviedb.org/3/movie/$movieId?api_key=$apiKey'));
      if (response.statusCode == 200) {
        final movieData = json.decode(response.body);
        movies.add(movieData);
      } else {
        print('Failed to load movie details');
      }
    }
    return movies;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.collectionName),
      ),
      body: ListView.builder(
        itemCount: _movies.length,
        itemBuilder: (context, index) {
          final movie = _movies[index];
          return ListTile(
            leading: Image.network(
              'https://image.tmdb.org/t/p/w500${movie['poster_path']}',
              fit: BoxFit.cover,
              width: 50,
            ),
            title: Text(movie['title']),
            subtitle: Text(movie['release_date']),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MovieDetailPage(
                    movie: movie,
                    isTVShow: movie['isTVShow'] ?? false,
                    posterUrl: movie['poster_path'],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
