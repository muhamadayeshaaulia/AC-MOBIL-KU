import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../bengkel_detail_screen.dart';

class RecommendationsTab extends StatelessWidget {
  final String userNama;
  final String userRole;
  final String userAddress;
  final List<dynamic> recommendedBengkels;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final VoidCallback onFilterTap;
  final VoidCallback onResetFilterTap;

  const RecommendationsTab({
    super.key,
    required this.userNama,
    required this.userRole,
    required this.userAddress,
    required this.recommendedBengkels,
    required this.isLoading,
    required this.onRefresh,
    required this.onFilterTap,
    required this.onResetFilterTap,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi,';
    if (hour < 15) return 'Selamat Siang,';
    if (hour < 18) return 'Selamat Sore,';
    return 'Selamat Malam,';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20.0),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom Curved Header
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                left: 24,
                right: 24,
                bottom: 32,
              ),
              decoration: const BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: const TextStyle(fontSize: 14, color: AppTheme.textSecondaryColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userNama,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: AppTheme.primaryColor),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                userAddress,
                                style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: const Icon(Icons.person, size: 30, color: AppTheme.primaryColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Header for top CF recommendations
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Rekomendasi Untuk Anda',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      AnimatedRefreshIcon(
                        onPressed: onResetFilterTap,
                        iconColor: AppTheme.textSecondaryColor,
                      ),
                      IconButton(
                        onPressed: onFilterTap,
                        icon: const Icon(Icons.tune_rounded, size: 20, color: AppTheme.primaryColor),
                        tooltip: 'Filter Rekomendasi',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),

            isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : recommendedBengkels.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(
                          child: Text(
                            'Belum ada rekomendasi bengkel di sekitar Anda saat ini.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: recommendedBengkels.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final bengkel = recommendedBengkels[index];
                            final bengkelId = bengkel['id']?.toString() ?? bengkel['nama'];
                            return BengkelCardWithCatalog(
                              key: ValueKey(bengkelId),
                              bengkel: bengkel,
                              index: index,
                            );
                          },
                        ),
                      ),
          ],
        ),
      ),
    );
  }
}

class AnimatedRefreshIcon extends StatefulWidget {
  final VoidCallback onPressed;
  final Color iconColor;

  const AnimatedRefreshIcon({super.key, required this.onPressed, required this.iconColor});

  @override
  State<AnimatedRefreshIcon> createState() => _AnimatedRefreshIconState();
}

class _AnimatedRefreshIconState extends State<AnimatedRefreshIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePress() {
    _controller.forward(from: 0.0);
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _handlePress,
      tooltip: 'Reset Filter',
      icon: RotationTransition(
        turns: _controller,
        child: Icon(Icons.refresh_rounded, size: 20, color: widget.iconColor),
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
      final idVal = widget.bengkel['id'];
      if (idVal == null) {
        setState(() => _isLoading = false);
        return;
      }
      final int bengkelId = (idVal as num?)?.toInt() ?? int.tryParse(idVal.toString()) ?? 0;
      final response = await _apiClient.get('/layanan/bengkel/$bengkelId');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          _layanans = decoded['data'] ?? decoded ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching layanan for bengkel ${widget.bengkel['id']}: $e');
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
            else ...[
              const Text('Katalog Jasa:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_layanans.isEmpty)
                const Text('Belum ada jasa ditambahkan.', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 11, fontStyle: FontStyle.italic))
              else
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
                      '${(bengkel['distance'] as num?)?.toStringAsFixed(1) ?? '0.0'} Km',
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

