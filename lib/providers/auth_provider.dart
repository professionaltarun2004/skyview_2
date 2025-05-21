import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  bool _isLoading = false;

  AuthProvider() {
    _initAuth();
  }

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;

  Future<void> _initAuth() async {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<Map<String, dynamic>> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Sign in with Firebase
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _user = userCredential.user;
      
      // Store auth token
      final prefs = await SharedPreferences.getInstance();
      final token = await _user?.getIdToken();
      if (token != null) {
        await prefs.setString('userToken', token);
      }
      
      _isLoading = false;
      notifyListeners();
      return {'success': true};
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'code': e.code,
        'message': _getErrorMessage(e.code),
      };
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  Future<Map<String, dynamic>> signUp(String name, String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Create user with Firebase
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _user = userCredential.user;
      
      // Update user display name
      await _user?.updateDisplayName(name);
      
      // Create user document in Firestore
      await _firestore.collection('users').doc(_user?.uid).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'preferences': {
          'notifications': true,
          'darkMode': false,
        },
      });
      
      // Store auth token
      final prefs = await SharedPreferences.getInstance();
      final token = await _user?.getIdToken();
      if (token != null) {
        await prefs.setString('userToken', token);
      }
      
      _isLoading = false;
      notifyListeners();
      return {'success': true};
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'code': e.code,
        'message': _getErrorMessage(e.code),
      };
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userToken');
      _user = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _auth.sendPasswordResetEmail(email: email);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password is too weak. Please use a stronger password.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
} 