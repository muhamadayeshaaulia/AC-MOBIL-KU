import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'add_service_screen.dart';
import 'edit_service_screen.dart';

class ManageCatalogScreen extends StatelessWidget {
  final List<dynamic> servicesList;
  final bool isServicesLoading;
  final Future<void> Function(String nama, String deskripsi, double harga, String fotoUrl) onAddLayanan;
  final Future<void> Function(int id) onDeleteLayanan;
  final Future<void> Function(int id, String nama, String deskripsi, double harga, String fotoUrl) onUpdateLayanan;

  const ManageCatalogScreen({
    super.key,
    required this.servicesList,
    required this.isServicesLoading,
    required this.onAddLayanan,
    required this.onDeleteLayanan,
    required this.onUpdateLayanan,
  });

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
        title: const Text('Kelola Katalog Jasa'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddServiceScreen(
                    onAddLayanan: onAddLayanan,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryColor),
          ),
        ],
      ),
      body: isServicesLoading
          ? const Center(child: CircularProgressIndicator())
          : servicesList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.construction_rounded, color: Colors.white24, size: 64),
                      const SizedBox(height: 16),
                      const Text(
                        'Katalog Jasa Kosong',
                        style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tambahkan jasa servis AC pertama Anda.',
                        style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddServiceScreen(
                                onAddLayanan: onAddLayanan,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('TAMBAH JASA'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24.0),
                  itemCount: servicesList.length,
                  itemBuilder: (context, index) {
                    final item = servicesList[index];
                    final price = (item['estimasi_harga'] as num?)?.toDouble() ?? 0.0;
                    
                    final String rawPhotoUrl = item['foto_url'] ?? '';
                    final List<String> serviceImages = rawPhotoUrl.isNotEmpty ? rawPhotoUrl.split(',') : [];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Row(
                        children: [
                          // Service Image Thumbnail
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: serviceImages.isNotEmpty
                                ? Image.network(
                                    serviceImages.first,
                                    width: 76,
                                    height: 76,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 76,
                                    height: 76,
                                    color: Colors.white.withOpacity(0.05),
                                    child: const Icon(Icons.image_not_supported_outlined, color: Colors.white24),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['nama'] ?? 'Servis AC',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['deskripsi'] ?? '',
                                  style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 11),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Estimasi: Rp ${_formatRupiah(price)}',
                                  style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Edit & Delete Action Panel
                          Column(
                            children: [
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(8),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditServiceScreen(
                                        service: item,
                                        onUpdateLayanan: onUpdateLayanan,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor, size: 20),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(8),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: AppTheme.cardColor,
                                      title: const Text('Hapus Jasa?', style: TextStyle(color: Colors.white)),
                                      content: const Text(
                                        'Apakah Anda yakin ingin menghapus jasa ini dari katalog?',
                                        style: TextStyle(color: AppTheme.textSecondaryColor),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Batal'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                          child: const Text('Hapus'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await onDeleteLayanan(item['id'] as int);
                                  }
                                },
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
