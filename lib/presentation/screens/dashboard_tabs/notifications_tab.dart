import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class NotificationsTab extends StatelessWidget {
  const NotificationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        'title': 'Booking Diterima',
        'desc': 'Booking Anda di AC Jaya Abadi Sentosa telah diterima oleh pengelola. Silakan datang sesuai jadwal.',
        'time': '10 Menit Lalu',
        'icon': Icons.check_circle_outline_rounded,
        'color': const Color(0xFF10B981),
      },
      {
        'title': 'Status Service Selesai',
        'desc': 'Service AC Mobil Avanza Anda telah selesai dikerjakan. Silakan melakukan pembayaran.',
        'time': '2 Jam Lalu',
        'icon': Icons.build_circle_outlined,
        'color': AppTheme.primaryColor,
      },
      {
        'title': 'Rekomendasi Baru Terdekat',
        'desc': 'Ada bengkel AC berjarak 1.2 Km baru saja bergabung. Dapatkan diskon 10% minggu ini!',
        'time': '1 Hari Lalu',
        'icon': Icons.local_offer_outlined,
        'color': Colors.amber,
      }
    ];

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
                        Text(
                          notif['title'] as String,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
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
