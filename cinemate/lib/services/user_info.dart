import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcı verilerini güncelleme
  Future<void> updateUserStats(String userId, int followingCount,
      int followersCount, double likesCount) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'following_count': followingCount,
        'followers_count': followersCount,
        'likes_count': likesCount,
      }, SetOptions(merge: true));
      print('User stats updated successfully.');
    } catch (e) {
      print('Failed to update user stats: $e');
    }
  }
}
