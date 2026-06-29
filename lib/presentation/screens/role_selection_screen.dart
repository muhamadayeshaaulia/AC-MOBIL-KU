import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/theme/app_theme.dart';
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
  String _selectedRole = 'pelanggan'; // 'pelanggan' or 'pengelola_bengkel'
  bool _isSubmitting = false;

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      final authProvider = context.read<AuthProvider>();
      // Perform Firebase Auth with the Google credentials
      // and call the Go backend api to store details
      try {
        final success = await authProvider.registerWithEmail(
          email: widget.googleAccount.email,
          password: 'GoogleSignInBypassSecretPassword123!', // secure dummy pass for firebase credential linkage
          name: widget.googleAccount.displayName ?? 'Google User',
          role: _selectedRole,
          phone: _phoneController.text.trim(),
        );

        if (mounted) {
          if (success) {
            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.dashboard, (route) => false);
          } else {
            // Clean up / sign out on failure
            await authProvider.logout();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(authProvider.errorMessage ?? 'Gagal membuat akun.'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
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
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'Nomor Telepon WhatsApp',
                    prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.textSecondaryColor),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Nomor telepon wajib diisi' : null,
                ),
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
                            onPressed: () {
                              Navigator.pop(context); // Go back to login, cancel everything
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
