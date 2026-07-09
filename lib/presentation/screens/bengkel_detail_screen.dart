import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import 'booking_screen.dart';

class BengkelDetailScreen extends StatefulWidget {
  final Map<String, dynamic> bengkel;

  const BengkelDetailScreen({super.key, required this.bengkel});

  @override
  State<BengkelDetailScreen> createState() => _BengkelDetailScreenState();
}

class _BengkelDetailScreenState extends State<BengkelDetailScreen> {
  final ApiClient _apiClient = ApiClient();
  List<dynamic> _layanan = [];
  List<dynamic> _reviews = [];
  bool _isLoadingLayanan = true;
  bool _isLoadingReviews = true;

  @override
  void initState() {
    super.initState();
    _loadLayanan();
    _loadReviews();
  }

  Future<void> _loadLayanan() async {
    try {
      final int bengkelId = (widget.bengkel['id'] as num?)?.toInt() ?? int.parse(widget.bengkel['id'].toString());
      final response = await _apiClient.get('/layanan/bengkel/$bengkelId');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          _layanan = decoded['data'] ?? decoded ?? [];
          _isLoadingLayanan = false;
        });
      }
    } catch (e) {
      print('Error loading layanan: $e');
      setState(() => _isLoadingLayanan = false);
    }
  }

  Future<void> _loadReviews() async {
    try {
      final int bengkelId = (widget.bengkel['id'] as num?)?.toInt() ?? int.parse(widget.bengkel['id'].toString());
      final response = await _apiClient.get('/rating/bengkel/$bengkelId');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          _reviews = decoded['data'] ?? [];
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      print('Error loading reviews: $e');
      setState(() => _isLoadingReviews = false);
    }
  }

  String _formatRupiah(double amount) {
    final int val = amount.toInt();
    final String str = val.toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return 'Rp ${str.replaceAllMapped(reg, (m) => '${m[1]}.')}';
  }

  Widget _buildStars(double avg) {
    final int filled = avg.round().clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) => Icon(
        i < filled ? Icons.star_rounded : Icons.star_border_rounded,
        color: i < filled ? const Color(0xFFF59E0B) : Colors.white24,
        size: 14,
      )),
    );
  }

  Future<void> _openMaps() async {
    final double? lat = (widget.bengkel['latitude'] as num?)?.toDouble();
    final double? lng = (widget.bengkel['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null || (lat == 0.0 && lng == 0.0)) return;
    final Uri uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String nama = widget.bengkel['nama'] ?? 'Bengkel AC';
    final String alamat = widget.bengkel['alamat'] ?? '';
    final String deskripsi = widget.bengkel['deskripsi'] ?? '';
    final String jamBuka = widget.bengkel['jam_buka'] ?? '-';
    final String jamTutup = widget.bengkel['jam_tutup'] ?? '-';
    final double avgRating = (widget.bengkel['avg_rating_keseluruhan'] as num?)?.toDouble() ?? 0.0;
    final String coverUrl = widget.bengkel['foto_url'] ?? '';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Collapsible header with cover photo
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppTheme.backgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              background: coverUrl.isNotEmpty
                  ? Image.network(coverUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderCover())
                  : _buildPlaceholderCover(),
              title: Text(
                nama,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              titlePadding: const EdgeInsets.only(left: 52, bottom: 12),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rating and distance row
                  Row(
                    children: [
                      _buildStars(avgRating),
                      const SizedBox(width: 6),
                      Text(
                        avgRating > 0 ? avgRating.toStringAsFixed(1) : 'Belum ada rating',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const Spacer(),
                      if ((widget.bengkel['distance'] as num?)?.toDouble() != null)
                        Row(
                          children: [
                            const Icon(Icons.navigation_outlined, color: AppTheme.primaryColor, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${(widget.bengkel['distance'] as num).toStringAsFixed(1)} km',
                              style: const TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Address
                  if (alamat.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: AppTheme.textSecondaryColor, size: 15),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(alamat, style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),

                  // Operating hours + open/closed badge
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, color: AppTheme.textSecondaryColor, size: 15),
                      const SizedBox(width: 6),
                      Text('$jamBuka – $jamTutup', style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  if (deskripsi.isNotEmpty) ...[
                    Text(deskripsi, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
                    const SizedBox(height: 16),
                  ],

                  // CTA Buttons row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openMaps,
                          icon: const Icon(Icons.directions_rounded, size: 16),
                          label: const Text('Dapatkan Arah'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF10B981),
                            side: const BorderSide(color: Color(0xFF10B981)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),
                  const Text('Katalog Jasa Layanan AC', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Pilih jasa untuk membuat reservasi', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                  const SizedBox(height: 16),

                  // Layanan list
                  _isLoadingLayanan
                      ? const Center(child: CircularProgressIndicator())
                      : _layanan.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(16)),
                              child: const Center(
                                child: Text('Belum ada layanan terdaftar.', style: TextStyle(color: AppTheme.textSecondaryColor)),
                              ),
                            )
                          : Column(
                              children: _layanan.map((item) => _buildLayananCard(context, item)).toList(),
                            ),

                  const SizedBox(height: 28),
                  const Text('Ulasan Pelanggan', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // Reviews list
                  _isLoadingReviews
                      ? const Center(child: CircularProgressIndicator())
                      : _reviews.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(16)),
                              child: const Center(
                                child: Text('Belum ada ulasan.', style: TextStyle(color: AppTheme.textSecondaryColor)),
                              ),
                            )
                          : Column(
                              children: _reviews.map((r) => _buildReviewCard(r)).toList(),
                            ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderCover() {
    return Container(
      color: const Color(0xFF1E293B),
      child: const Center(
        child: Icon(Icons.car_repair, color: Colors.white24, size: 64),
      ),
    );
  }

  Widget _buildLayananCard(BuildContext context, Map<String, dynamic> item) {
    final double harga = (item['estimasi_harga'] as num?)?.toDouble() ?? 0;
    final String fotoUrl = item['foto_url'] ?? '';
    final List<String> fotoList = fotoUrl.isNotEmpty ? fotoUrl.split(',') : [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image carousel if available
          if (fotoList.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                fotoList.first.trim(),
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['nama'] ?? 'Layanan AC',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['deskripsi'] ?? '',
                            style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatRupiah(harga),
                          style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Tersedia', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orangeAccent.withOpacity(0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.info_outline_rounded, color: Colors.orangeAccent, size: 14),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Harga di atas hanyalah estimasi dan dapat berubah (lebih atau kurang) tergantung pada hasil pengecekan dan proses perbaikan.',
                          style: TextStyle(color: Colors.orangeAccent, fontSize: 10, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingScreen(
                            bengkel: widget.bengkel,
                            selectedLayanan: item,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('BUAT RESERVASI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final pelanggan = review['pelanggan'] ?? {};
    final String pelangganNama = pelanggan['nama'] ?? 'Pelanggan';
    final int kualitas = review['rating_kualitas'] ?? 5;
    final int harga = review['rating_harga'] ?? 5;
    final String ulasan = review['ulasan'] ?? '';
    
    // Check if there is a booked service linked
    String layananName = '';
    if (review['booking'] != null && review['booking']['layanan'] != null) {
      layananName = review['booking']['layanan']['nama'] ?? '';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: const Icon(Icons.person_rounded, color: AppTheme.primaryColor, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(pelangganNama, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          if (layananName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Layanan: $layananName',
                style: const TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Kualitas:', style: TextStyle(color: Colors.white54, fontSize: 10)),
              const SizedBox(width: 4),
              _buildStars(kualitas.toDouble()),
              const SizedBox(width: 12),
              const Text('Harga:', style: TextStyle(color: Colors.white54, fontSize: 10)),
              const SizedBox(width: 4),
              _buildStars(harga.toDouble()),
            ],
          ),
          if (ulasan.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(ulasan, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4, fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }
}
