import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ProfileTab extends StatelessWidget {
  final String nama;
  final String email;
  final String role;
  final String phone;
  final String userAddress;
  final Map<String, dynamic>? myBengkelDetails;
  final bool isBengkelLoading;
  final VoidCallback onLogout;

  const ProfileTab({
    super.key,
    required this.nama,
    required this.email,
    required this.role,
    required this.phone,
    required this.userAddress,
    required this.myBengkelDetails,
    required this.isBengkelLoading,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 50,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: const Icon(Icons.person, size: 60, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            nama,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 8),
          // Role displayed directly under name/email
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
            ),
            child: Text(
              role.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Detail user - phone is hidden for partner role since it's redundant
          if (role != 'Pengelola Bengkel')
            _buildProfileItem(Icons.phone_android_outlined, 'Nomor Telepon', phone),
          // Workshop Detail Section for Pengelola
          if (role == 'Pengelola Bengkel') ...[
            const Divider(color: Color(0xFF334155), height: 40),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Informasi Bengkel Anda',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            isBengkelLoading
                ? const Center(child: CircularProgressIndicator())
                : myBengkelDetails == null
                    ? const Card(
                        color: AppTheme.cardColor,
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Anda belum mendaftarkan data bengkel AC.',
                            style: TextStyle(color: AppTheme.textSecondaryColor),
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          _buildProfileItem(Icons.store_rounded, 'Nama Bengkel', myBengkelDetails!['nama'] ?? '-'),
                          _buildProfileItem(Icons.location_on_outlined, 'Alamat Bengkel', myBengkelDetails!['alamat'] ?? '-'),
                          _buildProfileItem(Icons.access_time_rounded, 'Jam Kerja', '${myBengkelDetails!['jam_buka'] ?? '-'} - ${myBengkelDetails!['jam_tutup'] ?? '-'}'),
                          _buildProfileItem(Icons.phone_outlined, 'Kontak Bengkel', myBengkelDetails!['telepon'] ?? '-'),
                          if (myBengkelDetails!['deskripsi'] != null && myBengkelDetails!['deskripsi'].toString().isNotEmpty)
                            _buildProfileItem(Icons.info_outline_rounded, 'Deskripsi', myBengkelDetails!['deskripsi']),
                        ],
                      ),
          ],

          const SizedBox(height: 40),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('KELUAR AKUN'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 11)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
