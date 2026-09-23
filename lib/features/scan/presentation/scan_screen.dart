import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:skindisease/features/scan/data/tflite_predict_service.dart';
import 'package:skindisease/features/scan/presentation/result_screen.dart';
import 'package:skindisease/features/history/data/firebase_history_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  final TFLitePredictService _predictService = TFLitePredictService();
  final FirebaseHistoryService _historyService = FirebaseHistoryService();

  File? _selectedImage;
  bool _isLoading = false;
  bool _isModelLoaded = false;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _loadModel();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _predictService.close();
    super.dispose();
  }

  Future<void> _loadModel() async {
    try {
      await _predictService.loadModel();
      if (!mounted) return;
      setState(() => _isModelLoaded = true);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Gagal memuat model: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (!_isModelLoaded) {
      _showSnack('Model belum siap, tunggu sebentar...');
      return;
    }

    final picker = ImagePicker();
    final XFile? picked =
        await picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;

    setState(() => _selectedImage = File(picked.path));
    await _runPredict();
  }

  Future<void> _runPredict() async {
    if (_selectedImage == null) return;
    setState(() => _isLoading = true);

    try {
      final result = await _predictService.predict(_selectedImage!);

      await _historyService.saveHistory(
        label: result.displayName,
        confidence: result.confidence,
        imageUrl: _selectedImage!.path,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            image: _selectedImage!,
            label: result.displayName,
            confidence: result.confidence,
            description: result.description,
            prevention: result.prevention,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('Gagal prediksi: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF1C3D1E);
    const Color accent = Color(0xFF3A7D44);
    const Color bg = Color(0xFFF4F8F5);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: const Color(0xFFDDE8DE), width: 1),
                    ),
                    child: const Icon(Icons.document_scanner_outlined,
                        color: primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Skin Scanner',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: primary,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        _isModelLoaded ? 'AI model ready' : 'Loading model...',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isModelLoaded
                              ? const Color(0xFF3A7D44)
                              : const Color(0xFFD4880A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Model status dot
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isModelLoaded
                          ? const Color(0xFF3A7D44)
                          : const Color(0xFFD4880A),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Image Preview / Upload Zone ───────────────────────────
              Expanded(
                child: _selectedImage == null
                    ? _EmptyDropZone(
                        pulseAnim: _pulseAnim,
                        isModelLoaded: _isModelLoaded,
                        onCamera: () => _pickImage(ImageSource.camera),
                        onGallery: () => _pickImage(ImageSource.gallery),
                      )
                    : _ImagePreview(
                        image: _selectedImage!,
                        isLoading: _isLoading,
                        onRetake: () => setState(() => _selectedImage = null),
                      ),
              ),

              const SizedBox(height: 20),

              // ── Tips row ──────────────────────────────────────────────
              if (!_isLoading) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: const Color(0xFFDDE8DE), width: 1),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.tips_and_updates_outlined,
                          color: Color(0xFF3A7D44), size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Pastikan pencahayaan cukup dan kulit terlihat jelas untuk hasil terbaik.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF4A6B4D),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Action Buttons ──────────────────────────────────────
                if (_selectedImage == null)
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.camera_alt_rounded,
                          label: 'Kamera',
                          isPrimary: true,
                          onTap: _isLoading || !_isModelLoaded
                              ? null
                              : () => _pickImage(ImageSource.camera),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.photo_library_rounded,
                          label: 'Galeri',
                          isPrimary: false,
                          onTap: _isLoading || !_isModelLoaded
                              ? null
                              : () => _pickImage(ImageSource.gallery),
                        ),
                      ),
                    ],
                  )
                else
                  // Analyze button when image is selected
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.biotech_rounded, size: 20),
                      label: const Text(
                        'Analisis Gambar',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: _isLoading ? null : _runPredict,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty Drop Zone ───────────────────────────────────────────────────────────
class _EmptyDropZone extends StatelessWidget {
  final Animation<double> pulseAnim;
  final bool isModelLoaded;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _EmptyDropZone({
    required this.pulseAnim,
    required this.isModelLoaded,
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFCFE0D1),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Pulsing scan icon
          ScaleTransition(
            scale: pulseAnim,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ring
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF3A7D44).withOpacity(0.2),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  const Icon(
                    Icons.document_scanner_outlined,
                    size: 44,
                    color: Color(0xFF3A7D44),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Scan Your Skin',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1C3D1E),
            ),
          ),

          const SizedBox(height: 8),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Take a photo or choose from your gallery to detect skin conditions',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF7A9E82),
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Inline quick action buttons inside drop zone
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SmallActionChip(
                icon: Icons.camera_alt_rounded,
                label: 'Camera',
                onTap: onCamera,
              ),
              const SizedBox(width: 12),
              _SmallActionChip(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                onTap: onGallery,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SmallActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF0F7F1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF3A7D44)),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C3D1E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Image Preview ─────────────────────────────────────────────────────────────
class _ImagePreview extends StatelessWidget {
  final File image;
  final bool isLoading;
  final VoidCallback onRetake;

  const _ImagePreview({
    required this.image,
    required this.isLoading,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.file(image, fit: BoxFit.cover),
        ),

        // Dim overlay while loading
        if (isLoading)
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              color: Colors.black.withOpacity(0.45),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Analyzing...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Retake button (top right)
        if (!isLoading)
          Positioned(
            top: 12,
            right: 12,
            child: Material(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onRetake,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded,
                          color: Colors.white, size: 16),
                      SizedBox(width: 5),
                      Text(
                        'Retake',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Corner scan decorators (cosmetic)
        if (!isLoading) ...[
          Positioned(
            top: 12,
            left: 12,
            child: _CornerDecor(top: true, left: true),
          ),
          Positioned(
            top: 12,
            right: 60,
            child: _CornerDecor(top: true, left: false),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            child: _CornerDecor(top: false, left: true),
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: _CornerDecor(top: false, left: false),
          ),
        ],
      ],
    );
  }
}

// ── Corner Decorator ──────────────────────────────────────────────────────────
class _CornerDecor extends StatelessWidget {
  final bool top;
  final bool left;
  const _CornerDecor({required this.top, required this.left});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(
        painter: _CornerPainter(top: top, left: left),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool top;
  final bool left;
  _CornerPainter({required this.top, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double x = left ? 0 : size.width;
    final double y = top ? 0 : size.height;
    final double dx = left ? size.width * 0.6 : -size.width * 0.6;
    final double dy = top ? size.height * 0.6 : -size.height * 0.6;

    canvas.drawLine(Offset(x, y), Offset(x + dx, y), paint);
    canvas.drawLine(Offset(x, y), Offset(x, y + dy), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Action Button ─────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1C3D1E);

    if (isPrimary) {
      return SizedBox(
        height: 52,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 0,
            disabledBackgroundColor: Colors.grey.shade300,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: Icon(icon, size: 20),
          label: Text(
            label,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700),
          ),
          onPressed: onTap,
        ),
      );
    }

    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: Color(0xFF3A7D44), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700),
        ),
        onPressed: onTap,
      ),
    );
  }
}