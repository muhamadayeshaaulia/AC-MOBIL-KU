import 'dart:io';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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
                            'Layanan: ${booking['layanan']?['nama'] ?? '-'}',
                            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Catatan: ${booking['catatan']?.isNotEmpty == true ? booking['catatan'] : '-'}',
                            style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Color(0xFF334155), height: 1),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Metode: ${booking['metode_pembayaran'] ?? '-'}',
                                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'DP: Rp ${booking['nominal_dp'] ?? 0}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  _showStrukDialog(context, booking);
                                },
                                icon: const Icon(Icons.receipt_long_rounded, size: 14),
                                label: const Text('STRUK', style: TextStyle(fontSize: 11)),
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

  void _showStrukDialog(BuildContext context, Map<String, dynamic> booking) {
    final screenshotController = ScreenshotController();
    bool isCapturing = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppTheme.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Struk Pembayaran DP', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              content: Screenshot(
                controller: screenshotController,
                child: Container(
                  color: AppTheme.cardColor, // Ensure background is captured
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStrukRow('ID Reservasi', '#${booking['id']}'),
                      _buildStrukRow('Bengkel', booking['bengkel']?['nama'] ?? '-'),
                      _buildStrukRow('Layanan', booking['layanan']?['nama'] ?? '-'),
                      _buildStrukRow('Jadwal', booking['tanggal_booking'] != null ? booking['tanggal_booking'].toString().substring(0, 16).replaceFirst('T', ' ') : '-'),
                      const Divider(color: Colors.white24, height: 24),
                      _buildStrukRow('Metode', booking['metode_pembayaran'] ?? '-'),
                      _buildStrukRow('Total DP', 'Rp ${booking['nominal_dp'] ?? 0}', isBold: true, isPrice: true),
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'Silakan tunjukkan struk ini saat datang ke bengkel.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isCapturing
                      ? null
                      : () async {
                          setStateDialog(() => isCapturing = true);
                          try {
                            final image = await screenshotController.capture(delay: const Duration(milliseconds: 10));
                            if (image != null) {
                              final directory = await getTemporaryDirectory();
                              final imagePath = await File('${directory.path}/struk_dp_${booking['id']}.png').create();
                              await imagePath.writeAsBytes(image);
                              
                              if (context.mounted) {
                                Navigator.pop(ctx);
                                await Share.shareXFiles([XFile(imagePath.path)], text: 'Struk DP Reservasi #${booking['id']}');
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Gagal membuat struk.'), backgroundColor: Colors.redAccent),
                              );
                            }
                          } finally {
                            if (context.mounted) {
                              setStateDialog(() => isCapturing = false);
                            }
                          }
                        },
                  child: isCapturing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Bagikan/Unduh', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Tutup', style: TextStyle(color: Colors.white70)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Widget _buildStrukRow(String label, String value, {bool isBold = false, bool isPrice = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isPrice ? const Color(0xFFF59E0B) : Colors.white,
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
