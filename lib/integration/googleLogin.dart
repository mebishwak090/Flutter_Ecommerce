import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '/loginPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
    signInOption: SignInOption.standard,
  );

  Future<UserCredential?> signInWithGoogle() async {
    try {
      GoogleSignInAccount? googleUser = _googleSignIn.currentUser;

      googleUser ??= await _googleSignIn.signIn();

      if (googleUser == null) {
        log("Google sign-in was cancelled by the user.");
        return null;
      }

      log("Google User Selected:");
      log("Email: ${googleUser.email}");
      log("Display Name: ${googleUser.displayName}");
      log("ID: ${googleUser.id}");

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      final user = userCredential.user;
      if (user != null) {
        log("Firebase User Info:");
        log("UID: ${user.uid}");
        log("Email: ${user.email}");
        log("Name: ${user.displayName}");
        log("Photo URL: ${user.photoURL}");
      }

      return userCredential;
    } catch (e, stacktrace) {
      print("Google Sign-In Error: $e");
      print("StackTrace: $stacktrace");
      return null;
    }
  }

  Future<void> registerUser(String email, String password, BuildContext context) async {
    try {

      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
        });

        print("User registered and added to Firestore");

        Fluttertoast.showToast(
            msg: "User Created Please login",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 20.0
        );
        Future.delayed(const Duration(seconds: 3), (){
          Navigator.pop(context);
        });
      }
    } catch (e, stacktrace) {
      print("Registration Error: $e");
      Fluttertoast.showToast(
        msg: e.toString(),
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 20.0
      );
      print("StackTrace: $stacktrace");
    }
  }

  Future<User?> loginUser(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      print("Login successful: ${user?.email}");
      return user;
    } catch (e, stacktrace) {
      print("Login Error: $e");
      print("StackTrace: $stacktrace");
      return null;
    }
  }
  Future<void> signOut(BuildContext context) async {
    try {

      await _auth.signOut();
      await _googleSignIn.signOut();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>LoginPage()));
      log(" User signed out successfully.");
    } catch (e, stacktrace) {
      log(" Sign-Out Error: $e");
      log("StackTrace: $stacktrace");
    }
  }


}