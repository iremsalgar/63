import 'package:cinemate/screens/login_screen.dart';
import 'package:cinemate/widgets/navi_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class FirebaseAuthService {
  final userCollection = FirebaseFirestore.instance.collection("users");
  final firebaseAuth = FirebaseAuth.instance;

  Future<void> signUp({
    required String name,
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
          "name": name,
          "password": password,
          "username": username,
        });
        registerUser(
            name: name, email: email, password: password, username: username);
        Fluttertoast.showToast(msg: "succesfully");
      }
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(msg: e.message!, toastLength: Toast.LENGTH_LONG);
    }
  }

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

  Future<String> getUsername(String uid) async {
    final docSnapshot = await userCollection.doc(uid).get();
    if (docSnapshot.exists) {
      final data = docSnapshot.data() as Map<String, dynamic>;
      return data['username'] ?? '';
    } else {
      return '';
    }
  }

  Future<void> registerUser(
      {required String name,
      required String username,
      required String email,
      required String password}) async {
    await userCollection.doc().set({
      "email": email,
      "name": name,
      "password": password,
      "username": username
    });
  }
}
