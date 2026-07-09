import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
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
import 'manage_catalog_screen.dart';
import 'manage_bookings_screen.dart';
import 'workshop_reviews_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final ApiClient _apiClient = ApiClient();

  // Recommendations data
  List<dynamic> _allRecommendedBengkels = [];
  List<dynamic> _recommendedBengkels = [];
  bool _isRecsLoading = true;
  double _filterMaxDistance = 50.0;
  double? _filterMaxHarga; // null means no limit
  String _filterSortBy = 'rekomendasi'; // 'rekomendasi', 'jarak', 'rating', 'harga'

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
    WidgetsBinding.instance.addObserver(this);
    _loadRecommendations();
    _loadBookingHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        // Automatically check and update location every time the app is opened
        _checkAndRequestLocation();
      }
      if (user?.role == 'pengelola_bengkel') {
        _loadMyBengkelDetails();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        _checkAndRequestLocation();
      }
    }
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

  Future<void> _checkAndRequestLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _userAddress = 'Layanan lokasi tidak aktif';
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _userAddress = 'Izin lokasi ditolak';
        });
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _userAddress = 'Izin lokasi ditolak permanen';
      });
      return;
    } 

    setState(() {
      _userAddress = 'Mendeteksi lokasi GPS...';
    });

    try {
      final Position position = await Geolocator.getCurrentPosition();
      
      // Update backend
      await _apiClient.post('/user/location', {
        'latitude': position.latitude,
        'longitude': position.longitude,
      });

      // Update provider and ui
      if (mounted) {
         context.read<AuthProvider>().updateLocation(position.latitude, position.longitude);
         _fetchUserAddress(position.latitude, position.longitude);
         _loadRecommendations(); // Reload recommendations with new coordinates
      }
    } catch(e) {
      debugPrint("Failed to update location: $e");
      setState(() {
        _userAddress = 'Gagal mendeteksi lokasi';
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

  Future<void> _updateWorkshopDetails(String nama, String alamat, String deskripsi, String jamBuka, String jamTutup, String telepon) async {
    if (_myBengkelDetails == null) return;
    try {
      final response = await _apiClient.put('/bengkel', {
        'nama': nama,
        'alamat': alamat,
        'latitude': _myBengkelDetails!['latitude'],
        'longitude': _myBengkelDetails!['longitude'],
        'deskripsi': deskripsi,
        'jam_buka': jamBuka,
        'jam_tutup': jamTutup,
        'telepon': telepon,
        'status': _myBengkelDetails!['status'],
        'foto_url': _myBengkelDetails!['foto_url'],
      });
      if (response.statusCode == 200) {
        _loadMyBengkelDetails();
      } else {
        throw Exception();
      }
    } catch (e) {
      debugPrint('Failed to update workshop details: $e');
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
      final response = await _apiClient.get('/recommendations?limit=50');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          _allRecommendedBengkels = decoded['data'] ?? [];
          _isRecsLoading = false;
        });
        _applyFilters();
      } else {
        throw Exception();
      }
    } catch (e) {
      setState(() {
        _allRecommendedBengkels = [
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
      _applyFilters();
    }
  }

  void _applyFilters() {
    debugPrint('Applying filters: maxDistance=$_filterMaxDistance, sortBy=$_filterSortBy');
    debugPrint('Original bengkel count: ${_allRecommendedBengkels.length}');

    List<dynamic> filtered = _allRecommendedBengkels.where((b) {
      final double distance = (b['distance'] as num?)?.toDouble() ?? 0.0;
      final double minHarga = (b['min_harga'] as num?)?.toDouble() ?? 0.0;
      bool passDistance = distance <= _filterMaxDistance;
      bool passHarga = _filterMaxHarga == null || minHarga <= _filterMaxHarga!;

      return passDistance && passHarga;
    }).toList();

    debugPrint('Filtered count by distance: ${filtered.length}');

    if (_filterSortBy == 'jarak') {
      filtered.sort((a, b) => ((a['distance'] as num?)?.toDouble() ?? 0.0)
          .compareTo((b['distance'] as num?)?.toDouble() ?? 0.0));
    } else if (_filterSortBy == 'rating') {
      filtered.sort((a, b) => ((b['avg_rating_keseluruhan'] as num?)?.toDouble() ?? 0.0)
          .compareTo((a['avg_rating_keseluruhan'] as num?)?.toDouble() ?? 0.0));
    } else if (_filterSortBy == 'harga') {
      filtered.sort((a, b) => ((b['avg_rating_harga'] as num?)?.toDouble() ?? 0.0)
          .compareTo((a['avg_rating_harga'] as num?)?.toDouble() ?? 0.0));
    }

    setState(() {
      _recommendedBengkels = filtered.take(15).toList();
    });
    
    debugPrint('Final displayed bengkel count: ${_recommendedBengkels.length}');
  }

  void _resetFilters() {
    setState(() {
      _filterSortBy = 'rekomendasi';
      _filterMaxDistance = 50.0;
      _filterMaxHarga = null;
    });
    _applyFilters();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).padding.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filter Rekomendasi',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 24),
                  const Text('Urutkan Berdasarkan', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: [
                      ChoiceChip(
                        label: const Text('Rekomendasi'),
                        selected: _filterSortBy == 'rekomendasi',
                        onSelected: (val) {
                          if (val) setModalState(() => _filterSortBy = 'rekomendasi');
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Jarak Terdekat'),
                        selected: _filterSortBy == 'jarak',
                        onSelected: (val) {
                          if (val) setModalState(() => _filterSortBy = 'jarak');
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Rating Tertinggi'),
                        selected: _filterSortBy == 'rating',
                        onSelected: (val) {
                          if (val) setModalState(() => _filterSortBy = 'rating');
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Harga Terjangkau'),
                        selected: _filterSortBy == 'harga',
                        onSelected: (val) {
                          if (val) setModalState(() => _filterSortBy = 'harga');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Jarak Maksimal', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13)),
                      Text('${_filterMaxDistance.toInt()} km',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                    ],
                  ),
                  Slider(
                    value: _filterMaxDistance,
                    min: 5.0,
                    max: 50.0,
                    divisions: 9,
                    activeColor: AppTheme.primaryColor,
                    inactiveColor: const Color(0xFF334155),
                    onChanged: (val) {
                      setModalState(() => _filterMaxDistance = val);
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text('Batas Harga (Estimasi Terendah)', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.primaryColor.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<double?>(
                        value: _filterMaxHarga,
                        isExpanded: true,
                        dropdownColor: AppTheme.cardColor,
                        icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Semua Harga')),
                          DropdownMenuItem(value: 500000.0, child: Text('Di bawah Rp 500.000')),
                          DropdownMenuItem(value: 1000000.0, child: Text('Di bawah Rp 1.000.000')),
                          DropdownMenuItem(value: 2000000.0, child: Text('Di bawah Rp 2.000.000')),
                          DropdownMenuItem(value: 5000000.0, child: Text('Di bawah Rp 5.000.000')),
                        ],
                        onChanged: (val) {
                          setModalState(() => _filterMaxHarga = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _applyFilters();
                      },
                      child: const Text('Terapkan Filter'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _loadBookingHistory() async {
    final role = context.read<AuthProvider>().currentUser?.role;
    try {
      setState(() => _isBookingsLoading = true);
      String endpoint = role == 'pengelola_bengkel' ? '/booking/queue' : '/booking/history';
      final response = await _apiClient.get(endpoint);
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
      appBar: (_currentIndex == 0)
          ? null
          : AppBar(
              title: Text(_getAppBarTitle()),
            ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          userRole == 'Pengelola Bengkel'
              ? ManagerDashboardTab(
                  nama: userNama,
                  userFotoUrl: user?.fotoUrl ?? '',
                  myBengkelDetails: _myBengkelDetails,
                  isBengkelLoading: _isBengkelLoading,
                  servicesList: _myServices,
                  bookingHistory: _bookingHistory,
                  onViewReviews: () {
                    final int bengkelId = _myBengkelDetails?['id'] as int? ?? 1;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkshopReviewsScreen(bengkelId: bengkelId),
                      ),
                    );
                  },
                  onViewCatalog: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManageCatalogScreen(
                          servicesList: _myServices,
                          isServicesLoading: _isServicesLoading,
                          onAddLayanan: _addLayanan,
                          onDeleteLayanan: _deleteLayanan,
                          onUpdateLayanan: _updateLayanan,
                        ),
                      ),
                    ).then((_) {
                      final authProvider = context.read<AuthProvider>();
                      if (authProvider.currentUser?.role == 'pengelola_bengkel') {
                        _loadMyBengkelDetails();
                      }
                    });
                  },
                  onViewBookings: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManageBookingsScreen(),
                      ),
                    ).then((_) {
                      _loadBookingHistory();
                    });
                  },
                )
              : RecommendationsTab(
                  userNama: userNama,
                  userRole: userRole,
                  userAddress: _userAddress,
                  recommendedBengkels: _recommendedBengkels,
                  isLoading: _isRecsLoading,
                  onRefresh: () async {
                    await _checkAndRequestLocation();
                    await _loadRecommendations();
                  },
                  onFilterTap: _showFilterSheet,
                  onResetFilterTap: _resetFilters,
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
            onUpdateWorkshopDetails: _updateWorkshopDetails,
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
          final role = context.read<AuthProvider>().currentUser?.role;
          final isManager = role == 'pengelola_bengkel';

          if (index == 1) {
            _loadBookingHistory();
          } else if (index == 0) {
            if (isManager) {
              _loadMyBengkelDetails();
              _loadBookingHistory();
            } else {
              _loadRecommendations();
            }
          } else if (index == 3) {
            if (isManager) {
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
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Rekomendasi',
          ),
          BottomNavigationBarItem(
            icon: userRole == 'Pengelola Bengkel'
                ? const Icon(Icons.info_outline_rounded)
                : const Icon(Icons.assignment_outlined),
            activeIcon: userRole == 'Pengelola Bengkel'
                ? const Icon(Icons.info_rounded)
                : const Icon(Icons.assignment),
            label: userRole == 'Pengelola Bengkel' ? 'Informasi' : 'Riwayat',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none_rounded),
            activeIcon: Icon(Icons.notifications_rounded),
            label: 'Notifikasi',
          ),
          const BottomNavigationBarItem(
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
