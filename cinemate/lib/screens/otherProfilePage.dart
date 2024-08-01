import 'dart:convert';
import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cinemate/screens/messagePage.dart';
import 'package:cinemate/screens/movieDetailPage.dart';
import 'package:cinemate/widgets/outlined_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class OtherProfilePage extends StatefulWidget {
  final String userId;

  const OtherProfilePage({super.key, required this.userId});

  @override
  _OtherProfilePageState createState() => _OtherProfilePageState();
}

class _OtherProfilePageState extends State<OtherProfilePage> {
  bool _isFollowing = false;
  late int _followingCount;
  late int _followersCount;
  late double _likesCount;
  late String _profileName;
  late String _username;
  late String _email;
  File? _profileImageFile;
  List<String> _collections = [];
  List _favoriteMovies = [];
  List favoriteMovies = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  double _commonFavoritesPercentage = 0.0;
  late final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  AwesomeNotifications awesomeNotifications = AwesomeNotifications();
  List _originalFavoriteMovies = [];
  final String apiKey = 'f09947e5d5bbc3a4ba0a6e149efb63f9';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkIfFollowing();
    _fetchUserProfile();
    _loadProfile();
    _fetchCollections();
    _fetchFavoriteMovies();
    _loadFavoritesAndCollections();
  }

  void _loadFavoritesAndCollections() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteMovieIds = prefs.getStringList('favoriteMovies') ?? [];
    final allCollections = prefs.getStringList('collections') ?? [];

    for (final collectionName in allCollections) {
      final collectionKey = 'collection_$collectionName';
      final collectionMovieIds = prefs.getStringList(collectionKey) ?? [];
      favoriteMovieIds.addAll(collectionMovieIds);
    }

    for (final id in favoriteMovieIds) {
      final url = 'https://api.themoviedb.org/3/movie/$id?api_key=$apiKey';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        favoriteMovies.add(json.decode(response.body));
      } else {
        print('Error fetching movie: ${response.statusCode}');
      }
    }

    setState(() {
      _favoriteMovies = favoriteMovies;
      _originalFavoriteMovies = List.from(favoriteMovies);
      _isLoading = false;
    });
  }

  Future<void> _calculateCommonFavoritesPercentage() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final currentUserFavoritesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('favorites')
          .get();
      final otherUserFavoritesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('favorites')
          .get();

      final currentUserFavorites =
          currentUserFavoritesSnapshot.docs.map((doc) => doc.id).toSet();
      final otherUserFavorites =
          otherUserFavoritesSnapshot.docs.map((doc) => doc.id).toSet();

      final commonFavorites =
          currentUserFavorites.intersection(otherUserFavorites).length;
      final totalFavorites =
          currentUserFavorites.union(otherUserFavorites).length;

      if (totalFavorites > 0) {
        setState(() {
          _commonFavoritesPercentage = (commonFavorites / totalFavorites) * 100;
        });
      }
    }
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

        // Calculate common favorites percentage
        await _calculateCommonFavoritesPercentage();
      } else {
        print('User document not found');
      }
    } catch (e) {
      print('Error loading profile: $e');
    }
  }

  Future<void> _checkIfFollowing() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('following')
          .doc(widget.userId)
          .get();
      setState(() {
        _isFollowing = doc.exists;
      });
    }
  }

  followNotification() {
    AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: 10,
            channelKey: "basic_channel",
            title: "Cinemate",
            body: "$_username adlı kullanıcıyı takip ediyorsun."));
  }

  unfollowNotification() {
    AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: 11,
            channelKey: "basic_channel",
            title: "Cinemate",
            body: "$_username adlı kullanıcıyı artık takip etmiyorsun."));
  }

  Future<void> _fetchUserProfile() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
    final data = doc.data()!;
    setState(() {
      _profileName = data['profileName'] ?? 'Profil İsmi Yok';
      _username = data['username'] ?? 'Kullanıcı Adı Yok';
      _email = data['email'] ?? 'Email Yok';
      _followingCount = data['following_count'] ?? 0;
      _followersCount = data['followers_count'] ?? 0;
      _likesCount = data['likes_count']?.toDouble() ?? 0.0;
    });
  }

  Future<void> _fetchCollections() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('collections')
        .get();
    setState(() {
      _collections = querySnapshot.docs.map((doc) => doc.id).toList();
    });
  }

  Future<void> _fetchFavoriteMovies() async {
    try {
      // Fetch the favorite movies for the user whose profile is being viewed
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('favorites')
          .get();

      // Get the list of movie IDs from the Firestore query
      final movieIds = querySnapshot.docs.map((doc) => doc.id).toList();

      // Fetch the details of each favorite movie using the movie IDs
      final favoriteMovies = await Future.wait(
        movieIds.map((movieId) async {
          final url =
              'https://api.themoviedb.org/3/movie/$movieId?api_key=$apiKey';
          final response = await http.get(Uri.parse(url));
          if (response.statusCode == 200) {
            return json.decode(response.body);
          } else {
            print('Error fetching movie: ${response.statusCode}');
            return null; // Return null if there's an error
          }
        }),
      );

      // Filter out any null results (in case of errors fetching movies)
      setState(() {
        _favoriteMovies = favoriteMovies.whereType<Map>().toList();
        _originalFavoriteMovies = List.from(_favoriteMovies);
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching favorite movies: $e');
    }
  }

  Future<void> toggleFollow() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        if (_isFollowing) {
          // Unfollow
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
          // Follow
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
            followNotification();
            _followersCount++;
            _isFollowing = true;
          });
        }
      } catch (e) {
        print('Takip işlemi sırasında hata oluştu: $e');
      }
    }
  }

  Future<void> _toggleFollow() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        if (_isFollowing) {
          // Unfollow
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
          // Follow
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
            followNotification();
            _followersCount++;
            _isFollowing = true;
          });
        }
      } catch (e) {
        print('Takip işlemi sırasında hata oluştu: $e');
      }
    }
  }

  void showMovieDetailsPage(Map movie) {
    const baseUrl = 'https://image.tmdb.org/t/p/w500';
    final posterUrl = '$baseUrl${movie['poster_path']}';

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
  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style:
              TextStyle(color: Colors.amber[700], fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Profil fotoğrafı, ad ve diğer bilgileri buraya ekleyin

            CircleAvatar(
              radius: 50,
              backgroundImage: _profileImageFile != null
                  ? FileImage(_profileImageFile!)
                  : const AssetImage("assets/image/RemovePopcorn.png")
                      as ImageProvider,
            ),
            const SizedBox(height: 10),
            // Kullanıcı bilgilerini gösterin
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return const Text('Hata oluştu');
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                _profileName = data['profileName'] ?? 'Profil İsmi Yok';
                _username = data['username'] ?? 'Kullanıcı Adı Yok';
                _email = data['email'] ?? 'Email Yok';
                _followingCount = data['following_count'] ?? 0;
                _followersCount = data['followers_count'] ?? 0;
                _likesCount = data['likes_count']?.toDouble() ?? 0.0;

                return Column(
                  children: [
                    Text(
                      _username,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
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
                            const Text('Following',
                                style: TextStyle(color: Colors.grey)),
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
                            const Text('Followers',
                                style: TextStyle(color: Colors.grey)),
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
                            const Text('Likes',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ],
                );
              },
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
                  icons: Icons.message,
                  text: "Message",
                  background: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Common Favorites: ${_commonFavoritesPercentage.toStringAsFixed(2)}%',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Favori filmleri göster
            const Text(
              'Favorite Movies',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    height: 200,
                    child: _favoriteMovies.isEmpty
                        ? const Center(child: Text('No favorite movies yet.'))
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _favoriteMovies.length,
                            itemBuilder: (context, index) {
                              final movie = _favoriteMovies[index];
                              final posterPath = movie['poster_path'];
                              final posterUrl = posterPath != null &&
                                      posterPath.isNotEmpty
                                  ? 'https://image.tmdb.org/t/p/w500$posterPath'
                                  : null;

                              return GestureDetector(
                                onTap: () => showMovieDetailsPage(movie),
                                child: Card(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      posterUrl != null
                                          ? Image.network(
                                              posterUrl,
                                              width: 100,
                                              height: 150,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return const Center(
                                                    child: Text(
                                                        'Image Not Found'));
                                              },
                                            )
                                          : const Center(
                                              child: Text('Image Not Found')),
                                      const SizedBox(height: 5),
                                      Text(
                                        movie['title'],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
            const SizedBox(height: 20),
            // Koleksiyonları göster
            const Text(
              'Collections',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _collections.isEmpty
                ? const Text('No collections yet.')
                : Column(
                    children: _collections
                        .map((collection) => ListTile(
                              title: Text(collection),
                              onTap: () {
                                // Koleksiyon tıklama işlemi
                              },
                            ))
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }
}
