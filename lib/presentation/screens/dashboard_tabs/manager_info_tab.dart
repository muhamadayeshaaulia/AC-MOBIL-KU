import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ManagerInfoTab extends StatelessWidget {
  const ManagerInfoTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Premium Info Welcome Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.gavel_rounded, color: Colors.white, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Pusat Informasi & Aturan Mitra',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  'Panduan operasional, aturan hukum, dan standar pelayanan untuk mitra pengelola bengkel AC MobilKu.',
                  style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 1. Operational Rules Section
          const Text(
            'Aturan & Standar Pelayanan',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            context,
            Icons.verified_user_outlined,
            'Kejujuran & Transparansi Harga',
            'Mitra wajib mengisi katalog jasa dengan estimasi harga yang jujur dan akurat. Dilarang keras melakukan markup harga sepihak atau membebankan biaya tambahan tersembunyi kepada pelanggan di luar aplikasi.',
            const Color(0xFF10B981),
          ),
          _buildInfoCard(
            context,
            Icons.timer_outlined,
            'Ketepatan Waktu Layanan',
            'Harap menanggapi notifikasi booking masuk secepatnya. Jika terjadi keterlambatan atau bengkel penuh, pengelola wajib menghubungi pelanggan terlebih dahulu melalui kontak yang tertera.',
            const Color(0xFF3B82F6),
          ),
          _buildInfoCard(
            context,
            Icons.cleaning_services_outlined,
            'Kualitas Servis & Garansi',
            'Semua servis AC mobil harus dilakukan oleh teknisi berpengalaman dengan menggunakan suku cadang/freon sesuai standar spesifikasi kendaraan pelanggan untuk menjaga rating kualitas.',
            const Color(0xFFF59E0B),
          ),

          const SizedBox(height: 24),

          // 2. Step-by-Step Flow Instructions
          const Text(
            'Panduan Alur Kerja Aplikasi',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              children: [
                _buildStepItem('1', 'Kelola Katalog', 'Tambahkan jasa servis AC di tab Profil agar pelanggan dapat melihat penawaran Anda.'),
                _buildDivider(),
                _buildStepItem('2', 'Pantau Reservasi', 'Masuk ke tab Booking untuk memproses antrean reservasi masuk secara teratur.'),
                _buildDivider(),
                _buildStepItem('3', 'Konfirmasi Status', 'Ubah status pengerjaan reservasi (Diterima / Selesai) agar pelanggan menerima notifikasi update.'),
                _buildDivider(),
                _buildStepItem('4', 'Jaga Rating', 'Berikan performa pelayanan maksimal untuk mengumpulkan ulasan bintang 5 dari pelanggan.'),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, IconData icon, String title, String description, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 11, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(String number, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: AppTheme.primaryColor,
          child: Text(
            number,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 10, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Divider(color: Colors.white.withOpacity(0.05), height: 1),
    );
  }
}
