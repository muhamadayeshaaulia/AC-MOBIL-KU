import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';

class EditServiceScreen extends StatefulWidget {
  final Map<String, dynamic> service;
  final Future<void> Function(int id, String nama, String deskripsi, double harga, String fotoUrl) onUpdateLayanan;

  const EditServiceScreen({super.key, required this.service, required this.onUpdateLayanan});

  @override
  State<EditServiceScreen> createState() => _EditServiceScreenState();
}

class _EditServiceScreenState extends State<EditServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _priceController;
  final List<String> _uploadedPhotos = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    debugPrint('EditServiceScreen: editing service map data = ${widget.service}');
    _nameController = TextEditingController(text: widget.service['nama']);
    _descController = TextEditingController(text: widget.service['deskripsi']);
    final price = (widget.service['estimasi_harga'] as num?)?.toDouble() ?? 0.0;
    _priceController = TextEditingController(text: _formatRupiah(price));
    
    final String rawPhotoUrl = widget.service['foto_url'] ?? '';
    if (rawPhotoUrl.isNotEmpty) {
      _uploadedPhotos.addAll(rawPhotoUrl.split(','));
    }
  }

  String _formatRupiah(double amount) {
    final int val = amount.toInt();
    final String str = val.toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return str.replaceAllMapped(reg, (Match match) => '${match[1]}.');
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image != null) {
        setState(() => _isSubmitting = true);
        final apiClient = ApiClient();
        final uploaded = await apiClient.uploadImage(image.path);
        setState(() => _isSubmitting = false);

        if (uploaded != null) {
          setState(() {
            _uploadedPhotos.add(uploaded);
          });
        }
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengunggah foto: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final int id = widget.service['id'] as int;
      // Clean numeric formatting periods from controller text
      final cleanPriceStr = _priceController.text.replaceAll('.', '');
      await widget.onUpdateLayanan(
        id,
        _nameController.text.trim(),
        _descController.text.trim(),
        double.parse(cleanPriceStr),
        _uploadedPhotos.join(','),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Layanan berhasil diperbarui!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui layanan: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Edit Jasa & Layanan'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Informasi Jasa',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Perbarui rincian jasa servis AC mobil di katalog Anda.',
                style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
              ),
              const SizedBox(height: 32),
              
              // Name Field
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nama Jasa / Layanan',
                  labelStyle: TextStyle(color: AppTheme.textSecondaryColor),
                  prefixIcon: Icon(Icons.build_rounded, color: AppTheme.primaryColor),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 20),

              // Description Field
              TextFormField(
                controller: _descController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Detail Layanan',
                  labelStyle: TextStyle(color: AppTheme.textSecondaryColor),
                  prefixIcon: Icon(Icons.description_outlined, color: AppTheme.primaryColor),
                  alignLabelWithHint: true,
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Deskripsi tidak boleh kosong' : null,
              ),
              const SizedBox(height: 20),

              // Price Field formatted dynamically with periods
              TextFormField(
                controller: _priceController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  RupiahInputFormatter(),
                ],
                decoration: const InputDecoration(
                  labelText: 'Estimasi Harga Layanan (Rp)',
                  labelStyle: TextStyle(color: AppTheme.textSecondaryColor),
                  prefixIcon: Icon(Icons.payments_outlined, color: AppTheme.primaryColor),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Harga tidak boleh kosong';
                  }
                  final cleanStr = value.replaceAll('.', '');
                  if (double.tryParse(cleanStr) == null) {
                    return 'Masukkan nominal angka saja';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Photo Gallery Section Header
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Foto Dokumentasi Jasa',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Kelola foto hasil servis AC',
                          style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _pickPhoto,
                    icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                    label: const Text('TAMBAH FOTO'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                      foregroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppTheme.primaryColor, width: 1),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Photo Grid View
              _uploadedPhotos.isEmpty
                  ? Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo_library_outlined, color: AppTheme.textSecondaryColor, size: 36),
                            SizedBox(height: 8),
                            Text(
                              'Belum ada foto dokumentasi ditambahkan',
                              style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _uploadedPhotos.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _uploadedPhotos[index],
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _uploadedPhotos.removeAt(index);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

              const SizedBox(height: 48),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'SIMPAN PERUBAHAN',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    final String cleanText = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (cleanText.isEmpty) {
      return newValue.copyWith(text: '', selection: const TextSelection.collapsed(offset: 0));
    }

    final double value = double.parse(cleanText);
    final int val = value.toInt();
    final String str = val.toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final String formatted = str.replaceAllMapped(reg, (Match match) => '${match[1]}.');

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
