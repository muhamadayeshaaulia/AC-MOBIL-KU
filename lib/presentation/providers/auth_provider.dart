import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  // Google Sign-In placeholder (requires google_sign_in package dependency)
  Future<bool> loginWithGoogle(String role) async {
    _setLoading(true);
    _setError(null);
    try {
      // For testing, since google_sign_in package requires setup, we can use dev bypass or direct firebase call
      // In production, this would trigger GoogleSignIn().signIn()
      // Let's fallback to current Firebase user if already authenticated, or trigger sync
      if (_auth.currentUser != null) {
        _currentUser = await _authRemoteDataSource.syncProfileToBackend(role: role);
        notifyListeners();
        return true;
      }
      _setError("Google Sign In requires physical device configuration");
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
