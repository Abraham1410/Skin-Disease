import 'package:flutter/material.dart';
import 'package:skindisease/features/dashboard/presentation/dashboard_screen.dart';
import 'package:skindisease/features/history/presentation/history_screen.dart';
import 'package:skindisease/features/benchmark/presentation/benchmark_screen.dart';
import 'package:skindisease/features/profile/presentation/profile_screen.dart';
import 'package:skindisease/features/scan/presentation/scan_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardScreen(),
    BenchmarkScreen(), 
    HistoryScreen(),
    ProfileScreen(),
  ];

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  void _openScan() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF2F7F3);
    const primaryGreen = Color(0xFF1F4E20);

    return Scaffold(
      backgroundColor: bg,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      // custom bottom bar + fab
      bottomNavigationBar: SizedBox(
        height: 110,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // Bottom bar shape (rounded + notch curve)
            Positioned(
              left: 18,
              right: 18,
              bottom: 14,
              child: ClipPath(
                clipper: _CurvedNotchClipper(),
                child: Container(
                  height: 78,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // left items
                        Row(
                          children: [
                            _NavItem(
                              icon: Icons.home_outlined,
                              isActive: _currentIndex == 0,
                              onTap: () => _onTabSelected(0),
                            ),
                            const SizedBox(width: 22),
                            _NavItem(
                              icon: Icons.science_outlined,
                              isActive: _currentIndex == 1,
                              onTap: () => _onTabSelected(1),
                            ),
                          ],
                        ),

                        // right items
                        Row(
                          children: [
                            _NavItem(
                              icon: Icons.history_rounded,
                              isActive: _currentIndex == 2,
                              onTap: () => _onTabSelected(2),
                            ),
                            const SizedBox(width: 22),
                            _NavItem(
                              icon: Icons.person_outline_rounded,
                              isActive: _currentIndex == 3,
                              onTap: () => _onTabSelected(3),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // FAB with glow like reference
            Positioned(
              bottom: 52,
              child: Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFA7E6A5).withOpacity(0.55),
                      blurRadius: 28,
                      spreadRadius: 2,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  onPressed: _openScan,
                  elevation: 0,
                  backgroundColor: primaryGreen,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const active = Color(0xFF1F4E20);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 46,
        height: 46,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 26,
              color: isActive ? active : Colors.grey.shade500,
            ),
            const SizedBox(height: 4),
            // active dot indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isActive ? 8 : 0,
              height: isActive ? 8 : 0,
              decoration: const BoxDecoration(
                color: active,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Clipper untuk bikin cekungan halus di tengah (mirip reference)
class _CurvedNotchClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // Mulai dari kiri atas
    path.moveTo(0, 0);

    // Garis atas sampai sebelum notch
    final centerX = size.width / 2;
    const notchWidth = 120.0;
    const notchDepth = 26.0;

    path.lineTo(centerX - notchWidth / 2, 0);

    // Kurva turun (cekungan)
    path.cubicTo(
      centerX - notchWidth / 3, 0,
      centerX - notchWidth / 3, notchDepth,
      centerX, notchDepth,
    );

    // Kurva naik lagi
    path.cubicTo(
      centerX + notchWidth / 3, notchDepth,
      centerX + notchWidth / 3, 0,
      centerX + notchWidth / 2, 0,
    );

    // Lanjut ke kanan atas
    path.lineTo(size.width, 0);

    // Sisanya rectangle bawah
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
