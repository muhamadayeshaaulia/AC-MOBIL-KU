import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class AccountSettingsScreen extends StatefulWidget {
  final Map<String, dynamic>? myBengkelDetails;
  final Future<void> Function(String nama, String alamat, String deskripsi, String jamBuka, String jamTutup, String telepon)? onUpdateWorkshopDetails;

  const AccountSettingsScreen({
    super.key,
    this.myBengkelDetails,
    this.onUpdateWorkshopDetails,
  });

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // User profile inputs
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  
  // Workshop details inputs (if partner)
  late final TextEditingController _bengkelNameController;
  late final TextEditingController _bengkelAddressController;
  late final TextEditingController _bengkelDescController;
  late final TextEditingController _bengkelPhoneController;
  
  String _jamBuka = '08:00';
  String _jamTutup = '17:00';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: user?.nama ?? '');
    _phoneController = TextEditingController(text: user?.telepon ?? '');
    _latController = TextEditingController(text: (user?.latitude ?? 0.0).toString());
    _lngController = TextEditingController(text: (user?.longitude ?? 0.0).toString());

    if (widget.myBengkelDetails != null) {
      _bengkelNameController = TextEditingController(text: widget.myBengkelDetails!['nama'] ?? '');
      _bengkelAddressController = TextEditingController(text: widget.myBengkelDetails!['alamat'] ?? '');
      _bengkelDescController = TextEditingController(text: widget.myBengkelDetails!['deskripsi'] ?? '');
      _bengkelPhoneController = TextEditingController(text: widget.myBengkelDetails!['telepon'] ?? '');
      _jamBuka = widget.myBengkelDetails!['jam_buka'] ?? '08:00';
      _jamTutup = widget.myBengkelDetails!['jam_tutup'] ?? '17:00';
    } else {
      _bengkelNameController = TextEditingController();
      _bengkelAddressController = TextEditingController();
      _bengkelDescController = TextEditingController();
      _bengkelPhoneController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _bengkelNameController.dispose();
    _bengkelAddressController.dispose();
    _bengkelDescController.dispose();
    _bengkelPhoneController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    setState(() => _isSubmitting = true);

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Layanan lokasi tidak aktif.');
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin lokasi ditolak.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak permanen.');
      }

      final Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _latController.text = position.latitude.toString();
        _lngController.text = position.longitude.toString();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lokasi berhasil didapatkan!'), backgroundColor: Color(0xFF10B981)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _selectTime(BuildContext context, bool isOpenTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse((isOpenTime ? _jamBuka : _jamTutup).split(':')[0]),
        minute: int.parse((isOpenTime ? _jamBuka : _jamTutup).split(':')[1]),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: AppTheme.cardColor,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isOpenTime) {
          _jamBuka = formattedTime;
        } else {
          _jamTutup = formattedTime;
        }
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    try {
      // 1. Save personal profile
      final authProvider = context.read<AuthProvider>();
      final double? parsedLat = double.tryParse(_latController.text.trim());
      final double? parsedLng = double.tryParse(_lngController.text.trim());

      final userSuccess = await authProvider.updateUserProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        latitude: parsedLat,
        longitude: parsedLng,
      );

      if (!userSuccess) {
        throw Exception('Gagal memperbarui profil pengguna.');
      }

      // 2. Save workshop settings (if pengelola bengkel)
      if (authProvider.currentUser?.role == 'pengelola_bengkel' && widget.onUpdateWorkshopDetails != null) {
        await widget.onUpdateWorkshopDetails!(
          _bengkelNameController.text.trim(),
          _bengkelAddressController.text.trim(),
          _bengkelDescController.text.trim(),
          _jamBuka,
          _jamTutup,
          _bengkelPhoneController.text.trim(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengaturan akun berhasil disimpan!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan pengaturan: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final isPengelola = user?.role == 'pengelola_bengkel';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Pengaturan Akun'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informasi Pribadi',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // Full name field
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  labelStyle: TextStyle(color: AppTheme.textSecondaryColor),
                  prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.primaryColor),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),

              // Phone number field
              TextFormField(
                controller: _phoneController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Nomor Telepon',
                  labelStyle: TextStyle(color: AppTheme.textSecondaryColor),
                  prefixIcon: Icon(Icons.phone_android_rounded, color: AppTheme.primaryColor),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Nomor telepon tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),

              // Latitude and Longitude Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        labelStyle: TextStyle(color: AppTheme.textSecondaryColor),
                        prefixIcon: Icon(Icons.pin_drop_outlined, color: AppTheme.primaryColor),
                      ),
                      validator: (value) => value != null && double.tryParse(value) == null ? 'Invalid' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _lngController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        labelStyle: TextStyle(color: AppTheme.textSecondaryColor),
                        prefixIcon: Icon(Icons.pin_drop_outlined, color: AppTheme.primaryColor),
                      ),
                      validator: (value) => value != null && double.tryParse(value) == null ? 'Invalid' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isSubmitting ? null : _getCurrentLocation,
                  icon: const Icon(Icons.my_location_rounded, size: 18),
                  label: const Text('Isi Lokasi Otomatis (GPS)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              
              if (isPengelola) ...[
                const SizedBox(height: 32),
                const Text(
                  'Informasi Bengkel',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Workshop Name field
                TextFormField(
                  controller: _bengkelNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Nama Bengkel AC',
                    labelStyle: TextStyle(color: AppTheme.textSecondaryColor),
                    prefixIcon: Icon(Icons.storefront_outlined, color: AppTheme.primaryColor),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Nama bengkel tidak boleh kosong' : null,
                ),
                const SizedBox(height: 16),

                // Workshop Address field
                TextFormField(
                  controller: _bengkelAddressController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Alamat Lengkap Bengkel',
                    labelStyle: TextStyle(color: AppTheme.textSecondaryColor),
                    prefixIcon: Icon(Icons.location_on_outlined, color: AppTheme.primaryColor),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Alamat bengkel tidak boleh kosong' : null,
                ),
                const SizedBox(height: 16),

                // Workshop Description field
                TextFormField(
                  controller: _bengkelDescController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi Singkat Bengkel',
                    labelStyle: TextStyle(color: AppTheme.textSecondaryColor),
                    prefixIcon: Icon(Icons.info_outline_rounded, color: AppTheme.primaryColor),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),

                // Workshop Phone field
                TextFormField(
                  controller: _bengkelPhoneController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'No. Telepon Operasional Bengkel',
                    labelStyle: TextStyle(color: AppTheme.textSecondaryColor),
                    prefixIcon: Icon(Icons.contact_phone_outlined, color: AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(height: 20),

                // Operational Hours (Jam Buka - Tutup) inputs
                const Text('Jam Kerja Operasional:', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectTime(context, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Buka: $_jamBuka', style: const TextStyle(color: Colors.white, fontSize: 13)),
                              const Icon(Icons.access_time_rounded, color: AppTheme.primaryColor, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectTime(context, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Tutup: $_jamTutup', style: const TextStyle(color: Colors.white, fontSize: 13)),
                              const Icon(Icons.access_time_rounded, color: AppTheme.primaryColor, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 48),

              // Submit Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _saveSettings,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'SIMPAN PENGATURAN',
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
