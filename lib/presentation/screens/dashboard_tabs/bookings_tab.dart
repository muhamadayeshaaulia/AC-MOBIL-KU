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

    String formatTanggal(dynamic tgl) {
      if (tgl == null) return '-';
      try {
        final dt = DateTime.parse(tgl.toString()).toLocal();
        return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      } catch (_) {
        return tgl.toString().substring(0, 16).replaceFirst('T', ' ');
      }
    }

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
                  width: double.maxFinite,
                  color: Colors.white, // Kertas putih
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.directions_car_filled_outlined, color: Colors.black87, size: 40),
                      const SizedBox(height: 8),
                      const Text(
                        'AC MOBILKU',
                        style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
                      const Text(
                        'BUKTI PEMBAYARAN DP',
                        style: TextStyle(color: Colors.black54, fontSize: 11),
                      ),
                      const SizedBox(height: 20),
                      Container(height: 1, color: Colors.black26, width: double.infinity),
                      const SizedBox(height: 16),
                      _buildStrukRow('ID Reservasi', '#${booking['id']}'),
                      _buildStrukRow('Bengkel', booking['bengkel']?['nama'] ?? '-'),
                      _buildStrukRow('Layanan', booking['layanan']?['nama'] ?? '-'),
                      _buildStrukRow('Jadwal', formatTanggal(booking['tanggal_booking'])),
                      _buildStrukRow('Metode', booking['metode_pembayaran'] ?? '-'),
                      const SizedBox(height: 8),
                      Container(height: 1, color: Colors.black26, width: double.infinity),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TOTAL DP', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
                          Text('Rp ${booking['nominal_dp'] ?? 0}', style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        '-- TERIMA KASIH --',
                        style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tunjukkan struk ini saat datang ke bengkel',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black38, fontSize: 10),
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

  Widget _buildStrukRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
