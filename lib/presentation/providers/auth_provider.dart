import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthRemoteDataSource _authRemoteDataSource = AuthRemoteDataSource();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Sign up using Email & Password + Save in MySQL backend
  Future<bool> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String role,
    required String phone,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(name);
        _currentUser = await _authRemoteDataSource.syncProfileToBackend(
          role: role,
          name: name,
          phone: phone,
        );
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign in using Email & Password + Get from MySQL backend
  Future<bool> loginWithEmail(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        _currentUser = await _authRemoteDataSource.getProfileFromBackend();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Checks if the google authenticated user has a profile in the backend
  Future<bool?> checkGoogleUserExisting(GoogleSignInAccount googleUser, GoogleSignInAuthentication googleAuth) async {
    _setLoading(true);
    _setError(null);
    try {
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        try {
          // Attempt to retrieve profile from backend
          _currentUser = await _authRemoteDataSource.getProfileFromBackend();
          notifyListeners();
          return true; // Profile exists! Direct to dashboard
        } catch (e) {
          // Profile not found on backend (first time sign in)
          return false; // Show role selection
        }
      }
      return null;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Register Google user profile on backend
  Future<bool> registerGoogleUser({required String role, required String phone, String? name}) async {
    _setLoading(true);
    _setError(null);
    try {
      if (_auth.currentUser != null) {
        _currentUser = await _authRemoteDataSource.syncProfileToBackend(
          role: role,
          name: name,
          phone: phone,
        );
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateUserPhoto(String url) async {
    _setLoading(true);
    _setError(null);
    try {
      if (_currentUser != null) {
        _currentUser = await _authRemoteDataSource.syncProfileToBackend(
          role: _currentUser!.role,
          name: _currentUser!.nama,
          phone: _currentUser!.telepon,
          photoUrl: url,
        );
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Real Google Sign-In implementation (legacy fallback)
  Future<bool> loginWithGoogle(String role) async {
    _setLoading(true);
    _setError(null);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        _setError("Google Sign In dibatalkan oleh pengguna");
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        _currentUser = await _authRemoteDataSource.syncProfileToBackend(
          role: role,
          name: googleUser.displayName,
        );
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }
}
