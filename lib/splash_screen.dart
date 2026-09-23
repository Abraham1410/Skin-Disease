import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/auth'); // ganti '/main' kalau mau langsung masuk
    });
  }

  @override
  Widget build(BuildContext context) {
    // warna yang nyambung dengan logo (green + blue)
    const green1 = Color(0xFF1F4E20);
    const green2 = Color(0xFF2E7D32);
    const blue1 = Color(0xFF2D8CFF);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF2F7F3), // soft background
              Color(0xFFE9F5EE),
              Color(0xFFEAF3FF),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // glow / blob modern
              Positioned(
                top: -120,
                left: -120,
                child: _GlowBlob(color: green2.withOpacity(0.18), size: 260),
              ),
              Positioned(
                bottom: -140,
                right: -130,
                child: _GlowBlob(color: blue1.withOpacity(0.16), size: 300),
              ),

              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Card logo modern
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 30,
                              offset: const Offset(0, 14),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        child: Image.asset(
                          'assets/images/dermacare_logo.png',
                          width: 180,
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: 22),

                      Text(
                        'DermaCare',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: green1,
                          letterSpacing: 0.2,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Healthy Skin Solutions',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey.shade700,
                        ),
                      ),

                      const SizedBox(height: 26),

                      // loading modern kecil
                      SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: const AlwaysStoppedAnimation<Color>(green2),
                          backgroundColor: green2.withOpacity(0.18),
                        ),
                      ),

                      const SizedBox(height: 90),

                      Text(
                        'Scan • Learn • Care',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
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

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 120,
            spreadRadius: 40,
          ),
        ],
      ),
    );
  }
}
