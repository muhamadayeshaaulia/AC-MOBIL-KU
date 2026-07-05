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
          RecommendationsTab(
            userNama: userNama,
            userRole: userRole,
            recommendedBengkels: _recommendedBengkels,
            isLoading: _isRecsLoading,
            onRefresh: _loadRecommendations,
          ),
          BookingsTab(
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
            myBengkelDetails: _myBengkelDetails,
            isBengkelLoading: _isBengkelLoading,
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
            icon: Icon(Icons.bookmark_border_rounded),
            activeIcon: Icon(Icons.bookmark_rounded),
            label: 'Booking',
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
    switch (_currentIndex) {
      case 0:
        return 'AC MobilKu Rekomendasi';
      case 1:
        return 'Reservasi Booking';
      case 2:
        return 'Notifikasi Saya';
      case 3:
        return 'Profil Pengguna';
      default:
        return 'AC MobilKu';
    }
  }
}
