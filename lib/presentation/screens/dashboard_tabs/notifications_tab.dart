import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class NotificationsTab extends StatelessWidget {
  final List<dynamic> bookingHistory;
  final String userRole;

  const NotificationsTab({
    super.key,
    required this.bookingHistory,
    required this.userRole,
  });

  String _formatTime(String? dateStr) {
    if (dateStr == null) return 'Baru saja';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inMinutes < 60) {
        return '${diff.inMinutes} Menit Lalu';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} Jam Lalu';
      } else {
        return '${diff.inDays} Hari Lalu';
      }
    } catch (e) {
      return 'Baru saja';
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> notifications = [];

    // Generate notifications from booking history
    for (var booking in bookingHistory) {
      final status = booking['status'] ?? '';
      final orderId = booking['order_number'] ?? '-';
      final tanggalBooking = booking['tanggal_booking'];
      final targetName = userRole == 'Pengelola Bengkel' 
          ? (booking['pelanggan']?['nama'] ?? 'Pelanggan')
          : (booking['bengkel']?['nama'] ?? 'Bengkel');

      if (status == 'menunggu_konfirmasi') {
        notifications.add({
          'title': userRole == 'Pengelola Bengkel' ? 'Ada Booking Masuk!' : 'Booking Berhasil Dibuat',
          'desc': userRole == 'Pengelola Bengkel' 
              ? '$targetName melakukan reservasi (Order: $orderId). Segera konfirmasi jadwalnya.'
              : 'Reservasi Anda di $targetName dengan ID $orderId telah diteruskan ke bengkel.',
          'time': _formatTime(tanggalBooking),
          'icon': Icons.hourglass_top_rounded,
          'color': Colors.amber,
        });
      } else if (status == 'diterima') {
        notifications.add({
          'title': 'Booking Diterima',
          'desc': userRole == 'Pengelola Bengkel'
              ? 'Anda telah menerima reservasi $targetName.'
              : 'Reservasi Anda di $targetName telah diterima! Silakan datang sesuai jadwal.',
          'time': _formatTime(tanggalBooking),
          'icon': Icons.check_circle_outline_rounded,
          'color': const Color(0xFF10B981),
        });
      } else if (status == 'selesai') {
        notifications.add({
          'title': 'Service Selesai',
          'desc': 'Service (Order: $orderId) telah selesai dikerjakan.',
          'time': _formatTime(tanggalBooking),
          'icon': Icons.build_circle_outlined,
          'color': AppTheme.primaryColor,
        });
      } else if (status == 'ditolak') {
        notifications.add({
          'title': 'Booking Ditolak',
          'desc': 'Mohon maaf, reservasi (Order: $orderId) tidak dapat dilanjutkan.',
          'time': _formatTime(tanggalBooking),
          'icon': Icons.cancel_outlined,
          'color': Colors.red,
        });
      }
    }

    if (notifications.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada notifikasi saat ini.',
          style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final notif = notifications[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (notif['color'] as Color).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(notif['icon'] as IconData, color: notif['color'] as Color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notif['title'] as String,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          notif['time'] as String,
                          style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notif['desc'] as String,
                      style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
