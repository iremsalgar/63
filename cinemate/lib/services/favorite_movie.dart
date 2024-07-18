import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addFavoriteMovie(String movieId) async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentReference userDoc = _firestore.collection('users').doc(user.uid);
      CollectionReference favorites = userDoc.collection('favorites');

      // Film zaten favorilerde mi kontrol et
      DocumentSnapshot snapshot = await favorites.doc(movieId).get();
      if (!snapshot.exists) {
        await favorites.doc(movieId).set({'added_at': Timestamp.now()});
      }
    }
  }

  Future<void> removeFavoriteMovie(String movieId) async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentReference userDoc = _firestore.collection('users').doc(user.uid);
      CollectionReference favorites = userDoc.collection('favorites');

      await favorites.doc(movieId).delete();
    }
  }

  Stream<QuerySnapshot> getFavoriteMovies() {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentReference userDoc = _firestore.collection('users').doc(user.uid);
      CollectionReference favorites = userDoc.collection('favorites');

      return favorites.snapshots();
    } else {
      // Kullanıcı oturum açmamışsa boş bir stream döndür
      return const Stream.empty();
    }
  }
}
