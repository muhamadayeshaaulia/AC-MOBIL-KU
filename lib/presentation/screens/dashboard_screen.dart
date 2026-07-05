import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
    _loadBookingHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user?.role == 'pengelola_bengkel') {
        _loadMyBengkelDetails();
      }
    });
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
        actions: [
          if (_currentIndex == 3)
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              onPressed: _handleLogout,
            ),
        ],
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
