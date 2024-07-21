import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addCollection(String uid, String collectionName) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('collections')
          .doc(collectionName)
          .set({
        'name': collectionName,
      });
    } catch (e) {
      print('Error adding collection: $e');
    }
  }

  Future<List<String>> getCollections(String uid) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('collections')
          .get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('Error fetching collections: $e');
      return [];
    }
  }

  Future<void> removeCollection(String uid, String collectionName) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('collections')
          .doc(collectionName)
          .delete();

      final moviesSnapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('collections')
          .doc(collectionName)
          .collection('movies')
          .get();
      for (var doc in moviesSnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error removing collection: $e');
    }
  }

  Future<void> addMovieToCollection(
      String uid, String collectionName, String movieId) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('collections')
          .doc(collectionName)
          .collection('movies')
          .doc(movieId)
          .set({
        'id': movieId,
      });
    } catch (e) {
      print('Error adding movie to collection: $e');
    }
  }

  Future<List<String>> getCollectionMovies(
      String uid, String collectionName) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('collections')
          .doc(collectionName)
          .collection('movies')
          .get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('Error fetching collection movies: $e');
      return [];
    }
  }

  // Yeni metot: getAllUserProfiles
  Future<Map<String, dynamic>> getAllUserProfiles() async {
    try {
      final snapshot = await _db.collection('users').get();
      final profiles = <String, dynamic>{};
      for (var doc in snapshot.docs) {
        profiles[doc.id] = doc.data();
      }
      return profiles;
    } catch (e) {
      print('Error fetching user profiles: $e');
      return {};
    }
  }

  // getAllUserFavorites metodunu buraya eklemeyi unutmayın
  Future<Map<String, List<String>>> getAllUserFavorites() async {
    try {
      final snapshot = await _db.collection('users').get();
      final allUserFavorites = <String, List<String>>{};
      for (var doc in snapshot.docs) {
        final favoritesSnapshot =
            await doc.reference.collection('favorites').get();
        final favoriteIds =
            favoritesSnapshot.docs.map((doc) => doc.id).toList();
        allUserFavorites[doc.id] = favoriteIds;
      }
      return allUserFavorites;
    } catch (e) {
      print('Error fetching all user favorites: $e');
      return {};
    }
  }
}
