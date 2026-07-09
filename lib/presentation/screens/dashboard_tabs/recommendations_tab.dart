import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../bengkel_detail_screen.dart';

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
                      return BengkelCardWithCatalog(bengkel: bengkel, index: index);
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

class BengkelCardWithCatalog extends StatefulWidget {
  final Map<String, dynamic> bengkel;
  final int index;

  const BengkelCardWithCatalog({super.key, required this.bengkel, required this.index});

  @override
  State<BengkelCardWithCatalog> createState() => _BengkelCardWithCatalogState();
}

class _BengkelCardWithCatalogState extends State<BengkelCardWithCatalog> {
  final ApiClient _apiClient = ApiClient();
  List<dynamic> _layanans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLayanan();
  }

  Future<void> _fetchLayanan() async {
    try {
      final int bengkelId = widget.bengkel['id'] as int;
      final response = await _apiClient.get('/layanan/bengkel/$bengkelId');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          _layanans = decoded['data'] ?? decoded ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _formatRupiah(double amount) {
    final int val = amount.toInt();
    final String str = val.toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return 'Rp ${str.replaceAllMapped(reg, (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    final bengkel = widget.bengkel;
    final String coverUrl = bengkel['foto_url'] ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BengkelDetailScreen(bengkel: bengkel),
          ),
        );
      },
      child: Container(
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
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: coverUrl.isNotEmpty
                  ? Image.network(
                      coverUrl,
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1E293B), height: 130),
                    )
                  : Container(
                      height: 130,
                      width: double.infinity,
                      color: const Color(0xFF1E293B),
                      child: const Icon(Icons.car_repair, color: Colors.white24, size: 48),
                    ),
            ),
            const SizedBox(height: 12),
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
            
            // ==========================================
            // KATALOG PREVIEW SECTION
            // ==========================================
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (_layanans.isNotEmpty) ...[
              const Text('Katalog Jasa:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _layanans.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final l = _layanans[i];
                    final double harga = (l['estimasi_harga'] as num?)?.toDouble() ?? 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF334155),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(l['nama'] ?? '-', style: const TextStyle(color: Colors.white, fontSize: 11)),
                          const SizedBox(width: 6),
                          Text(_formatRupiah(harga), style: const TextStyle(color: AppTheme.primaryColor, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            const Divider(color: Color(0xFF334155), height: 1),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${(bengkel['avg_rating_keseluruhan'] ?? 0.0).toStringAsFixed(1)}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BengkelDetailScreen(bengkel: bengkel),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('LIHAT JASA', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

