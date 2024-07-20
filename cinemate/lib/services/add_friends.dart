import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class User {
  String id;
  String name;

  User({required this.id, required this.name});

  factory User.fromDocument(DocumentSnapshot doc) {
    return User(
      id: doc.id,
      name: doc['name'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
    };
  }
}

void addFriend(String userId, User friend) async {
  await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('friends')
      .doc(friend.id)
      .set(friend.toMap());
}

Stream<List<User>> getFriends(String userId) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('friends')
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => User.fromDocument(doc)).toList());
}
