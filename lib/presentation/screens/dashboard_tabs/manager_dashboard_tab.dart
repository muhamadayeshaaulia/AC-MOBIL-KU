import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../add_service_screen.dart';

class ManagerDashboardTab extends StatelessWidget {
  final String nama;
  final Map<String, dynamic>? myBengkelDetails;
  final bool isBengkelLoading;
  final List<dynamic> servicesList;
  final List<dynamic> bookingHistory;
  final Future<void> Function(String nama, String deskripsi, double harga, String fotoUrl) onAddLayanan;
  final VoidCallback onViewCatalog;
  final VoidCallback onViewBookings;
  final VoidCallback onViewProfile;

  const ManagerDashboardTab({
    super.key,
    required this.nama,
    required this.myBengkelDetails,
    required this.isBengkelLoading,
    required this.servicesList,
    required this.bookingHistory,
    required this.onAddLayanan,
    required this.onViewCatalog,
    required this.onViewBookings,
    required this.onViewProfile,
  });

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

  @override
  Widget build(BuildContext context) {
    final int servicesCount = servicesList.length;
    final int bookingsCount = bookingHistory.length;
    final String bengkelName = myBengkelDetails?['nama'] ?? 'Bengkel AC Anda';
    final String statusBengkel = myBengkelDetails?['status'] == 'aktif' ? 'Buka' : 'Tutup';
    final String fotoUrl = (myBengkelDetails?['foto_url'] != null && myBengkelDetails!['foto_url'].toString().isNotEmpty)
        ? myBengkelDetails!['foto_url']
        : 'https://images.unsplash.com/photo-1486006920555-c77dce18193b?auto=format&fit=crop&q=80&w=600';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Premium Curved Header with Dynamic Greeting
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
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
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
                    // Circular Workshop Logo
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundImage: NetworkImage(fotoUrl),
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
                    Column(
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
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Status: $statusBengkel',
                            style: const TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
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
          
          const SizedBox(height: 28),

          // 2. Menu Section Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'Menu Kelola Pengelola',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. 2x2 Grid Menu for Pengelola
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.15,
              children: [
                _buildMenuCard(
                  context,
                  Icons.construction_rounded,
                  'Katalog Jasa',
                  'Kelola daftar harga & jasa',
                  const Color(0xFF10B981),
                  onViewCatalog,
                ),
                _buildMenuCard(
                  context,
                  Icons.history_edu_rounded,
                  'Booking Masuk',
                  'Lihat daftar reservasi',
                  const Color(0xFF3B82F6),
                  onViewBookings,
                ),
                _buildMenuCard(
                  context,
                  Icons.add_circle_outline_rounded,
                  'Tambah Jasa',
                  'Buat layanan baru',
                  const Color(0xFFF59E0B),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddServiceScreen(onAddLayanan: onAddLayanan),
                      ),
                    );
                  },
                ),
                _buildMenuCard(
                  context,
                  Icons.storefront_outlined,
                  'Profil Bengkel',
                  'Detail & Jam Operasional',
                  const Color(0xFFEC4899),
                  onViewProfile,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
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
        padding: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 9,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
