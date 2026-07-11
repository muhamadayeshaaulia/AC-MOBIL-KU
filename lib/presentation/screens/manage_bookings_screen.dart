import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/services/notification_service.dart';

class ManageBookingsScreen extends StatefulWidget {
  const ManageBookingsScreen({super.key});

  @override
  State<ManageBookingsScreen> createState() => _ManageBookingsScreenState();
}

class _ManageBookingsScreenState extends State<ManageBookingsScreen> {
  final ApiClient _apiClient = ApiClient();
  List<dynamic> _bookingQueue = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookingQueue();
  }

  Future<void> _loadBookingQueue() async {
    try {
      setState(() => _isLoading = true);
      final response = await _apiClient.get('/booking/queue');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          _bookingQueue = decoded['data'] ?? [];
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load queue');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading bookings queue: $e');
    }
  }

  Future<void> _updateBookingStatus(int bookingId, String newStatus, String orderNumber, String customerName) async {
    try {
      final response = await _apiClient.put('/booking/$bookingId/status', {
        'status': newStatus,
      });

      if (response.statusCode == 200) {
        if (newStatus == 'dikonfirmasi') {
          NotificationService().showBookingAcceptedNotification(orderNumber, customerName);
        } else if (newStatus == 'selesai') {
          NotificationService().showBookingCompletedNotification(orderNumber, customerName);
        }

        _loadBookingQueue();
      } else {
        throw Exception('Failed to update status');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui status: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  String _formatDateTime(String isoStr) {
    try {
      final dt = DateTime.parse(isoStr).toLocal();
      final String day = dt.day.toString().padLeft(2, '0');
      final String month = dt.month.toString().padLeft(2, '0');
      final String year = dt.year.toString();
      final String hour = dt.hour.toString().padLeft(2, '0');
      final String minute = dt.minute.toString().padLeft(2, '0');
      return '$day-$month-$year  $hour:$minute';
    } catch (e) {
      return isoStr;
    }
  }

  String _formatRupiah(double amount) {
    final int val = amount.toInt();
    final String str = val.toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return str.replaceAllMapped(reg, (Match match) => '${match[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Reservasi Booking Masuk'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadBookingQueue,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookingQueue.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_turned_in_outlined, color: Colors.white24, size: 64),
                      const SizedBox(height: 16),
                      const Text(
                        'Tidak Ada Booking Aktif',
                        style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Belum ada reservasi masuk dari pelanggan.',
                        style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24.0),
                  itemCount: _bookingQueue.length,
                  itemBuilder: (context, index) {
                    final booking = _bookingQueue[index];
                    final int bookingId = booking['id'] as int;
                    final String orderNumber = booking['order_number'] ?? '#$bookingId';
                    final String status = booking['status'] ?? 'menunggu';
                    final String catatan = booking['catatan'] ?? '-';
                    final String tanggal = booking['tanggal_booking'] ?? '';
                    
                    final pelanggan = booking['pelanggan'] ?? {};
                    final String pelangganNama = pelanggan['nama'] ?? 'Pelanggan';
                    final String pelangganPhone = pelanggan['telepon'] ?? '-';
                    
                    final layanan = booking['layanan'] ?? {};
                    final String layananNama = layanan['nama'] ?? 'Servis AC';
                    final double harga = (layanan['estimasi_harga'] as num?)?.toDouble() ?? 0.0;

                    // Compute visual status tags
                    Color statusColor = const Color(0xFFF59E0B);
                    String statusLabel = 'Menunggu';
                    if (status == 'dikonfirmasi') {
                      statusColor = const Color(0xFF3B82F6);
                      statusLabel = 'Diterima';
                    } else if (status == 'selesai') {
                      statusColor = const Color(0xFF10B981);
                      statusLabel = 'Selesai';
                    } else if (status == 'dibatalkan') {
                      statusColor = Colors.redAccent;
                      statusLabel = 'Ditolak';
                    }

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
                          // Header Card: Date and Status Tag
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '$orderNumber • ${_formatDateTime(tanggal)}',
                                  style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: statusColor.withOpacity(0.2)),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Colors.white10, height: 1),
                          const SizedBox(height: 12),

                          // Customer Information details
                          Row(
                            children: [
                              const Icon(Icons.person_outline_rounded, color: AppTheme.primaryColor, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                pelangganNama,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.phone_android_rounded, color: AppTheme.textSecondaryColor, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                pelangganPhone,
                                style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Colors.white10, height: 1),
                          const SizedBox(height: 12),

                          // Layanan details
                          const Text('LAYANAN YANG DIPILIH:', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 9, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(layananNama, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(
                            'Estimasi Biaya: Rp ${_formatRupiah(harga)}',
                            style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Metode: ${booking['metode_pembayaran'] ?? '-'}',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'DP Masuk: Rp ${_formatRupiah((booking['nominal_dp'] as num?)?.toDouble() ?? 0.0)}',
                            style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          
                          // Customer notes (catatan)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.02),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.04)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Catatan Pelanggan / Keluhan:', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 9, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(catatan, style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.4)),
                              ],
                            ),
                          ),

                          // Dynamic Action Panel based on Booking Status
                          if (status == 'menunggu') ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _updateBookingStatus(bookingId, 'dibatalkan', orderNumber, pelangganNama),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.redAccent,
                                      side: const BorderSide(color: Colors.redAccent),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    child: const Text('TOLAK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _updateBookingStatus(bookingId, 'dikonfirmasi', orderNumber, pelangganNama),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    child: const Text('TERIMA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                ),
                              ],
                            ),
                          ] else if (status == 'dikonfirmasi') ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _updateBookingStatus(bookingId, 'selesai', orderNumber, pelangganNama),
                                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                                label: const Text('SELESAIKAN PENGERJAAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
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
