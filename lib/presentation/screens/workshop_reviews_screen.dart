import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';

class WorkshopReviewsScreen extends StatefulWidget {
  final int bengkelId;
  const WorkshopReviewsScreen({super.key, required this.bengkelId});

  @override
  State<WorkshopReviewsScreen> createState() => _WorkshopReviewsScreenState();
}

class _WorkshopReviewsScreenState extends State<WorkshopReviewsScreen> {
  final ApiClient _apiClient = ApiClient();
  List<dynamic> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      setState(() => _isLoading = true);
      final response = await _apiClient.get('/rating/bengkel/${widget.bengkelId}');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          _reviews = decoded['data'] ?? [];
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load reviews');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading reviews: $e');
    }
  }

  Widget _buildStars(int count, {Color color = const Color(0xFFF59E0B)}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < count ? Icons.star_rounded : Icons.star_border_rounded,
          color: index < count ? color : Colors.white24,
          size: 14,
        );
      }),
    );
  }

  String _formatDateTime(String isoStr) {
    try {
      final dt = DateTime.parse(isoStr).toLocal();
      final String day = dt.day.toString().padLeft(2, '0');
      final String month = dt.month.toString().padLeft(2, '0');
      final String year = dt.year.toString();
      return '$day-$month-$year';
    } catch (e) {
      return isoStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Rating & Ulasan Pelanggan'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadReviews,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reviews.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rate_review_outlined, color: Colors.white24, size: 64),
                      const SizedBox(height: 16),
                      const Text(
                        'Belum Ada Ulasan',
                        style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Rating dan ulasan dari pelanggan akan muncul di sini.',
                        style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24.0),
                  itemCount: _reviews.length,
                  itemBuilder: (context, index) {
                    final review = _reviews[index];
                    final String ulasan = review['ulasan'] ?? '-';
                    final String tanggal = review['created_at'] ?? '';
                    final int kualitas = review['rating_kualitas'] ?? 5;
                    final int harga = review['rating_harga'] ?? 5;
                    
                    final pelanggan = review['pelanggan'] ?? {};
                    final String pelangganNama = pelanggan['nama'] ?? 'Pelanggan';
                    final String fotoUrl = pelanggan['foto_url'] ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Customer Header
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                backgroundImage: fotoUrl.isNotEmpty ? NetworkImage(fotoUrl) : null,
                                child: fotoUrl.isEmpty
                                    ? const Icon(Icons.person_rounded, color: AppTheme.primaryColor, size: 18)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pelangganNama,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatDateTime(tanggal),
                                      style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(color: Colors.white10, height: 1),
                          const SizedBox(height: 12),

                          // Ratings breakdown (Quality & Price)
                          Row(
                            children: [
                              const Text(
                                'Kualitas Servis:  ',
                                style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 11),
                              ),
                              _buildStars(kualitas),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Text(
                                'Kesesuaian Harga:  ',
                                style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 11),
                              ),
                              _buildStars(harga, color: const Color(0xFF10B981)),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Written review text
                          if (ulasan.isNotEmpty && ulasan != '-') ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.01),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.03)),
                              ),
                              child: Text(
                                ulasan,
                                style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4, fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
