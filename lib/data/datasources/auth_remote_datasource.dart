import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  final ApiClient _apiClient = ApiClient();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Sync profile details to Go MySQL backend
  Future<UserModel> syncProfileToBackend({required String role, String? name, String? phone}) async {
    final User? firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      throw Exception('No active Firebase user found');
    }

    final body = {
      'role': role,
      'nama': name ?? firebaseUser.displayName ?? '',
      'foto_url': firebaseUser.photoURL ?? '',
      'telepon': phone ?? firebaseUser.phoneNumber ?? '',
      'latitude': 0.0,
      'longitude': 0.0,
    };

    final response = await _apiClient.post('/user/profile', body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      return UserModel.fromJson(decoded['data']);
    } else {
      throw Exception('Failed to sync profile with backend: ${response.body}');
    }
  }

  // Retrieve profile details from Go MySQL backend
  Future<UserModel> getProfileFromBackend() async {
    final response = await _apiClient.get('/user/profile');
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return UserModel.fromJson(decoded['data']);
    } else {
      throw Exception('Failed to retrieve profile from backend: ${response.body}');
    }
  }
}
