import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../providers/auth_provider.dart';

class RoleSelectionScreen extends StatefulWidget {
  final GoogleSignInAccount googleAccount;
  final GoogleSignInAuthentication googleAuth;

  const RoleSelectionScreen({
    super.key,
    required this.googleAccount,
    required this.googleAuth,
  });

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  // Bengkel specific controllers
  final _bengkelNamaController = TextEditingController();
  final _bengkelAlamatController = TextEditingController();
  final _bengkelDeskripsiController = TextEditingController();
  final _bengkelJamBukaController = TextEditingController(text: '08:00');
  final _bengkelJamTutupController = TextEditingController(text: '17:00');
  final _bengkelTeleponController = TextEditingController();

  double _latitude = -6.2000;
  double _longitude = 106.8166;
  bool _gpsFetched = false;

  String _selectedRole = 'pelanggan'; // 'pelanggan' or 'pengelola_bengkel'
  bool _isSubmitting = false;

  Future<void> _fetchGPSAndAddress() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Layanan lokasi (GPS) dinonaktifkan di perangkat Anda.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Izin akses lokasi ditolak.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin lokasi ditolak permanen, silakan aktifkan lewat pengaturan.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    setState(() {
      _gpsFetched = false;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _gpsFetched = true;
      });

      // Reverse Geocoding to get Address
      List<Placemark> placemarks = await placemarkFromCoordinates(_latitude, _longitude);
      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        final String? streetAddress = (place.street != null && !place.street!.contains('+')) ? place.street : null;
        final String formattedAddress = [
          if (streetAddress != null && streetAddress.isNotEmpty) streetAddress,
          if (place.subLocality != null && place.subLocality!.isNotEmpty) place.subLocality,
          if (place.locality != null && place.locality!.isNotEmpty) place.locality,
          if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) place.subAdministrativeArea,
          if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) place.administrativeArea,
          if (place.postalCode != null && place.postalCode!.isNotEmpty) place.postalCode,
        ].join(', ');

        setState(() {
          _bengkelAlamatController.text = formattedAddress;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('GPS & Alamat berhasil dimuat: $_latitude, $_longitude'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mendeteksi lokasi: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      final authProvider = context.read<AuthProvider>();
      try {
        // 1. Authenticate with Firebase & Save User Profile to Backend Go
        final userSuccess = await authProvider.registerWithEmail(
          email: widget.googleAccount.email,
          password: 'GoogleSignInBypassSecretPassword123!', 
          name: widget.googleAccount.displayName ?? 'Google User',
          role: _selectedRole,
          phone: _phoneController.text.trim(),
        );

        if (!userSuccess) {
          throw Exception(authProvider.errorMessage ?? 'Gagal membuat akun.');
        }

        // 2. If the user registers as "Pengelola Bengkel", also create the Bengkel
        if (_selectedRole == 'pengelola_bengkel') {
          final apiClient = ApiClient();
          final response = await apiClient.post('/bengkel', {
            'nama': _bengkelNamaController.text.trim(),
            'alamat': _bengkelAlamatController.text.trim(),
            'latitude': _latitude,
            'longitude': _longitude,
            'deskripsi': _bengkelDeskripsiController.text.trim(),
            'jam_buka': _bengkelJamBukaController.text.trim(),
            'jam_tutup': _bengkelJamTutupController.text.trim(),
            'telepon': _bengkelTeleponController.text.trim(),
            'status': 'aktif',
          });

          if (response.statusCode != 201 && response.statusCode != 200) {
            // Rollback/Logout if bengkel creation failed to prevent dirty/half state
            await authProvider.logout();
            throw Exception('Gagal mendaftarkan data bengkel ke server.');
          }
        }

        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.dashboard, (route) => false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Eror: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _bengkelNamaController.dispose();
    _bengkelAlamatController.dispose();
    _bengkelDeskripsiController.dispose();
    _bengkelJamBukaController.dispose();
    _bengkelJamTutupController.dispose();
    _bengkelTeleponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Lengkapi Profil Google'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: widget.googleAccount.photoUrl != null
                      ? NetworkImage(widget.googleAccount.photoUrl!)
                      : null,
                  child: widget.googleAccount.photoUrl == null
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  'Halo, ${widget.googleAccount.displayName}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  widget.googleAccount.email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Peran Pembuat Akun
                const Text(
                  'Pilih Peran Pendaftaran',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedRole = 'pelanggan'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _selectedRole == 'pelanggan'
                                ? AppTheme.primaryColor
                                : AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedRole == 'pelanggan'
                                  ? AppTheme.primaryColor
                                  : const Color(0xFF334155),
                            ),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.directions_car_rounded, color: Colors.white),
                              SizedBox(height: 4),
                              Text(
                                'Pelanggan',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedRole = 'pengelola_bengkel'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _selectedRole == 'pengelola_bengkel'
                                ? AppTheme.primaryColor
                                : AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedRole == 'pengelola_bengkel'
                                  ? AppTheme.primaryColor
                                  : const Color(0xFF334155),
                            ),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.store_rounded, color: Colors.white),
                              SizedBox(height: 4),
                              Text(
                                'Pengelola',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Form input dasar telepon
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'Nomor Telepon WhatsApp Personal',
                    prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.textSecondaryColor),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Nomor telepon wajib diisi' : null,
                ),
                const SizedBox(height: 20),

                // Form Tambahan khusus Pengelola Bengkel
                if (_selectedRole == 'pengelola_bengkel') ...[
                  const Divider(color: Color(0xFF334155), height: 32),
                  const Text(
                    'Informasi Bengkel AC Anda',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bengkelNamaController,
                    decoration: const InputDecoration(
                      hintText: 'Nama Bengkel AC',
                      prefixIcon: Icon(Icons.store_rounded, color: AppTheme.textSecondaryColor),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Nama bengkel wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bengkelAlamatController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Alamat Lengkap Bengkel',
                      prefixIcon: Icon(Icons.location_on_outlined, color: AppTheme.textSecondaryColor),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Alamat bengkel wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bengkelDeskripsiController,
                    decoration: const InputDecoration(
                      hintText: 'Deskripsi / Layanan Utama Bengkel',
                      prefixIcon: Icon(Icons.description_outlined, color: AppTheme.textSecondaryColor),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _bengkelJamBukaController,
                          decoration: const InputDecoration(
                            hintText: 'Jam Buka (e.g. 08:00)',
                            prefixIcon: Icon(Icons.access_time, color: AppTheme.textSecondaryColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _bengkelJamTutupController,
                          decoration: const InputDecoration(
                            hintText: 'Jam Tutup (e.g. 17:00)',
                            prefixIcon: Icon(Icons.access_time_filled, color: AppTheme.textSecondaryColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bengkelTeleponController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: 'Nomor Telepon Kontak Bengkel',
                      prefixIcon: Icon(Icons.contact_phone_outlined, color: AppTheme.textSecondaryColor),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Nomor telepon kontak bengkel wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  // GPS coordinates fetcher simulation
                  InkWell(
                    onTap: _fetchGPSAndAddress,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _gpsFetched ? const Color(0xFF10B981).withOpacity(0.1) : AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _gpsFetched ? const Color(0xFF10B981) : const Color(0xFF334155),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _gpsFetched ? Icons.gps_fixed : Icons.gps_not_fixed,
                            color: _gpsFetched ? const Color(0xFF10B981) : AppTheme.textSecondaryColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _gpsFetched ? 'GPS Bengkel Terkunci' : 'Deteksi GPS Titik Bengkel',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Text(
                                  'Koordinat: ($_latitude, $_longitude)',
                                  style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          if (!_gpsFetched)
                            const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textSecondaryColor),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                
                _isSubmitting
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton(
                            onPressed: _handleSubmit,
                            child: const Text('SELESAIKAN PENDAFTARAN'),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () async {
                              await GoogleSignIn().signOut();
                              if (mounted) {
                                Navigator.pop(context); // Go back to login, cancel everything
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Colors.redAccent),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'BATALKAN',
                              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
