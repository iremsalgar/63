import 'package:cinemate/widgets/navi_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseAuthService {
  final userCollection = FirebaseFirestore.instance.collection("users");
  final firebaseAuth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  /// Kullanıcı kaydı yapar ve Firestore'a ekler.
  Future<bool> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final UserCredential userCredential = await firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      if (userCredential.user != null) {
        final userId = userCredential.user!.uid;
        await userCollection.doc(userId).set({
          "email": email,
          "username": username,
        });
        Fluttertoast.showToast(msg: "Successfully registered");
        return true; // Kaydın başarılı olduğunu belirtiyoruz.
      } else {
        Fluttertoast.showToast(msg: "Failed to register");
        return false; // Kaydın başarısız olduğunu belirtiyoruz.
      }
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(msg: e.message!, toastLength: Toast.LENGTH_LONG);
      return false; // Hata durumunda da başarısızlık döndürüyoruz.
    }
  }

  Future<bool> isUsernameAlreadyRegistered(String username) async {
    try {
      final querySnapshot = await firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking username: $e');
      return false;
    }
  }

  Future<bool> isEmailAlreadyRegistered(String email) async {
    try {
      final user = await firebaseAuth.fetchSignInMethodsForEmail(email);
      return user.isNotEmpty;
    } catch (e) {
      print('Error checking email: $e');
      return false;
    }
  }

  /// Kullanıcı oturumu açar.
  Future<void> signIn(
    BuildContext context, {
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      if (userCredential.user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', email);
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => const NaviBar()));
      }
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(msg: e.message!, toastLength: Toast.LENGTH_LONG);
    }
  }

  /// Kullanıcının kullanıcı adını döndürür.
  Future<String> getUsername(String uid) async {
    final docSnapshot = await userCollection.doc(uid).get();
    if (docSnapshot.exists) {
      final data = docSnapshot.data() as Map<String, dynamic>;
      return data['username'] ?? '';
    } else {
      return '';
    }
  }
}
