import 'package:flutter/material.dart';
import '../../data/models/disease_model.dart';

class DetailDiseasePage extends StatefulWidget {
  final Disease disease;
  const DetailDiseasePage({super.key, required this.disease});

  @override
  State<DetailDiseasePage> createState() => _DetailDiseasePageState();
}

class _DetailDiseasePageState extends State<DetailDiseasePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF1C3D1E);
    const Color accent = Color(0xFF3A7D44);
    const Color bg = Color(0xFFF4F8F5);

    return Scaffold(
      backgroundColor: bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            // ── Hero Image ─────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: primary,
              automaticallyImplyLeading: false,
              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: _CircleIcon(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.pop(context),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      widget.disease.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFD6E8D9),
                        child: const Icon(
                          Icons.healing_rounded,
                          size: 64,
                          color: Color(0xFF3A7D44),
                        ),
                      ),
                    ),
                    // Gradient overlay
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x441C3D1E),
                            Colors.transparent,
                            Color(0xDD1C3D1E),
                          ],
                          stops: [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                    // Title at bottom
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Skin Disease',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.disease.name,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Content ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  child: Column(
                    children: [
                      // Quick info chips
                      _QuickInfoRow(disease: widget.disease),
                      const SizedBox(height: 14),

                      _DetailCard(
                        icon: Icons.info_outline_rounded,
                        iconColor: accent,
                        title: 'Penyebab',
                        content: widget.disease.reason,
                      ),
                      const SizedBox(height: 14),
                      _DetailCard(
                        icon: Icons.healing_rounded,
                        iconColor: accent,
                        title: 'Gejala',
                        content: widget.disease.symptom,
                      ),
                      const SizedBox(height: 14),
                      // Disclaimer
                      _DisclaimerBanner(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick Info Row ─────────────────────────────────────────────────────────────
class _QuickInfoRow extends StatelessWidget {
  final Disease disease;
  const _QuickInfoRow({required this.disease});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _InfoChip(
          icon: Icons.warning_amber_rounded,
          label: 'Symptom',
          color: const Color(0xFFD4880A),
          bgColor: const Color(0xFFFFF8EC),
          borderColor: const Color(0xFFE8C87A),
        ),
        const SizedBox(width: 10),
        _InfoChip(
          icon: Icons.local_hospital_outlined,
          label: 'Treatable',
          color: const Color(0xFF2D7A3A),
          bgColor: const Color(0xFFEBF6EC),
          borderColor: const Color(0xFFB8D9BC),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final Color borderColor;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Detail Card ───────────────────────────────────────────────────────────────
class _DetailCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String content;

  const _DetailCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDE9), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C3D1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 14),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.65,
              color: Color(0xFF444444),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Disclaimer Banner ─────────────────────────────────────────────────────────
class _DisclaimerBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB8D9BC), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.eco_rounded, color: Color(0xFF3A7D44), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Informasi ini bersifat edukatif. Untuk diagnosis atau penanganan medis, selalu konsultasikan dengan tenaga kesehatan profesional.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: Color(0xFF2D5E35),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Circle Icon Button ────────────────────────────────────────────────────────
class _CircleIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Icon(icon, size: 16, color: const Color(0xFF1C3D1E)),
          ),
        ),
      ),
    );
  }
}