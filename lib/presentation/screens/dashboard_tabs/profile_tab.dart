import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../account_settings_screen.dart';

class ProfileTab extends StatelessWidget {
  final String nama;
  final String email;
  final String role;
  final String phone;
  final String userAddress;
  final String fotoUrl;
  final String createdAt;
  final Map<String, dynamic>? myBengkelDetails;
  final bool isBengkelLoading;
  final List<dynamic> servicesList;
  final bool isServicesLoading;
  final Future<void> Function(String nama, String deskripsi, double harga, String fotoUrl) onAddLayanan;
  final Future<void> Function(int id) onDeleteLayanan;
  final Future<void> Function(int id, String nama, String deskripsi, double harga, String fotoUrl) onUpdateLayanan;
  final Future<void> Function(String newPhotoUrl) onUpdateWorkshopPhoto;
  final Future<void> Function(String newPhotoUrl) onUpdateUserPhoto;
  final Future<void> Function(String nama, String alamat, String deskripsi, String jamBuka, String jamTutup, String telepon) onUpdateWorkshopDetails;
  final VoidCallback onLogout;

  const ProfileTab({
    super.key,
    required this.nama,
    required this.email,
    required this.role,
    required this.phone,
    required this.userAddress,
    required this.fotoUrl,
    required this.createdAt,
    required this.myBengkelDetails,
    required this.isBengkelLoading,
    required this.servicesList,
    required this.isServicesLoading,
    required this.onAddLayanan,
    required this.onDeleteLayanan,
    required this.onUpdateLayanan,
    required this.onUpdateWorkshopPhoto,
    required this.onUpdateUserPhoto,
    required this.onUpdateWorkshopDetails,
    required this.onLogout,
  });

  Future<void> _pickImageFromGallery(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      
      if (image != null) {
        final ApiClient apiClient = ApiClient();
        final String? uploadedUrl = await apiClient.uploadImage(image.path);
        
        if (uploadedUrl != null) {
          await onUpdateUserPhoto(uploadedUrl);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Foto profil berhasil diperbarui!'),
                backgroundColor: Color(0xFF10B981),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui foto profil: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _pickWorkshopCover(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      
      if (image != null) {
        final ApiClient apiClient = ApiClient();
        final String? uploadedUrl = await apiClient.uploadImage(image.path);
        
        if (uploadedUrl != null) {
          await onUpdateWorkshopPhoto(uploadedUrl);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Foto bengkel berhasil diperbarui!'),
                backgroundColor: Color(0xFF10B981),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui foto bengkel: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  String _formatRupiah(double amount) {
    final int val = amount.toInt();
    final String str = val.toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return str.replaceAllMapped(reg, (Match match) => '${match[1]}.');
  }

  String _formatJoinDate(String isoStr) {
    if (isoStr.isEmpty) return 'Baru saja';
    try {
      final dt = DateTime.parse(isoStr).toLocal();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (e) {
      return isoStr.split('T').first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String displayAvatar = fotoUrl.isNotEmpty 
        ? fotoUrl 
        : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&q=80&w=200';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Profile Card Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                // Avatar with gallery picker tap action
                GestureDetector(
                  onTap: () => _pickImageFromGallery(context),
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 36,
                          backgroundImage: NetworkImage(displayAvatar),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nama,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        role,
                        style: const TextStyle(color: AppTheme.primaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bergabung sejak: ${_formatJoinDate(createdAt)}',
                        style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // User Details List section
          const Text(
            'Informasi Pengguna',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),
          
          _buildProfileItem(Icons.email_outlined, 'Alamat Email', email),
          _buildProfileItem(Icons.phone_android_rounded, 'Nomor Telepon', phone.isNotEmpty ? phone : '-'),
          
          if (role == 'Pengelola Bengkel') ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Informasi Bengkel Kelolaan',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                TextButton.icon(
                  onPressed: () => _pickWorkshopCover(context),
                  icon: const Icon(Icons.photo_library_outlined, size: 16),
                  label: const Text('Cover'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            isBengkelLoading
                ? const Center(child: CircularProgressIndicator())
                : myBengkelDetails == null
                    ? Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            'Belum terdaftar sebagai pengelola bengkel.',
                            style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          // Cover photo bengkel with tap-to-change button
                          GestureDetector(
                            onTap: () => _pickWorkshopCover(context),
                            child: Container(
                              width: double.infinity,
                              height: 160,
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withOpacity(0.08)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    (myBengkelDetails!['foto_url'] != null && myBengkelDetails!['foto_url'].toString().isNotEmpty)
                                        ? Image.network(
                                            myBengkelDetails!['foto_url'],
                                            fit: BoxFit.cover,
                                            errorBuilder: (ctx, err, _) => Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: const [
                                                  Icon(Icons.broken_image_outlined, color: Colors.white24, size: 40),
                                                  SizedBox(height: 8),
                                                  Text('Gagal memuat gambar', style: TextStyle(color: Colors.white24, fontSize: 11)),
                                                ],
                                              ),
                                            ),
                                          )
                                        : Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: const [
                                              Icon(Icons.add_photo_alternate_outlined, color: Colors.white24, size: 40),
                                              SizedBox(height: 8),
                                              Text('Ketuk untuk tambahkan foto cover', style: TextStyle(color: Colors.white24, fontSize: 12)),
                                            ],
                                          ),
                                    // Dark overlay with camera icon on top of the image
                                    Positioned(
                                      bottom: 8,
                                      right: 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.55),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                                            SizedBox(width: 4),
                                            Text('Ganti Foto Cover', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          _buildProfileItem(Icons.storefront_outlined, 'Nama Bengkel', myBengkelDetails!['nama'] ?? '-'),
                          _buildProfileItem(Icons.location_on_outlined, 'Alamat Bengkel', myBengkelDetails!['alamat'] ?? '-'),
                          // Tombol dapatkan arah ke bengkel via Google Maps
                          Builder(builder: (context) {
                            final double? lat = (myBengkelDetails!['latitude'] as num?)?.toDouble();
                            final double? lng = (myBengkelDetails!['longitude'] as num?)?.toDouble();
                            if (lat == null || lng == null || (lat == 0.0 && lng == 0.0)) {
                              return const SizedBox.shrink();
                            }
                            return GestureDetector(
                              onTap: () async {
                                final String bengkelNama = Uri.encodeComponent(myBengkelDetails!['nama'] ?? 'Bengkel');
                                // Gunakan Google Maps intent URL, fallback ke browser jika app tidak ada
                                final Uri mapsUri = Uri.parse(
                                  'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$bengkelNama&travelmode=driving',
                                );
                                if (await canLaunchUrl(mapsUri)) {
                                  await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A3A2A),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                                ),
                                child: Row(children: [
                                  const Icon(Icons.directions_rounded, color: Color(0xFF10B981), size: 22),
                                  const SizedBox(width: 16),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Dapatkan Arah', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                        SizedBox(height: 2),
                                        Text('Buka Google Maps untuk navigasi ke bengkel', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.open_in_new_rounded, color: Color(0xFF10B981), size: 18),
                                ]),
                              ),
                            );
                          }),
                          _buildProfileItem(Icons.access_time_rounded, 'Jam Kerja', '${myBengkelDetails!['jam_buka'] ?? '-'} - ${myBengkelDetails!['jam_tutup'] ?? '-'}'),
                          if (myBengkelDetails!['deskripsi'] != null && myBengkelDetails!['deskripsi'].toString().isNotEmpty)
                            _buildProfileItem(Icons.info_outline_rounded, 'Deskripsi', myBengkelDetails!['deskripsi']),
                        ],
                      ),
          ],

          const SizedBox(height: 32),

          // Account Settings Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AccountSettingsScreen(
                      myBengkelDetails: myBengkelDetails,
                      onUpdateWorkshopDetails: onUpdateWorkshopDetails,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.settings_suggest_rounded),
              label: const Text('PENGATURAN AKUN'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.cardColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white.withOpacity(0.05)),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),
          
          // Logout Button
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
