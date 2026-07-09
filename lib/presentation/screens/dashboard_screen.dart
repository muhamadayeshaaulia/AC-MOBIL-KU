import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import '../../core/theme/app_theme.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/network/api_client.dart';
import '../providers/auth_provider.dart';

// Import Tabs
import 'dashboard_tabs/recommendations_tab.dart';
import 'dashboard_tabs/bookings_tab.dart';
import 'dashboard_tabs/notifications_tab.dart';
import 'dashboard_tabs/profile_tab.dart';
import 'dashboard_tabs/manager_dashboard_tab.dart';
import 'dashboard_tabs/manager_info_tab.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final ApiClient _apiClient = ApiClient();

  // Recommendations data
  List<dynamic> _recommendedBengkels = [];
  bool _isRecsLoading = true;

  // Bookings data
  List<dynamic> _bookingHistory = [];
  bool _isBookingsLoading = true;

  // Bengkel details for Pengelola role
  Map<String, dynamic>? _myBengkelDetails;
  bool _isBengkelLoading = false;

  // Resolved user address from coords
  String _userAddress = 'Mendeteksi alamat...';

  // Services catalog list for manager
  List<dynamic> _myServices = [];
  bool _isServicesLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
    _loadBookingHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null && user.latitude != 0.0) {
        _fetchUserAddress(user.latitude, user.longitude);
      } else {
        setState(() {
          _userAddress = 'Lokasi belum diatur (0.0, 0.0)';
        });
      }
      if (user?.role == 'pengelola_bengkel') {
        _loadMyBengkelDetails();
      }
    });
  }

  Future<void> _fetchUserAddress(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        final String? streetAddress = (place.street != null && !place.street!.contains('+')) ? place.street : null;
        final String formattedAddress = [
          if (streetAddress != null && streetAddress.isNotEmpty) streetAddress,
          if (place.subLocality != null && place.subLocality!.isNotEmpty) place.subLocality,
          if (place.locality != null && place.locality!.isNotEmpty) place.locality,
          if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) place.administrativeArea,
        ].join(', ');
        setState(() {
          _userAddress = formattedAddress;
        });
      }
    } catch (e) {
      setState(() {
        _userAddress = 'Lat: $lat, Lng: $lng';
      });
    }
  }

  Future<void> _loadMyBengkelDetails() async {
    try {
      setState(() => _isBengkelLoading = true);
      final response = await _apiClient.get('/bengkel/my');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          _myBengkelDetails = decoded['data'];
          _isBengkelLoading = false;
        });

        // Use the bengkel's registered location coordinates for the geocoded address
        if (_myBengkelDetails != null) {
          final double bLat = (_myBengkelDetails!['latitude'] as num?)?.toDouble() ?? 0.0;
          final double bLng = (_myBengkelDetails!['longitude'] as num?)?.toDouble() ?? 0.0;
          if (bLat != 0.0 && bLng != 0.0) {
            _fetchUserAddress(bLat, bLng);
          }
          // Fetch services catalog
          final int? bId = _myBengkelDetails!['id'] as int?;
          if (bId != null) {
            _loadMyServices(bId);
          }
        }
      } else {
        throw Exception();
      }
    } catch (e) {
      setState(() {
        _isBengkelLoading = false;
      });
      debugPrint('Failed to load my bengkel details: $e');
    }
  }

  Future<void> _loadMyServices(int bengkelId) async {
    try {
      setState(() => _isServicesLoading = true);
      final response = await _apiClient.get('/layanan/bengkel/$bengkelId');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          _myServices = decoded['data'] ?? [];
          _isServicesLoading = false;
        });
      } else {
        throw Exception();
      }
    } catch (e) {
      setState(() {
        _isServicesLoading = false;
      });
      debugPrint('Failed to load services catalog: $e');
    }
  }

  Future<void> _addLayanan(String nama, String deskripsi, double harga, String fotoUrl) async {
    if (_myBengkelDetails == null) return;
    try {
      final response = await _apiClient.post('/layanan', {
        'bengkel_id': _myBengkelDetails!['id'],
        'nama': nama,
        'deskripsi': deskripsi,
        'estimasi_harga': harga,
        'status': 'tersedia',
        'foto_url': fotoUrl,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        _loadMyServices(_myBengkelDetails!['id']);
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      debugPrint('Failed to add service: $e');
    }
  }

  Future<void> _deleteLayanan(int id) async {
    if (_myBengkelDetails == null) return;
    try {
      final response = await _apiClient.delete('/layanan/$id');
      if (response.statusCode == 200) {
        _loadMyServices(_myBengkelDetails!['id']);
      } else {
        throw Exception();
      }
    } catch (e) {
      debugPrint('Failed to delete service: $e');
    }
  }

  Future<void> _updateLayanan(int id, String nama, String deskripsi, double harga, String fotoUrl) async {
    if (_myBengkelDetails == null) return;
    try {
      final response = await _apiClient.put('/layanan/$id', {
        'bengkel_id': _myBengkelDetails!['id'],
        'nama': nama,
        'deskripsi': deskripsi,
        'estimasi_harga': harga,
        'status': 'tersedia',
        'foto_url': fotoUrl,
      });
      if (response.statusCode == 200) {
        _loadMyServices(_myBengkelDetails!['id']);
      } else {
        throw Exception();
      }
    } catch (e) {
      debugPrint('Failed to update service: $e');
    }
  }

  Future<void> _updateWorkshopPhoto(String url) async {
    if (_myBengkelDetails == null) return;
    try {
      final response = await _apiClient.put('/bengkel', {
        'nama': _myBengkelDetails!['nama'],
        'alamat': _myBengkelDetails!['alamat'],
        'latitude': _myBengkelDetails!['latitude'],
        'longitude': _myBengkelDetails!['longitude'],
        'deskripsi': _myBengkelDetails!['deskripsi'],
        'jam_buka': _myBengkelDetails!['jam_buka'],
        'jam_tutup': _myBengkelDetails!['jam_tutup'],
        'telepon': _myBengkelDetails!['telepon'],
        'status': _myBengkelDetails!['status'],
        'foto_url': url,
      });
      if (response.statusCode == 200) {
        _loadMyBengkelDetails();
      } else {
        throw Exception();
      }
    } catch (e) {
      debugPrint('Failed to update workshop cover: $e');
    }
  }

  Future<void> _updateUserPhoto(String url) async {
    try {
      final success = await context.read<AuthProvider>().updateUserPhoto(url);
      if (success) {
        debugPrint('Personal avatar updated successfully!');
      } else {
        throw Exception();
      }
    } catch (e) {
      debugPrint('Failed to update user avatar: $e');
    }
  }

  Future<void> _loadRecommendations() async {
    try {
      setState(() => _isRecsLoading = true);
      final response = await _apiClient.get('/recommendations?limit=5');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          _recommendedBengkels = decoded['data'] ?? [];
          _isRecsLoading = false;
        });
      } else {
        throw Exception();
      }
    } catch (e) {
      setState(() {
        _recommendedBengkels = [
          {
            'nama': 'AC Jaya Abadi Sentosa (Demo)',
            'alamat': 'Jl. Daan Mogot Raya No.24, Jakarta Barat',
            'distance': 2.4,
            'avg_rating_keseluruhan': 4.8,
            'status': 'aktif',
          },
          {
            'nama': 'Bengkel AC Mobil Dingin Jaya (Demo)',
            'alamat': 'Jl. Kebon Jeruk Indah No.10, Jakarta Barat',
            'distance': 5.1,
            'avg_rating_keseluruhan': 4.6,
            'status': 'aktif',
          },
        ];
        _isRecsLoading = false;
      });
    }
  }

  Future<void> _loadBookingHistory() async {
    try {
      setState(() => _isBookingsLoading = true);
      final response = await _apiClient.get('/booking/history');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          _bookingHistory = decoded['data'] ?? [];
          _isBookingsLoading = false;
        });
      } else {
        throw Exception();
      }
    } catch (e) {
      setState(() {
        _bookingHistory = [
          {
            'id': 101,
            'bengkel': {'nama': 'AC Jaya Abadi Sentosa'},
            'tanggal': '2026-07-06T10:00:00Z',
            'status': 'selesai',
            'total_biaya': 350000,
            'keluhan': 'AC kurang dingin dan bau apek',
          },
          {
            'id': 102,
            'bengkel': {'nama': 'Bengkel AC Mobil Dingin Jaya'},
            'tanggal': '2026-07-08T14:30:00Z',
            'status': 'diterima',
            'total_biaya': 150000,
            'keluhan': 'Tambah Freon R134a',
          }
        ];
        _isBookingsLoading = false;
      });
    }
  }

  void _handleLogout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final String userNama = user?.nama ?? 'Dimas Prasetyo';
    final String userEmail = user?.email ?? 'dimas@example.com';
    final String userRole = user?.role == 'pengelola_bengkel' ? 'Pengelola Bengkel' : 'Pelanggan';
    final String userPhone = user?.telepon ?? '0812-3456-7890';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          userRole == 'Pengelola Bengkel'
              ? ManagerDashboardTab(
                  nama: userNama,
                  myBengkelDetails: _myBengkelDetails,
                  isBengkelLoading: _isBengkelLoading,
                  servicesList: _myServices,
                  bookingHistory: _bookingHistory,
                  onAddLayanan: _addLayanan,
                  onViewCatalog: () {
                    setState(() => _currentIndex = 3);
                  },
                  onViewBookings: () {
                    setState(() => _currentIndex = 1);
                  },
                  onViewProfile: () {
                    setState(() => _currentIndex = 3);
                  },
                )
              : RecommendationsTab(
                  userNama: userNama,
                  userRole: userRole,
                  recommendedBengkels: _recommendedBengkels,
                  isLoading: _isRecsLoading,
                  onRefresh: _loadRecommendations,
                ),
          userRole == 'Pengelola Bengkel'
              ? const ManagerInfoTab()
              : BookingsTab(
                  bookingHistory: _bookingHistory,
                  isLoading: _isBookingsLoading,
                  onRefresh: _loadBookingHistory,
                ),
          const NotificationsTab(),
          ProfileTab(
            nama: userNama,
            email: userEmail,
            role: userRole,
            phone: userPhone,
            userAddress: _userAddress,
            fotoUrl: user?.fotoUrl ?? '',
            myBengkelDetails: _myBengkelDetails,
            isBengkelLoading: _isBengkelLoading,
            servicesList: _myServices,
            isServicesLoading: _isServicesLoading,
            onAddLayanan: _addLayanan,
            onDeleteLayanan: _deleteLayanan,
            onUpdateLayanan: _updateLayanan,
            onUpdateWorkshopPhoto: _updateWorkshopPhoto,
            onUpdateUserPhoto: _updateUserPhoto,
            onLogout: _handleLogout,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 1) {
            _loadBookingHistory();
          } else if (index == 0) {
            _loadRecommendations();
          } else if (index == 3) {
            final authProvider = context.read<AuthProvider>();
            if (authProvider.currentUser?.role == 'pengelola_bengkel') {
              _loadMyBengkelDetails();
            }
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.cardColor,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondaryColor,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Rekomendasi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline_rounded),
            activeIcon: Icon(Icons.info_rounded),
            label: 'Informasi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none_rounded),
            activeIcon: Icon(Icons.notifications_rounded),
            label: 'Notifikasi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    final user = context.read<AuthProvider>().currentUser;
    final isPengelola = user?.role == 'pengelola_bengkel';
    switch (_currentIndex) {
      case 0:
        return isPengelola ? 'Dashboard Bengkel' : 'AC MobilKu Rekomendasi';
      case 1:
        return isPengelola ? 'Aturan & Panduan Mitra' : 'Reservasi Booking';
      case 2:
        return 'Notifikasi Saya';
      case 3:
        return 'Profil Pengguna';
      default:
        return 'AC MobilKu';
    }
  }
}
