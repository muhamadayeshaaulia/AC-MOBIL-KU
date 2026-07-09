import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../providers/auth_provider.dart';
import 'payment_success_screen.dart';

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic> bengkel;
  final Map<String, dynamic> selectedLayanan;

  const BookingScreen({
    super.key,
    required this.bengkel,
    required this.selectedLayanan,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final ApiClient _apiClient = ApiClient();
  final _catatanController = TextEditingController();
  final _dpController = TextEditingController(text: '50000');

  DateTime? _selectedDate;
  String? _selectedTime;
  String _selectedPaymentMethod = 'Transfer Bank';
  bool _isSubmitting = false;

  final List<String> _paymentMethods = [
    'Transfer Bank',
    'E-Wallet (GoPay/OVO/Dana)',
  ];

  final List<String> _timeSlots = [
    '08:00', '09:00', '10:00', '11:00',
    '13:00', '14:00', '15:00', '16:00',
  ];

  @override
  void dispose() {
    _catatanController.dispose();
    _dpController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primaryColor,
            onPrimary: Colors.white,
            surface: AppTheme.cardColor,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String _formatRupiah(double amount) {
    final int val = amount.toInt();
    final String str = val.toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return 'Rp ${str.replaceAllMapped(reg, (m) => '${m[1]}.')}';
  }

  Future<void> _submitBooking() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal reservasi terlebih dahulu.'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih jam reservasi terlebih dahulu.'), backgroundColor: Colors.orange),
      );
      return;
    }

    final double dp = double.tryParse(_dpController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (dp < 50000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal DP minimal Rp 50.000'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final date = _selectedDate!;
      final timeParts = _selectedTime!.split(':');
      final formattedDate = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${timeParts[0]}:${timeParts[1]}";

      final bId = (widget.bengkel['id'] as num?)?.toInt() ?? int.tryParse(widget.bengkel['id'].toString()) ?? 0;
      final lId = (widget.selectedLayanan['id'] as num?)?.toInt() ?? int.tryParse(widget.selectedLayanan['id'].toString()) ?? 0;

      final response = await _apiClient.post('/booking', {
        'bengkel_id': bId,
        'layanan_id': lId,
        'tanggal_booking': formattedDate,
        'catatan': _catatanController.text.trim(),
        'metode_pembayaran': _selectedPaymentMethod,
        'nominal_dp': dp,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        final String orderNumber = decoded['data'] != null ? (decoded['data']['order_number'] ?? '-') : '-';

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentSuccessScreen(
                orderNumber: orderNumber,
                bengkelNama: widget.bengkel['nama'] ?? '-',
                layananNama: widget.selectedLayanan['nama'] ?? '-',
                jadwal: formattedDate,
                metode: _selectedPaymentMethod,
                nominalDp: dp.toDouble(),
              ),
            ),
            (route) => route.isFirst, // Remove all routes EXCEPT dashboard (isFirst)
            // Wait, pushAndRemoveUntil with isFirst will remove the current screen and push PaymentSuccessScreen ON TOP of the first route.
            // Oh actually, it pops everything above the first route and then pushes PaymentSuccessScreen.
          );
        }
      } else {
        final decoded = jsonDecode(response.body);
        final errorMsg = decoded['error'] ?? decoded['message'] ?? 'Terjadi kesalahan.';
        throw Exception(errorMsg);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat reservasi: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double harga = (widget.selectedLayanan['estimasi_harga'] as num?)?.toDouble() ?? 0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Buat Reservasi'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary card: bengkel + layanan terpilih
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ringkasan Reservasi', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.storefront_outlined, color: AppTheme.primaryColor, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(widget.bengkel['nama'] ?? '-', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.construction_rounded, color: AppTheme.primaryColor, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(widget.selectedLayanan['nama'] ?? '-', style: const TextStyle(color: Colors.white70)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.payments_outlined, color: Color(0xFFF59E0B), size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'Estimasi: ${_formatRupiah(harga)}',
                        style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
            const Text('Pilih Tanggal', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _selectedDate != null
                      ? AppTheme.primaryColor.withOpacity(0.4)
                      : Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, color: AppTheme.primaryColor),
                    const SizedBox(width: 14),
                    Text(
                      _selectedDate != null
                          ? '${_selectedDate!.day.toString().padLeft(2, '0')}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.year}'
                          : 'Ketuk untuk memilih tanggal',
                      style: TextStyle(
                        color: _selectedDate != null ? Colors.white : AppTheme.textSecondaryColor,
                        fontWeight: _selectedDate != null ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Text('Pilih Jam', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _timeSlots.map((time) {
                final bool isSelected = _selectedTime == time;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTime = time),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor : AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: Text(
                      time,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),
            const Text('Catatan / Keluhan', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _catatanController,
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Ceritakan keluhan atau kebutuhan AC mobil Anda...',
                hintStyle: const TextStyle(color: AppTheme.textSecondaryColor),
                filled: true,
                fillColor: AppTheme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.primaryColor),
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Text('Metode Pembayaran', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPaymentMethod,
                  isExpanded: true,
                  dropdownColor: AppTheme.cardColor,
                  icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  items: _paymentMethods.map((method) {
                    return DropdownMenuItem<String>(
                      value: method,
                      child: Text(method),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedPaymentMethod = val);
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Text('Nominal DP (Min. Rp 50.000)', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _dpController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                filled: true,
                fillColor: AppTheme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.primaryColor),
                ),
              ),
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitBooking,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('KONFIRMASI RESERVASI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
