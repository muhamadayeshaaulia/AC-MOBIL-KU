import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class BookingsTab extends StatelessWidget {
  final List<dynamic> bookingHistory;
  final bool isLoading;
  final Future<void> Function() onRefresh;

  const BookingsTab({
    super.key,
    required this.bookingHistory,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : bookingHistory.isEmpty
              ? const Center(
                  child: Text(
                    'Belum ada riwayat booking.',
                    style: TextStyle(color: AppTheme.textSecondaryColor),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: bookingHistory.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final booking = bookingHistory[index];
                    final String status = booking['status'] ?? 'menunggu';
                    
                    Color statusColor;
                    if (status == 'selesai') {
                      statusColor = const Color(0xFF10B981);
                    } else if (status == 'diterima' || status == 'diproses') {
                      statusColor = AppTheme.primaryColor;
                    } else {
                      statusColor = Colors.orangeAccent;
                    }

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Order #${booking['id']}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            booking['bengkel']?['nama'] ?? 'Bengkel Partner',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Keluhan: ${booking['keluhan'] ?? '-'}',
                            style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Color(0xFF334155), height: 1),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Biaya: Rp ${booking['total_biaya'] ?? 0}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                                label: const Text('HUBUNGI', style: TextStyle(fontSize: 11)),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  backgroundColor: AppTheme.cardColor,
                                  foregroundColor: Colors.white,
                                  side: BorderSide(color: Colors.teal.withOpacity(0.5)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
