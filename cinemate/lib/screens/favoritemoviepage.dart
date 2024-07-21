import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'movieDetailPage.dart';

class FavoriteMoviesPage extends StatefulWidget {
  final String userId;

  const FavoriteMoviesPage({required this.userId, super.key});

  @override
  _FavoriteMoviesPageState createState() => _FavoriteMoviesPageState();
}

class _FavoriteMoviesPageState extends State<FavoriteMoviesPage> {
  final String apiKey = 'f09947e5d5bbc3a4ba0a6e149efb63f9';
  List _favoriteMovies = [];

  @override
  void initState() {
    super.initState();
    _loadFavoriteMovies();
  }

  Future<void> _loadFavoriteMovies() async {
    try {
      final favDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('favorites')
          .get();

      final List movieIds = favDocs.docs.map((doc) => doc.id).toList();
      final List movies = [];

      for (final id in movieIds) {
        final url = 'https://api.themoviedb.org/3/movie/$id?api_key=$apiKey';
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final movie = json.decode(response.body);
          movies.add(movie);
        } else {
          print('Failed to load movie with id $id');
        }
      }

      setState(() {
        _favoriteMovies = movies;
      });
    } catch (e) {
      print('Error loading favorite movies: $e');
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
        title: const Text('Favorite Movies'),
      ),
      body: _favoriteMovies.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                mainAxisSpacing: 8.0,
                crossAxisSpacing: 8.0,
              ),
              itemCount: _favoriteMovies.length,
              itemBuilder: (context, index) {
                final movie = _favoriteMovies[index];
                final posterUrl =
                    'https://image.tmdb.org/t/p/w500${movie['poster_path']}';
                return GestureDetector(
                  onTap: () => _showMovieDetailsPage(movie),
                  child: Card(
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
                );
              },
            ),
    );
  }
}
