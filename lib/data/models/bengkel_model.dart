class BengkelModel {
  final int id;
  final String pengelolaId;
  final String nama;
  final String alamat;
  final double latitude;
  final double longitude;
  final String deskripsi;
  final String jamBuka;
  final String jamTutup;
  final String telepon;
  final String status;
  final double distance;
  final double avgRatingKeseluruhan;

  BengkelModel({
    required this.id,
    required this.pengelolaId,
    required this.nama,
    required this.alamat,
    required this.latitude,
    required this.longitude,
    required this.deskripsi,
    required this.jamBuka,
    required this.jamTutup,
    required this.telepon,
    required this.status,
    required this.distance,
    required this.avgRatingKeseluruhan,
  });

  factory BengkelModel.fromJson(Map<String, dynamic> json) {
    return BengkelModel(
      id: json['id'] ?? 0,
      pengelolaId: json['pengelola_id'] ?? '',
      nama: json['nama'] ?? '',
      alamat: json['alamat'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      deskripsi: json['deskripsi'] ?? '',
      jamBuka: json['jam_buka'] ?? '',
      jamTutup: json['jam_tutup'] ?? '',
      telepon: json['telepon'] ?? '',
      status: json['status'] ?? '',
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      avgRatingKeseluruhan: (json['avg_rating_keseluruhan'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
