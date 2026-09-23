import 'package:flutter/material.dart';
import 'package:skindisease/features/profile/presentation/profile_screen.dart';
import 'package:skindisease/features/scan/presentation/scan_screen.dart';
import 'package:skindisease/features/dashboard/data/weather_service.dart';
import 'package:skindisease/features/info/presentation/pages/list_disease_page.dart';
import 'package:skindisease/features/info/presentation/pages/list_virus_page.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:skindisease/features/info/data/datasources/disease_local_data.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

    IconData _getWeatherIcon(String weatherMain) {
    final w = weatherMain.toLowerCase();

    if (w.contains('clear')) {
      return Icons.wb_sunny_rounded; // ☀️ cerah
    } else if (w.contains('cloud')) {
      return Icons.cloud_rounded; // ☁️ berawan
    } else if (w.contains('rain')) {
      return Icons.umbrella_rounded; // 🌧️ hujan
    } else if (w.contains('drizzle')) {
      return Icons.grain_rounded; // 🌦️ gerimis
    } else if (w.contains('thunder')) {
      return Icons.thunderstorm_rounded; // ⛈️ petir
    } else if (w.contains('snow')) {
      return Icons.ac_unit_rounded; // ❄️ salju
    } else if (w.contains('mist') ||
        w.contains('fog') ||
        w.contains('haze') ||
        w.contains('smoke') ||
        w.contains('dust')) {
      return Icons.blur_on_rounded; // 🌫️ kabut
    } else if (w.contains('tornado') || w.contains('squall')) {
      return Icons.air_rounded; // 🌪️ angin
    }

    return Icons.cloud_rounded; // default
  }

  final WeatherService _weatherService = WeatherService();

  String _cityName = 'Surabaya, Indonesia';
  double? _temperature; // dalam °C
  String _weatherDesc = '';
  bool _isLoadingWeather = true;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
      setState(() => _isLoadingWeather = true);

      try {
        // 1) Pastikan service location aktif
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          throw Exception('Location service is disabled');
        }

        // 2) Cek permission
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
        if (permission == LocationPermission.deniedForever) {
          throw Exception('Location permission denied forever');
        }

        // 3) Ambil posisi terkini
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        // 4) Reverse geocoding -> nama kota (opsional tapi bagus)
        String city = 'Unknown location';
        try {
          final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            // contoh: "Surabaya, Indonesia"
            city = [
              if ((p.locality ?? '').isNotEmpty) p.locality,
              if ((p.country ?? '').isNotEmpty) p.country,
            ].join(', ');
          }
        } catch (_) {
          // kalau geocoding gagal, tetap lanjut pakai data weather API
        }

        // 5) Panggil weather pakai koordinat dari GPS
        final data = await _weatherService.getCurrentWeather(
          lat: pos.latitude,
          lon: pos.longitude,
        );

        setState(() {
          _temperature = (data['main']['temp'] as num).toDouble();
          _weatherDesc = (data['weather'][0]['main'] as String?) ?? '';
          // pakai hasil geocoding kalau ada, fallback ke data['name']
          _cityName = city.isNotEmpty ? city : ((data['name'] as String?) ?? _cityName);
          _isLoadingWeather = false;
        });
      } catch (e) {
        debugPrint('Error load weather: $e');
        setState(() => _isLoadingWeather = false);
      }
    }

  void _goToScan() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = const Color(0xFF2F7C4F);
    final Color softGreen = const Color(0xFFE9F5EE);

    return Scaffold(
      backgroundColor: softGreen,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(primaryGreen),
              const SizedBox(height: 16),
              _buildWeatherCard(primaryGreen),
              const SizedBox(height: 16),
              _buildCategoryChips(),
              const SizedBox(height: 16),
              _buildCheckSkinCard(primaryGreen),
              const SizedBox(height: 24),
              _buildAllFeaturesTitle(),
              const SizedBox(height: 12),
              _buildAllFeaturesGrid(primaryGreen),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _buildHeader(Color primaryGreen) {
    return SizedBox(
      height: 220,
      child: Stack(
        children: [


          // Background image + gradient
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/header_bg.png',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.65),
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          Positioned.fill(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Location info
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your location',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.redAccent,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _cityName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Profile circle
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white.withOpacity(0.9),
                        child: Icon(
                          Icons.person,
                          color: primaryGreen,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Search bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Search Article',
                              isCollapsed: true,
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- WEATHER CARD ----------------
Widget _buildWeatherCard(Color primaryGreen) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20.0),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Temperature & city
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isLoadingWeather
                      ? '--°C'
                      : '${_temperature?.toStringAsFixed(0) ?? '--'}°C',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _cityName,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _weatherDesc.isEmpty
                      ? 'Loading weather...'
                      : _weatherDesc,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Icon cuaca (DINAMIS)
          Column(
            children: [
              Icon(
                _isLoadingWeather
                    ? Icons.cloud_rounded
                    : _getWeatherIcon(_weatherDesc),
                size: 36,
                color: primaryGreen,
              ),
              const SizedBox(height: 4),
              Text(
                'Today',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          )
        ],
      ),
    ),
  );
}

  // ---------------- CATEGORY CHIPS ----------------
    Widget _buildCategoryChips() {
    final diseases = DiseaseLocalData.diseases;

    return SizedBox(
      height: 88, // sedikit lebih tinggi biar muat nama 2 baris
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: diseases.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final disease = diseases[index];

          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              // kalau mau navigate ke detail disease:
              // Navigator.push(context, MaterialPageRoute(
              //   builder: (_) => DetailDiseasePage(disease: disease),
              // ));
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset(
                      disease.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.medical_services_rounded,
                        size: 22,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 60, // biar teks tidak kepanjangan
                  child: Text(
                    disease.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------- CHECK YOUR SKIN CARD ----------------
  Widget _buildCheckSkinCard(Color primaryGreen) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/skin.png',
                width: 90,
                height: 130,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Check your Skin',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Take photos, start diagnose diseases & get skin care tips.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton(
                      onPressed: _goToScan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'Diagnose',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- ALL FEATURES TITLE ----------------
  Widget _buildAllFeaturesTitle() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'All Features',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ---------------- ALL FEATURES GRID ----------------
  Widget _buildAllFeaturesGrid(Color primaryGreen) {
    final items = [
      _FeatureItem(
        title: 'Diagnose',
        subtitle: 'Check your Disease',
        icon: Icons.analytics_rounded,
        onTap: _goToScan,
      ),
      _FeatureItem(
        title: 'Identify',
        subtitle: 'Recognize your Skin',
        icon: Icons.search_rounded,
        onTap: _goToScan,
      ),
      _FeatureItem(
        title: 'List Virus',
        subtitle: 'Optimize Monitoring for your Skin',
        icon: Icons.bug_report_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ListVirusPage()),
          );
        },
      ),
      _FeatureItem(
        title: 'List Disease',
        subtitle: 'Stay on top of your Skin care',
        icon: Icons.healing_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ListDiseasePage()),
          );
        },
      ),
    ];
  
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: GridView.builder(
        itemCount: items.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: item.onTap,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    item.icon,
                    size: 22,
                    color: primaryGreen,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FeatureItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  _FeatureItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}
