import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ManagerDashboardTab extends StatelessWidget {
  final String nama;
  final String userFotoUrl;
  final Map<String, dynamic>? myBengkelDetails;
  final bool isBengkelLoading;
  final List<dynamic> servicesList;
  final List<dynamic> bookingHistory;
  final VoidCallback onViewCatalog;
  final VoidCallback onViewBookings;
  final VoidCallback onViewReviews;

  const ManagerDashboardTab({
    key,
    required this.nama,
    required this.userFotoUrl,
    required this.myBengkelDetails,
    required this.isBengkelLoading,
    required this.servicesList,
    required this.bookingHistory,
    required this.onViewCatalog,
    required this.onViewBookings,
    required this.onViewReviews,
  }) : super(key: key);

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Selamat Pagi ☀️';
    } else if (hour >= 12 && hour < 15) {
      return 'Selamat Siang 🌤️';
    } else if (hour >= 15 && hour < 18) {
      return 'Selamat Sore ⛅';
    } else {
      return 'Selamat Malam 🌙';
    }
  }

  bool _isBengkelOpen(String? openStr, String? closeStr) {
    if (openStr == null || closeStr == null || openStr.isEmpty || closeStr.isEmpty) {
      return false; // Default to closed if hours aren't set
    }
    try {
      final now = DateTime.now();
      final nowMinutes = now.hour * 60 + now.minute;
      
      final openParts = openStr.split(':');
      final closeParts = closeStr.split(':');
      
      final openMinutes = int.parse(openParts[0]) * 60 + int.parse(openParts[1]);
      final closeMinutes = int.parse(closeParts[0]) * 60 + int.parse(closeParts[1]);
      
      if (closeMinutes < openMinutes) {
        // Overnight operating hours support (e.g. 22:00 to 03:00)
        return nowMinutes >= openMinutes || nowMinutes <= closeMinutes;
      }
      return nowMinutes >= openMinutes && nowMinutes <= closeMinutes;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int servicesCount = servicesList.length;
    final int bookingsCount = bookingHistory.length;
    final String bengkelName = myBengkelDetails?['nama'] ?? 'Bengkel AC Anda';
    
    // Automatically determine Open/Closed status based on operational hours
    final isOpen = _isBengkelOpen(myBengkelDetails?['jam_buka'], myBengkelDetails?['jam_tutup']);
    final String statusBengkel = isOpen ? 'Buka' : 'Tutup';
    final Color statusColor = isOpen ? const Color(0xFF10B981) : Colors.redAccent;

    // Use User Profile photo instead of Workshop photo for the user greeting avatar
    final String userAvatarUrl = userFotoUrl.isNotEmpty
        ? userFotoUrl
        : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&q=80&w=200';

    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. FIXED Curved Header (Will not scroll, stays locked at the top!)
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(24, statusBarHeight + 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Greeting Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: const TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nama,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Role Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.25)),
                          ),
                          child: const Text(
                            'Pengelola Bengkel',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Circular User Profile Avatar (Greeting Photo)
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundImage: NetworkImage(userAvatarUrl),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 20),

              // Workshop detail summary inside header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nama Bengkel:',
                          style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          bengkelName,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Jam Operasional: ${myBengkelDetails?['jam_buka'] ?? '-'} - ${myBengkelDetails?['jam_tutup'] ?? '-'}',
                          style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Status: $statusBengkel',
                          style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Circular stats indicators row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCircularStat(context, servicesCount.toString(), 'Layanan Jasa', AppTheme.primaryColor),
                  _buildCircularStat(context, bookingsCount.toString(), 'Reservasi Masuk', const Color(0xFF3B82F6)),
                ],
              ),
            ],
          ),
        ),

        // 2. SCROLLABLE Content (Only menus and list will scroll below the header!)
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Menu Section Header
                const Text(
                  'Menu Kelola Pengelola',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Vertical list of clean premium menu items
                _buildMenuCard(
                  context,
                  Icons.construction_rounded,
                  'Katalog Jasa',
                  'Kelola daftar harga & jasa layanan AC',
                  const Color(0xFF10B981),
                  onViewCatalog,
                ),
                _buildMenuCard(
                  context,
                  Icons.history_edu_rounded,
                  'Booking Masuk',
                  'Pantau dan terima reservasi masuk',
                  const Color(0xFF3B82F6),
                  onViewBookings,
                ),
                _buildMenuCard(
                  context,
                  Icons.star_rounded,
                  'Rating & Ulasan',
                  'Tingkat kepuasan dan ulasan pembeli',
                  const Color(0xFFF59E0B),
                  onViewReviews,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCircularStat(BuildContext context, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondaryColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color accentColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.3), size: 24),
          ],
        ),
      ),
    );
  }
}
