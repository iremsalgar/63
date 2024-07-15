import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'editProfile.dart';
import 'messagePage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  List<String> _collections = [];
  String _profileName = 'irem salgar';
  String _username = '@salgar_irem';
  File? _profileImageFile;
  int _followingCount = 29;
  int _followersCount = 5;
  double _likesCount = 7.5;
  bool _isFriend = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadCollections();
    _checkFriendStatus();
  }

  void _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profileName = prefs.getString('profileName') ?? 'irem salgar';
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

  void _loadCollections() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _collections = prefs.getStringList('collections') ?? [];
    });
  }

  void _checkFriendStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isFriend = prefs.getBool('isFriend') ?? false;
    });
  }

  void _toggleFriendStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isFriend = !_isFriend;
      prefs.setBool('isFriend', _isFriend);
    });
  }

  void _sendMessage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MessagePage(),
      ),
    );
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
            ElevatedButton(
              onPressed: _toggleFriendStatus,
              child: Text(_isFriend ? 'Arkadaşlıktan Çıkar' : 'Arkadaş Ekle'),
            ),
            ElevatedButton(
              onPressed: _sendMessage,
              child: const Text('Mesaj Gönder'),
            ),
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
                                        collectionName: collectionName),
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
            ),
          );
        },
      ),
    );
  }
}
