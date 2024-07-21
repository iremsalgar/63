import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String username;
  final String profileName;
  final String profileImagePath;
  final int followingCount;
  final int followersCount;
  final double likesCount;

  UserModel({
    required this.username,
    required this.profileName,
    required this.profileImagePath,
    required this.followingCount,
    required this.followersCount,
    required this.likesCount,
  });

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    return UserModel(
      username: doc['username'],
      profileName: doc['profileName'],
      profileImagePath: doc['profileImagePath'],
      followingCount: doc['followingCount'],
      followersCount: doc['followersCount'],
      likesCount: doc['likesCount'],
    );
  }
}
