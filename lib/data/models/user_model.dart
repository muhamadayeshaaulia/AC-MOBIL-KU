class UserModel {
  final String uid;
  final String email;
  final String nama;
  final String role; // "pelanggan" or "pengelola_bengkel"
  final double latitude;
  final double longitude;
  final String telepon;
  final String fotoUrl;
  final String createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.nama,
    required this.role,
    required this.latitude,
    required this.longitude,
    required this.telepon,
    required this.fotoUrl,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      nama: json['nama'] ?? '',
      role: json['role'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      telepon: json['telepon'] ?? '',
      fotoUrl: json['foto_url'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'nama': nama,
      'role': role,
      'latitude': latitude,
      'longitude': longitude,
      'telepon': telepon,
      'foto_url': fotoUrl,
      'created_at': createdAt,
    };
  }
}
