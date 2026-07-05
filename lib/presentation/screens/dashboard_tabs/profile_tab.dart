import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

class ProfileTab extends StatelessWidget {
  final String nama;
  final String email;
  final String role;
  final String phone;
  final String userAddress;
  final Map<String, dynamic>? myBengkelDetails;
  final bool isBengkelLoading;
  final List<dynamic> servicesList;
  final bool isServicesLoading;
  final Future<void> Function(String nama, String deskripsi, double harga) onAddLayanan;
  final Future<void> Function(int id) onDeleteLayanan;
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
    required this.servicesList,
    required this.isServicesLoading,
    required this.onAddLayanan,
    required this.onDeleteLayanan,
    required this.onLogout,
  });

  void _showAddServiceDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();
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
                          
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
                            ),
                            child: Row(
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
