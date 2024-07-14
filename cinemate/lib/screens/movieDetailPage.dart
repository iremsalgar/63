import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MovieDetailPage extends StatefulWidget {
  final Map movie;

  const MovieDetailPage({required this.movie, super.key});

  @override
  _MovieDetailPageState createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  List _cast = [];

  @override
  void initState() {
    super.initState();
    _loadCast();
  }

  void _loadCast() async {
    final int movieId = widget.movie['id'];
    final String apiKey = 'f09947e5d5bbc3a4ba0a6e149efb63f9';
    final url =
        'https://api.themoviedb.org/3/movie/$movieId/credits?api_key=$apiKey';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _cast = data['cast'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final posterUrl =
        'https://image.tmdb.org/t/p/w500${widget.movie['poster_path']}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Movie Info'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.network(posterUrl, height: 300),
              ),
              const SizedBox(height: 16),
              Text(
                widget.movie['title'] ?? widget.movie['name'],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.movie['release_date']?.substring(0, 4) ?? ''} | ${widget.movie['genres']?.map((g) => g['name']).join(', ') ?? ''} | ${widget.movie['runtime']} mins',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text('${widget.movie['vote_average']}'),
                  const SizedBox(width: 4),
                  Text('(${widget.movie['vote_count']} reviews)'),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                widget.movie['overview'] ?? 'No description available.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                'Cast & Crew',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _cast.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _cast.length,
                        itemBuilder: (context, index) {
                          final member = _cast[index];
                          final profileUrl = member['profile_path'] != null
                              ? 'https://image.tmdb.org/t/p/w500${member['profile_path']}'
                              : 'https://via.placeholder.com/80';
                          return Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 8),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  backgroundImage: NetworkImage(profileUrl),
                                  radius: 30,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  member['name'],
                                  style: const TextStyle(fontSize: 12),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
