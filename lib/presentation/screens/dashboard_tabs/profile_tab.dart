import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';

class ProfileTab extends StatelessWidget {
  final String nama;
  final String email;
  final String role;
  final String phone;
  final String userAddress;
  final String fotoUrl;
  final Map<String, dynamic>? myBengkelDetails;
  final bool isBengkelLoading;
  final List<dynamic> servicesList;
  final bool isServicesLoading;
  final Future<void> Function(String nama, String deskripsi, double harga, String fotoUrl) onAddLayanan;
  final Future<void> Function(int id) onDeleteLayanan;
  final Future<void> Function(String newPhotoUrl) onUpdateWorkshopPhoto;
  final Future<void> Function(String newPhotoUrl) onUpdateUserPhoto;
  final VoidCallback onLogout;

  const ProfileTab({
    super.key,
    required this.nama,
    required this.email,
    required this.role,
    required this.phone,
    required this.userAddress,
    required this.fotoUrl,
    required this.myBengkelDetails,
    required this.isBengkelLoading,
    required this.servicesList,
    required this.isServicesLoading,
    required this.onAddLayanan,
    required this.onDeleteLayanan,
    required this.onUpdateWorkshopPhoto,
    required this.onUpdateUserPhoto,
    required this.onLogout,
  });

  void _showAddServiceDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();
    final List<String> dialogPhotos = [];
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              title: const Text(
                'Tambah Layanan / Jasa',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Nama Layanan',
                          labelStyle: TextStyle(color: AppTheme.textSecondaryColor),
                          prefixIcon: Icon(Icons.build_rounded, color: AppTheme.primaryColor),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi Layanan',
                          labelStyle: TextStyle(color: AppTheme.textSecondaryColor),
                          prefixIcon: Icon(Icons.description_outlined, color: AppTheme.primaryColor),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Deskripsi tidak boleh kosong' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: priceController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Estimasi Harga (Rp)',
                          labelStyle: TextStyle(color: AppTheme.textSecondaryColor),
                          prefixIcon: Icon(Icons.payments_outlined, color: AppTheme.primaryColor),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Harga tidak boleh kosong';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Masukkan angka nominal saja';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Photos section for laying out multiple gallery images
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Foto Jasa / Hasil Kerja',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () async {
                              final picker = ImagePicker();
                              final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                              if (image != null) {
                                final uploaded = await ApiClient().uploadImage(image.path);
                                if (uploaded != null) {
                                  setDialogState(() {
                                    dialogPhotos.add(uploaded);
                                  });
                                }
                              }
                            },
                            icon: const Icon(Icons.add_a_photo_outlined, size: 14),
                            label: const Text('GALERI', style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                      
                      if (dialogPhotos.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 60,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: dialogPhotos.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (ctx, idx) {
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      dialogPhotos[idx],
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: GestureDetector(
                                      onTap: () {
                                        setDialogState(() {
                                          dialogPhotos.removeAt(idx);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                                        child: const Icon(Icons.close, size: 10, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('BATAL', style: TextStyle(color: Colors.redAccent)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setDialogState(() => isSubmitting = true);
                            await onAddLayanan(
                              nameController.text.trim(),
                              descController.text.trim(),
                              double.parse(priceController.text.trim()),
                              dialogPhotos.join(','), // comma separated list
                            );
                            if (context.mounted) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Layanan berhasil ditambahkan!'),
                                  backgroundColor: Color(0xFF10B981),
                                ),
                              );
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('TAMBAH'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _pickImageFromGallery(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      
      if (image != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                  SizedBox(width: 16),
                  Text('Mengunggah gambar...'),
                ],
              ),
              duration: Duration(seconds: 10),
            ),
          );
        }

        final apiClient = ApiClient();
        final uploadedUrl = await apiClient.uploadImage(image.path);

        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }

        if (uploadedUrl != null) {
          await onUpdateWorkshopPhoto(uploadedUrl);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Foto sampul berhasil diperbarui dari galeri!'),
                backgroundColor: Color(0xFF10B981),
              ),
            );
          }
        } else {
          throw Exception('Gagal mengupload gambar ke server.');
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _pickUserPhotoFromGallery(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      
      if (image != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                  SizedBox(width: 16),
                  Text('Mengunggah foto profil...'),
                ],
              ),
              duration: Duration(seconds: 10),
            ),
          );
        }

        final apiClient = ApiClient();
        final uploadedUrl = await apiClient.uploadImage(image.path);

        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }

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
        } else {
          throw Exception('Gagal mengupload foto profil.');
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui foto profil: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showUpdatePhotoDialog(BuildContext context) {
    final List<String> photoTemplates = [
      'https://images.unsplash.com/photo-1486006920555-c77dce18193b?auto=format&fit=crop&q=80&w=600',
      'https://images.unsplash.com/photo-1617886322168-72b886573c35?auto=format&fit=crop&q=80&w=600',
      'https://images.unsplash.com/photo-1517524206127-48bbd363f3d7?auto=format&fit=crop&q=80&w=600',
      'https://images.unsplash.com/photo-1619642751034-765dfdf7c58e?auto=format&fit=crop&q=80&w=600',
    ];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text(
            'Ubah Foto Sampul Bengkel',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Choose custom photo from gallery button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _pickImageFromGallery(context);
                },
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('PILIH DARI GALERI HP'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFF334155), height: 1),
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Atau Pilih dari Template:',
                  style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.maxFinite,
                child: GridView.builder(
                  shrinkWrap: true,
                  itemCount: photoTemplates.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                  ),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () async {
                        Navigator.pop(dialogContext);
                        await onUpdateWorkshopPhoto(photoTemplates[index]);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Foto sampul bengkel berhasil diperbarui!'),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        }
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          photoTemplates[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('BATAL', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // User profile image (Google photo or Fallback icon) with Edit overlay
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                backgroundImage: fotoUrl.isNotEmpty ? NetworkImage(fotoUrl) : null,
                child: fotoUrl.isEmpty
                    ? const Icon(Icons.person, size: 60, color: AppTheme.primaryColor)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _pickUserPhotoFromGallery(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Beautiful Premium Workshop Cover Image with Edit Button
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  (myBengkelDetails!['foto_url'] != null && myBengkelDetails!['foto_url'].toString().isNotEmpty)
                                      ? myBengkelDetails!['foto_url']
                                      : 'https://images.unsplash.com/photo-1486006920555-c77dce18193b?auto=format&fit=crop&q=80&w=600',
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                bottom: 10,
                                right: 10,
                                child: ElevatedButton.icon(
                                  onPressed: () => _showUpdatePhotoDialog(context),
                                  icon: const Icon(Icons.photo_camera_outlined, size: 14),
                                  label: const Text('UBAH FOTO', style: TextStyle(fontSize: 10)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black.withOpacity(0.6),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildProfileItem(Icons.store_rounded, 'Nama Bengkel', myBengkelDetails!['nama'] ?? '-'),
                          _buildProfileItem(Icons.location_on_outlined, 'Alamat Bengkel', myBengkelDetails!['alamat'] ?? '-'),
                          _buildProfileItem(Icons.access_time_rounded, 'Jam Kerja', '${myBengkelDetails!['jam_buka'] ?? '-'} - ${myBengkelDetails!['jam_tutup'] ?? '-'}'),
                          _buildProfileItem(Icons.phone_outlined, 'Kontak Bengkel', myBengkelDetails!['telepon'] ?? '-'),
                          if (myBengkelDetails!['deskripsi'] != null && myBengkelDetails!['deskripsi'].toString().isNotEmpty)
                            _buildProfileItem(Icons.info_outline_rounded, 'Deskripsi', myBengkelDetails!['deskripsi']),
                        ],
                      ),
            
            const Divider(color: Color(0xFF334155), height: 40),
            
            // Layout catalog services management section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Katalog Layanan & Jasa',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                TextButton.icon(
                  onPressed: () => _showAddServiceDialog(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('TAMBAH'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            isServicesLoading
                ? const Center(child: CircularProgressIndicator())
                : servicesList.isEmpty
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            'Belum ada jasa/layanan terdaftar.',
                            style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: servicesList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = servicesList[index];
                          final int id = item['id'] as int;
                          final double price = (item['estimasi_harga'] as num?)?.toDouble() ?? 0.0;
                          
                          // Parse comma separated photo URLs
                          final String rawPhotoUrl = item['foto_url'] ?? '';
                          final List<String> serviceImages = rawPhotoUrl.isNotEmpty ? rawPhotoUrl.split(',') : [];
                          
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.construction_rounded, color: AppTheme.primaryColor, size: 20),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['nama'] ?? 'Service AC',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            item['deskripsi'] ?? '',
                                            style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Estimasi: Rp ${price.toStringAsFixed(0)}',
                                            style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            backgroundColor: const Color(0xFF1E293B),
                                            title: const Text('Hapus Layanan', style: TextStyle(color: Colors.white)),
                                            content: const Text('Apakah Anda yakin ingin menghapus layanan ini?', style: TextStyle(color: AppTheme.textSecondaryColor)),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx, false),
                                                child: const Text('BATAL', style: TextStyle(color: Colors.white)),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(ctx, true),
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                                child: const Text('HAPUS'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          await onDeleteLayanan(id);
                                        }
                                      },
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                    ),
                                  ],
                                ),
                                
                                // Dynamic multiple photo slider for service card
                                if (serviceImages.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Foto Dokumentasi Jasa:',
                                    style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 80,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: serviceImages.length,
                                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                                      itemBuilder: (ctx, imgIdx) {
                                        return ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Image.network(
                                            serviceImages[imgIdx],
                                            width: 120,
                                            height: 80,
                                            fit: BoxFit.cover,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
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
