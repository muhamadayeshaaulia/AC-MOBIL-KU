import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class RecommendationsTab extends StatelessWidget {
  final String userNama;
  final String userRole;
  final List<dynamic> recommendedBengkels;
  final bool isLoading;
  final Future<void> Function() onRefresh;

  const RecommendationsTab({
    super.key,
    required this.userNama,
    required this.userRole,
    required this.recommendedBengkels,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        physics: const AlwaysScrollableScrollPhysics(),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userNama,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Role: $userRole',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                        ),
                        const SizedBox(height: 4),
                        const Row(
                          children: [
                            Icon(Icons.gps_fixed, size: 12, color: AppTheme.primaryColor),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Jakarta Barat (GPS Terkoneksi)',
                                style: TextStyle(fontSize: 11, color: AppTheme.primaryColor),
                              ),
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

            isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recommendedBengkels.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final bengkel = recommendedBengkels[index];
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
                                    bengkel['nama'] ?? 'Bengkel AC',
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
                                    color: (bengkel['status'] == 'Buka' || bengkel['status'] == 'aktif')
                                        ? const Color(0xFF10B981).withOpacity(0.1)
                                        : Colors.redAccent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    (bengkel['status'] == 'Buka' || bengkel['status'] == 'aktif') ? 'Buka' : 'Tutup',
                                    style: TextStyle(
                                      color: (bengkel['status'] == 'Buka' || bengkel['status'] == 'aktif')
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
                              bengkel['alamat'] ?? '',
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
                                      '${(bengkel['avg_rating_keseluruhan'] ?? 0.0).toStringAsFixed(1)}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(width: 16),
                                    const Icon(Icons.navigation_outlined, color: AppTheme.primaryColor, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${bengkel['distance'] ?? 0.0} Km',
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
                                  child: const Text('RESERVASI', style: TextStyle(fontSize: 12)),
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
