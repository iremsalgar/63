import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final String apiKey = 'YOUR_TMDB_API_KEY';
  List _favoriteMovies = [];
  String _profileName = 'irem salgar';
  String _username = '@salgar_irem';
  String _profileImageUrl = 'https://via.placeholder.com/150';
  int _followingCount = 29;
  int _followersCount = 5;
  double _likesCount = 7.5;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadFavorites();
  }

  void _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profileName = prefs.getString('profileName') ?? 'irem salgar';
      _username = prefs.getString('username') ?? '@salgar_irem';
      _profileImageUrl = prefs.getString('profileImageUrl') ??
          'https://via.placeholder.com/150';
      _followingCount = prefs.getInt('followingCount') ?? 29;
      _followersCount = prefs.getInt('followersCount') ?? 5;
      _likesCount = prefs.getDouble('likesCount') ?? 7.5;
    });
  }

  void _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteMovieIds = prefs.getStringList('favoriteMovies') ?? [];
    final favoriteMovies = [];

    for (final id in favoriteMovieIds) {
      final url = 'https://api.themoviedb.org/3/movie/$id?api_key=$apiKey';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        favoriteMovies.add(json.decode(response.body));
      }
    }

    setState(() {
      _favoriteMovies = favoriteMovies;
    });
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
              backgroundImage: NetworkImage(_profileImageUrl),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Follow'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Icon(Icons.message),
                ),
              ],
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Favorite Films',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _favoriteMovies.isEmpty
                      ? const Text('No favorite films yet.')
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _favoriteMovies.length,
                          itemBuilder: (context, index) {
                            final movie = _favoriteMovies[index];
                            return ListTile(
                              title: Text(movie['title']),
                              subtitle:
                                  Text(movie['overview'] ?? 'No description'),
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
