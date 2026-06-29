import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/navigation/app_routes.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Mock data of nearby bengkels from hybrid CF + Haversine algorithm
  final List<Map<String, dynamic>> _recommendedBengkels = [
    {
      'nama': 'AC Jaya Abadi Sentosa',
      'alamat': 'Jl. Daan Mogot Raya No.24, Jakarta Barat',
      'distance': 2.4,
      'rating': 4.8,
      'status': 'Buka',
      'layanan': 'Isi Freon, Cuci Evaporator, Tambah Oli Kompresor',
    },
    {
      'nama': 'Bengkel AC Mobil Dingin Jaya',
      'alamat': 'Jl. Kebon Jeruk Indah No.10, Jakarta Barat',
      'distance': 5.1,
      'rating': 4.6,
      'status': 'Buka',
      'layanan': 'Service Kompresor, Ganti Filter Kabin, Las Selang',
    },
    {
      'nama': 'Sejahtera Car AC Specialist',
      'alamat': 'Jl. Palmerah Barat No.15, Jakarta Pusat',
      'distance': 7.8,
      'rating': 4.5,
      'status': 'Tutup',
      'layanan': 'Overhaul System, Retrofit R12 ke R134a',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Dashboard Rekomendasi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () {
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User greeting and coordinates overview
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.teal.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: const Icon(Icons.person, size: 36, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dimas Prasetyo',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Role: Pelanggan (NIM: 1123150165)',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: AppTheme.primaryColor),
                            SizedBox(width: 4),
                            Text(
                              'Jakarta Barat (GPS Terkoneksi)',
                              style: TextStyle(fontSize: 11, color: AppTheme.primaryColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            
            // Header for top CF recommendations
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Top-N Rekomendasi Terdekat',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Icon(Icons.tune_rounded, size: 20, color: AppTheme.textSecondaryColor),
              ],
            ),
            const SizedBox(height: 16),

            // List of recommended bengkels
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recommendedBengkels.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final bengkel = _recommendedBengkels[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              bengkel['nama'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: bengkel['status'] == 'Buka'
                                  ? const Color(0xFF10B981).withOpacity(0.1)
                                  : Colors.redAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              bengkel['status'],
                              style: TextStyle(
                                color: bengkel['status'] == 'Buka'
                                    ? const Color(0xFF10B981)
                                    : Colors.redAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        bengkel['alamat'],
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Color(0xFF334155), height: 1),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '${bengkel['rating']}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(width: 16),
                              const Icon(Icons.navigation_outlined, color: AppTheme.primaryColor, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${bengkel['distance']} Km',
                                style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Membuka detail ${bengkel['nama']}...'),
                                  backgroundColor: AppTheme.primaryColor,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('PILIH', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
