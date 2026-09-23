import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:skindisease/features/benchmark/data/benchmark_models.dart';
import 'package:skindisease/features/benchmark/data/benchmark_service.dart';

// ══════════════════════════════════════════════════════════════════════════════
// MODEL CONFIGURATION
// ══════════════════════════════════════════════════════════════════════════════

/// Konfigurasi untuk setiap model yang akan di-benchmark.
class ModelConfig {
  final String name;
  final String shortName;
  final String float32Path;
  final String int8Path;
  final Color color;

  const ModelConfig({
    required this.name,
    required this.shortName,
    required this.float32Path,
    required this.int8Path,
    required this.color,
  });
}

/// Menyimpan seluruh hasil benchmark untuk satu model.
class ModelBenchmarkResults {
  InferenceTimingReport? timingReport;
  AccuracyReport? accuracyReport;
  CpuStressReport? cpuReport;
  MemoryUsageReport? memoryReport;
  ModelSizeReport? modelSizeReport;

  bool get hasAnyResult =>
      timingReport != null ||
      accuracyReport != null ||
      cpuReport != null ||
      memoryReport != null ||
      modelSizeReport != null;
}

// ══════════════════════════════════════════════════════════════════════════════
// BENCHMARK SCREEN
// ══════════════════════════════════════════════════════════════════════════════

/// Screen utama Benchmark On-Device Inference.
///
/// Mengimplementasikan seluruh skenario uji coba Tabel 3.24 untuk
/// dua model: MobileNetV3-Large dan EfficientNet-Lite0.
class BenchmarkScreen extends StatefulWidget {
  const BenchmarkScreen({super.key});

  @override
  State<BenchmarkScreen> createState() => _BenchmarkScreenState();
}

class _BenchmarkScreenState extends State<BenchmarkScreen> {
  final BenchmarkService _benchmarkService = BenchmarkService();
  final ScrollController _scrollController = ScrollController();

  // ─── Model Configs ────────────────────────────────────────────────────
  static const List<ModelConfig> _models = [
    ModelConfig(
      name: 'MobileNetV3-Large',
      shortName: 'MobileNetV3',
      float32Path:
          'assets/models/skin_disease_mobilenetv3large_float32.tflite',
      int8Path: 'assets/models/skin_disease_mobilenetv3large_int8.tflite',
      color: Color(0xFF1565C0),
    ),
    ModelConfig(
      name: 'EfficientNet-Lite0',
      shortName: 'EfficientNet',
      float32Path:
          'assets/models/skin_disease_efficientnetlite0_float32.tflite',
      int8Path: 'assets/models/skin_disease_efficientnetlite0_int8.tflite',
      color: Color(0xFF2E7D32),
    ),
  ];

  // ─── State ──────────────────────────────────────────────────────────────
  bool _isRunning = false;
  String _currentStatus = '';
  double _progress = 0.0;
  int _currentScenario = 0;
  int _selectedModelIndex = 0;

  // Test images: File → Ground Truth Label
  final Map<File, String> _testImages = {};
  bool _testImagesLoaded = false;

  // Results per model
  final Map<int, ModelBenchmarkResults> _results = {
    0: ModelBenchmarkResults(),
    1: ModelBenchmarkResults(),
  };

  // Log entries untuk tampilan real-time
  final List<String> _logEntries = [];

  ModelConfig get _selectedModel => _models[_selectedModelIndex];
  ModelBenchmarkResults get _currentResults => _results[_selectedModelIndex]!;

  @override
  void initState() {
    super.initState();
    _benchmarkService.onProgress = (msg, progress) {
      if (mounted) {
        setState(() {
          _currentStatus = msg;
          _progress = progress;
        });
      }
    };
  }

  @override
  void dispose() {
    _benchmarkService.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOAD TEST IMAGES
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _loadTestImagesFromFolder() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Pilih folder citra uji (berisi subfolder per kelas)',
    );
    if (result == null) return;
    await _loadImagesFromDirectory(Directory(result));
  }

  Future<void> _loadFromDefaultPath() async {
    // Cek SEMUA path, lalu pilih yang punya JUMLAH KELAS TERBANYAK
    // (bukan cuma yang pertama ketemu)
    final possiblePaths = [
      '/storage/emulated/0/Download/test_set',          // ← prioritaskan ini
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Android/data/com.example.skindisease/files/test_set',
    ];

    Directory? bestDir;
    int bestClassCount = 0;

    for (final path in possiblePaths) {
      final dir = Directory(path);
      if (!await dir.exists()) continue;

      final subDirs = dir.listSync().whereType<Directory>().toList();
      if (subDirs.isEmpty) continue;

      // Hitung berapa subfolder yang BENAR-BENAR punya gambar
      int classCountWithImages = 0;
      for (final sub in subDirs) {
        final hasImages = sub
            .listSync()
            .whereType<File>()
            .any((f) =>
                f.path.toLowerCase().endsWith('.jpg') ||
                f.path.toLowerCase().endsWith('.jpeg') ||
                f.path.toLowerCase().endsWith('.png'));
        if (hasImages) classCountWithImages++;
      }

      _addLog('🔍 Cek $path → $classCountWithImages kelas dengan gambar');

      // Simpan folder dengan jumlah kelas TERBANYAK
      if (classCountWithImages > bestClassCount) {
        bestClassCount = classCountWithImages;
        bestDir = dir;
      }
    }

    if (bestDir == null) {
      _showSnack(
        'Folder tidak ditemukan. Pastikan citra uji ada di '
        'Download/test_set/',
      );
      _addLog('❌ Tidak menemukan folder citra uji di path manapun');
      return;
    }

    _addLog('📂 Folder terpilih: ${bestDir.path} ($bestClassCount kelas)');
    await _loadImagesFromDirectory(bestDir);
  }

  Future<void> _loadImagesFromDirectory(Directory rootDir) async {
    final loadedImages = <File, String>{};

    List<FileSystemEntity> entities;
    try {
      entities = rootDir.listSync();
    } catch (e) {
      _showSnack('Gagal membaca folder: $e');
      _addLog('❌ Gagal membaca folder: ${rootDir.path}');
      return;
    }

    final subDirs = entities.whereType<Directory>().toList();
    if (subDirs.isEmpty) {
      _showSnack('Tidak ada subfolder kelas ditemukan.');
      return;
    }

    for (final subDir in subDirs) {
      final className = subDir.path.split('/').last;
      if (className.startsWith('.')) continue;

      List<FileSystemEntity> subEntities;
      try {
        subEntities = subDir.listSync();
      } catch (e) {
        _addLog('⚠️  Tidak bisa baca folder: $className');
        continue;
      }

      final imageFiles = subEntities
          .whereType<File>()
          .where((f) =>
              f.path.toLowerCase().endsWith('.jpg') ||
              f.path.toLowerCase().endsWith('.jpeg') ||
              f.path.toLowerCase().endsWith('.png'))
          .toList();

      for (final img in imageFiles) {
        loadedImages[img] = className;
      }
    }

    if (loadedImages.isEmpty) {
      _showSnack('Tidak ada gambar ditemukan. Pastikan struktur folder benar.');
      return;
    }

    setState(() {
      _testImages.clear();
      _testImages.addAll(loadedImages);
      _testImagesLoaded = true;
    });

    _addLog(
      '✅ ${loadedImages.length} citra dimuat dari '
      '${subDirs.where((d) => !d.path.split("/").last.startsWith(".")).length} kelas',
    );

    final classCounts = <String, int>{};
    for (final label in loadedImages.values) {
      classCounts[label] = (classCounts[label] ?? 0) + 1;
    }
    for (final entry in classCounts.entries) {
      _addLog('   ${entry.key}: ${entry.value} citra');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RUN SCENARIOS — PER MODEL
  // ═══════════════════════════════════════════════════════════════════════════

  /// Inisialisasi model yang dipilih
  Future<void> _initializeSelectedModel() async {
    _addLog('🔄 Memuat model: ${_selectedModel.name}...');
    await _benchmarkService.initialize(
      modelPath: _selectedModel.float32Path,
    );
    _addLog('✅ Model ${_selectedModel.name} berhasil dimuat');
  }

  Future<void> _runAllScenarios() async {
    if (!_testImagesLoaded || _testImages.isEmpty) {
      _showSnack('Muat citra uji terlebih dahulu!');
      return;
    }

    setState(() {
      _isRunning = true;
      _results[_selectedModelIndex] = ModelBenchmarkResults();
      _logEntries.clear();
    });

    try {
      _addLog('');
      _addLog('╔══════════════════════════════════════╗');
      _addLog('║  BENCHMARK: ${_selectedModel.name.padRight(24)}║');
      _addLog('╚══════════════════════════════════════╝');

      await _initializeSelectedModel();
      await _runScenario1();
      await _runScenario2();
      await _runScenario3();
      await _runScenario4();
      await _runScenario5();

      _addLog('\n🎉 Seluruh skenario untuk ${_selectedModel.name} selesai!');

      // Cek apakah kedua model sudah selesai
      if (_results[0]!.hasAnyResult && _results[1]!.hasAnyResult) {
        _addLog('');
        _addLog('═══════════════════════════════════════');
        _addLog('📊 Kedua model sudah di-benchmark!');
        _addLog('   Tap "Perbandingan" untuk melihat hasil.');
        _addLog('═══════════════════════════════════════');
      } else {
        final otherIdx = _selectedModelIndex == 0 ? 1 : 0;
        _addLog('');
        _addLog('📌 Selanjutnya: pilih tab "${_models[otherIdx].shortName}"');
        _addLog('   lalu jalankan skenario untuk model tersebut.');
      }
    } catch (e) {
      _addLog('❌ Error: $e');
      _showSnack('Error: $e');
    } finally {
      setState(() => _isRunning = false);
    }
  }

  /// Skenario 1: Kecepatan Inferensi
  Future<void> _runScenario1() async {
    setState(() => _currentScenario = 1);
    _addLog('\n══════════════════════════════════════');
    _addLog('📊 SKENARIO 1: Kecepatan Inferensi');
    _addLog('   Model: ${_selectedModel.name}');
    _addLog('══════════════════════════════════════');
    _addLog('Citra: ${_testImages.length} | Repetisi: 5');

    final report = await _benchmarkService.runInferenceTimeBenchmark(
      testImages: _testImages,
      repetitions: 5,
    );

    setState(() => _currentResults.timingReport = report);

    _addLog('');
    _addLog('📋 HASIL SKENARIO 1 (${_selectedModel.shortName}):');
    _addLog('─────────────────────────────────────');
    _addLog(
        '  Rata-rata  : ${report.overallAverageMs.toStringAsFixed(2)} ms');
    _addLog('  Minimum    : ${report.overallMinMs.toStringAsFixed(2)} ms');
    _addLog('  Maksimum   : ${report.overallMaxMs.toStringAsFixed(2)} ms');
    _addLog(
        '  Std Deviasi: ${report.overallStdDevMs.toStringAsFixed(2)} ms');

    _addLog('');
    _addLog('Detail per citra:');
    for (final r in report.results) {
      _addLog(
        '  ${r.imageName.padRight(25)} '
        'avg=${r.averageMs.toStringAsFixed(1)}ms '
        'min=${r.minMs.toStringAsFixed(1)}ms '
        'max=${r.maxMs.toStringAsFixed(1)}ms',
      );
    }
  }

  /// Skenario 2: Akurasi On-Device
  Future<void> _runScenario2() async {
    setState(() => _currentScenario = 2);
    _addLog('\n══════════════════════════════════════');
    _addLog('🎯 SKENARIO 2: Akurasi Deteksi');
    _addLog('   Model: ${_selectedModel.name}');
    _addLog('══════════════════════════════════════');

    final report = await _benchmarkService.runAccuracyBenchmark(
      testImages: _testImages,
    );

    setState(() => _currentResults.accuracyReport = report);

    _addLog('');
    _addLog('📋 HASIL SKENARIO 2 (${_selectedModel.shortName}):');
    _addLog('─────────────────────────────────────');
    _addLog(
        '  Overall Accuracy: ${(report.overallAccuracy * 100).toStringAsFixed(1)}%');
    _addLog('  Benar: ${report.totalCorrect} / ${report.totalImages}');

    _addLog('');
    _addLog('Akurasi per kelas:');
    for (final c in report.perClassAccuracy) {
      final pct = (c.accuracy * 100).toStringAsFixed(1);
      _addLog(
        '  ${c.className.padRight(22)} '
        '${c.correctPredictions}/${c.totalImages} ($pct%)',
      );
    }

    final wrong = report.predictions.where((p) => !p.isCorrect).toList();
    if (wrong.isNotEmpty) {
      _addLog('');
      _addLog('❌ Prediksi salah:');
      for (final w in wrong) {
        _addLog(
          '  ${w.imageName}: '
          'seharusnya=${w.trueLabel}, '
          'prediksi=${w.predictedLabel} '
          '(${(w.confidence * 100).toStringAsFixed(1)}%)',
        );
      }
    }
  }

  /// Skenario 3: CPU Stress Test
  Future<void> _runScenario3() async {
    setState(() => _currentScenario = 3);
    _addLog('\n══════════════════════════════════════');
    _addLog('🔥 SKENARIO 3: CPU Stress Test');
    _addLog('   Model: ${_selectedModel.name}');
    _addLog('══════════════════════════════════════');
    _addLog('⚠️  Buka Android Studio Profiler!');
    _addLog('    Menunggu 3 detik...');

    final images = _testImages.keys.toList();
    final report = await _benchmarkService.runCpuStressTest(
      testImages: images,
      imageCount: 10,
    );

    setState(() => _currentResults.cpuReport = report);

    _addLog('');
    _addLog('📋 HASIL SKENARIO 3 (${_selectedModel.shortName}):');
    _addLog('─────────────────────────────────────');
    _addLog(
        '  Total durasi: ${report.totalDuration.inMilliseconds} ms');
    _addLog(
        '  Rata-rata inferensi: ${report.averageInferenceMs.toStringAsFixed(2)} ms');

    _addLog('');
    _addLog('Detail per inferensi:');
    for (final e in report.entries) {
      _addLog(
        '  #${e.index}: ${e.imageName.padRight(25)} '
        '${e.inferenceTimeMs.toStringAsFixed(1)} ms',
      );
    }
  }

  /// Skenario 4: RAM
  Future<void> _runScenario4() async {
    setState(() => _currentScenario = 4);
    _addLog('\n══════════════════════════════════════');
    _addLog('💾 SKENARIO 4: Penggunaan Memori (RAM)');
    _addLog('   Model: ${_selectedModel.name}');
    _addLog('══════════════════════════════════════');

    final testImage = _testImages.keys.first;
    final report = await _benchmarkService.runMemoryBenchmark(
      testImage: testImage,
    );

    setState(() => _currentResults.memoryReport = report);

    _addLog('');
    _addLog('📋 HASIL SKENARIO 4 (${_selectedModel.shortName}):');
    _addLog('─────────────────────────────────────');
    _addLog(
      '  Total Memory : ${report.idleSnapshot.totalMemoryMB.toStringAsFixed(2)} MB',
    );
    _addLog('');
    _addLog(
        '  ┌─────────────────┬────────────┬────────────┬──────────┐');
    _addLog(
        '  │ Metrik          │ Idle (MB)  │ Active (MB)│ Delta(MB)│');
    _addLog(
        '  ├─────────────────┼────────────┼────────────┼──────────┤');
    _addLog(
      '  │ Used Memory     │ '
      '${report.idleSnapshot.usedMemoryMB.toStringAsFixed(2).padLeft(10)} │ '
      '${report.duringInferenceSnapshot.usedMemoryMB.toStringAsFixed(2).padLeft(10)} │ '
      '${report.deltaUsedMB.toStringAsFixed(2).padLeft(8)} │',
    );
    _addLog(
      '  │ Native Heap     │ '
      '${report.idleSnapshot.dartHeapUsageMB.toStringAsFixed(2).padLeft(10)} │ '
      '${report.duringInferenceSnapshot.dartHeapUsageMB.toStringAsFixed(2).padLeft(10)} │ '
      '${report.deltaDartHeapMB.toStringAsFixed(2).padLeft(8)} │',
    );
    _addLog(
        '  └─────────────────┴────────────┴────────────┴──────────┘');
  }

  /// Skenario 5: Ukuran Model
  Future<void> _runScenario5() async {
    setState(() => _currentScenario = 5);
    _addLog('\n══════════════════════════════════════');
    _addLog('📦 SKENARIO 5: Ukuran Model TFLite');
    _addLog('   Model: ${_selectedModel.name}');
    _addLog('══════════════════════════════════════');

    final modelPaths = <String, String>{
      '${_selectedModel.name} Float32': _selectedModel.float32Path,
      '${_selectedModel.name} INT8': _selectedModel.int8Path,
    };

    final report = await _benchmarkService.measureModelSizes(
      modelPaths: modelPaths,
    );

    setState(() => _currentResults.modelSizeReport = report);

    _addLog('');
    _addLog('📋 HASIL SKENARIO 5 (${_selectedModel.shortName}):');
    _addLog('─────────────────────────────────────');

    for (final m in report.models) {
      final sizeStr = m.sizeMB >= 0
          ? '${m.sizeMB.toStringAsFixed(2)} MB'
          : 'N/A';
      _addLog(
          '  ${m.modelName} (${m.quantizationType}): $sizeStr');
    }

    final reduction =
        report.reductionPercentage(_selectedModel.name);
    if (reduction > 0) {
      _addLog(
          '  📉 Reduksi quantization: ${reduction.toStringAsFixed(1)}%');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHOW COMPARISON
  // ═══════════════════════════════════════════════════════════════════════════

  void _showComparison() {
    final r0 = _results[0]!;
    final r1 = _results[1]!;

    if (!r0.hasAnyResult || !r1.hasAnyResult) {
      _showSnack(
          'Jalankan benchmark untuk kedua model terlebih dahulu!');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ComparisonSheet(
        model0: _models[0],
        model1: _models[1],
        results0: r0,
        results1: r1,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXPORT RESULTS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _exportAllResults() async {
    final dir = await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
    final timestamp =
        DateTime.now().toIso8601String().replaceAll(':', '-');
    final exportDir =
        Directory('${dir.path}/benchmark_$timestamp');
    await exportDir.create(recursive: true);

    final files = <String>[];

    // Export per model
    for (int i = 0; i < _models.length; i++) {
      final model = _models[i];
      final res = _results[i]!;
      final prefix = model.shortName.toLowerCase().replaceAll(' ', '_');

      if (res.timingReport != null) {
        final f = File(
            '${exportDir.path}/${prefix}_skenario1_inference_time.csv');
        await f.writeAsString(
            _benchmarkService.generateTimingCsv(res.timingReport!));
        files.add(f.path);
      }

      if (res.accuracyReport != null) {
        final f = File(
            '${exportDir.path}/${prefix}_skenario2_accuracy.csv');
        await f.writeAsString(
            _benchmarkService.generateAccuracyCsv(res.accuracyReport!));
        files.add(f.path);
      }

      if (res.memoryReport != null) {
        final f = File(
            '${exportDir.path}/${prefix}_skenario4_memory.csv');
        await f.writeAsString(
            _benchmarkService.generateMemoryCsv(res.memoryReport!));
        files.add(f.path);
      }

      if (res.modelSizeReport != null) {
        final f = File(
            '${exportDir.path}/${prefix}_skenario5_model_size.csv');
        await f.writeAsString(
            _benchmarkService.generateModelSizeCsv(res.modelSizeReport!));
        files.add(f.path);
      }
    }

    // Export comparison summary
    if (_results[0]!.hasAnyResult && _results[1]!.hasAnyResult) {
      final f =
          File('${exportDir.path}/comparison_summary.csv');
      await f.writeAsString(_generateComparisonCsv());
      files.add(f.path);
    }

    // Export log
    final logFile = File('${exportDir.path}/benchmark_log.txt');
    await logFile.writeAsString(_logEntries.join('\n'));
    files.add(logFile.path);

    if (files.isNotEmpty) {
      _showSnack('Hasil disimpan di: ${exportDir.path}');
      await Share.shareXFiles(
        files.map((f) => XFile(f)).toList(),
        subject: 'Benchmark Results - $timestamp',
      );
    }
  }

  String _generateComparisonCsv() {
    final buffer = StringBuffer();
    buffer.writeln('COMPARISON SUMMARY');
    buffer.writeln(
        'Metric,${_models[0].name},${_models[1].name},Winner');
    buffer.writeln('');

    // Skenario 1 - Speed
    final t0 = _results[0]!.timingReport;
    final t1 = _results[1]!.timingReport;
    if (t0 != null && t1 != null) {
      final avg0 = t0.overallAverageMs;
      final avg1 = t1.overallAverageMs;
      final winner = avg0 < avg1 ? _models[0].name : _models[1].name;
      buffer.writeln(
          'Avg Inference Time (ms),${avg0.toStringAsFixed(2)},${avg1.toStringAsFixed(2)},$winner');
    }

    // Skenario 2 - Accuracy
    final a0 = _results[0]!.accuracyReport;
    final a1 = _results[1]!.accuracyReport;
    if (a0 != null && a1 != null) {
      final acc0 = a0.overallAccuracy * 100;
      final acc1 = a1.overallAccuracy * 100;
      final winner = acc0 > acc1 ? _models[0].name : _models[1].name;
      buffer.writeln(
          'Accuracy (%),${acc0.toStringAsFixed(1)},${acc1.toStringAsFixed(1)},$winner');
    }

    // Skenario 4 - Memory
    final m0 = _results[0]!.memoryReport;
    final m1 = _results[1]!.memoryReport;
    if (m0 != null && m1 != null) {
      final delta0 = m0.deltaUsedMB;
      final delta1 = m1.deltaUsedMB;
      final winner = delta0 < delta1 ? _models[0].name : _models[1].name;
      buffer.writeln(
          'RAM Delta (MB),${delta0.toStringAsFixed(2)},${delta1.toStringAsFixed(2)},$winner');
    }

    // Skenario 5 - Size
    final s0 = _results[0]!.modelSizeReport;
    final s1 = _results[1]!.modelSizeReport;
    if (s0 != null && s1 != null) {
      final float32_0 = s0.models
          .where((m) => m.quantizationType == 'Float32')
          .firstOrNull
          ?.sizeMB;
      final float32_1 = s1.models
          .where((m) => m.quantizationType == 'Float32')
          .firstOrNull
          ?.sizeMB;
      if (float32_0 != null && float32_1 != null) {
        final winner =
            float32_0 < float32_1 ? _models[0].name : _models[1].name;
        buffer.writeln(
            'Model Size Float32 (MB),${float32_0.toStringAsFixed(2)},${float32_1.toStringAsFixed(2)},$winner');
      }
    }

    return buffer.toString();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  void _addLog(String message) {
    setState(() => _logEntries.add(message));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _runSingleScenario(int scenario) async {
    if (_isRunning) return;

    setState(() => _isRunning = true);

    try {
      await _initializeSelectedModel();
      switch (scenario) {
        case 1:
          await _runScenario1();
          break;
        case 2:
          await _runScenario2();
          break;
        case 3:
          await _runScenario3();
          break;
        case 4:
          await _runScenario4();
          break;
        case 5:
          await _runScenario5();
          break;
      }
    } catch (e) {
      _addLog('❌ Error Skenario $scenario: $e');
    } finally {
      setState(() => _isRunning = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF1C3D1E);
    const Color accent = Color(0xFF3A7D44);
    const Color bg = Color(0xFFF4F8F5);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text(
          'Benchmark On-Device',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Tombol Perbandingan
          if (_results[0]!.hasAnyResult && _results[1]!.hasAnyResult)
            IconButton(
              icon: const Icon(Icons.compare_arrows_rounded),
              tooltip: 'Perbandingan',
              onPressed: _showComparison,
            ),
          if (_logEntries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.save_alt_rounded),
              tooltip: 'Export Hasil',
              onPressed: _isRunning ? null : _exportAllResults,
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Progress bar ──────────────────────────────────────
          if (_isRunning)
            Column(
              children: [
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: const Color(0xFFDDE8DE),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(_selectedModel.color),
                  minHeight: 4,
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  color: const Color(0xFFE8F5E9),
                  child: Text(
                    _currentStatus,
                    style: TextStyle(
                      fontSize: 12,
                      color: primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

          Expanded(
            child: _testImagesLoaded
                ? _buildMainContent(primary, accent)
                : _buildSetupView(primary, accent),
          ),
        ],
      ),
    );
  }

  // ── Setup View ────────────────────────────────────────────────────────────
  Widget _buildSetupView(Color primary, Color accent) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(28),
              ),  
              child: const Icon(
                Icons.science_outlined,
                size: 50,
                color: Color(0xFF3A7D44),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Benchmark On-Device Inference',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1C3D1E),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'MobileNetV3-Large vs EfficientNet-Lite0',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3A7D44),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Siapkan folder citra uji dengan struktur:\n'
              'test_set/\n'
              '  ├── BA- cellulitis/ (3-4 gambar)\n'
              '  ├── BA-impetigo/ (3-4 gambar)\n'
              '  ├── FU-athlete-foot/ (3-4 gambar)\n'
              '  └── ... (9 kelas total)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF7A9E82),
                height: 1.6,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.sd_storage_rounded),
                label: const Text(
                  'Load dari Download',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                onPressed: _loadFromDefaultPath,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: const BorderSide(
                      color: Color(0xFF3A7D44), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.folder_open_rounded),
                label: const Text(
                  'Pilih Folder Manual',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
                onPressed: _loadTestImagesFromFolder,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8EC),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: const Color(0xFFE8C87A)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      color: Color(0xFFD4880A), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Untuk emulator: letakkan folder citra uji di '
                      'Download/test_set/ lalu tap "Load dari Download".',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF7A5200),
                        height: 1.4,
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

  // ── Main Content ──────────────────────────────────────────────────────────
  Widget _buildMainContent(Color primary, Color accent) {
    return Column(
      children: [
        // ── Model Selector Tabs ──────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDDE8DE)),
          ),
          child: Row(
            children: List.generate(_models.length, (index) {
              final model = _models[index];
              final isSelected = _selectedModelIndex == index;
              final hasResult = _results[index]!.hasAnyResult;

              return Expanded(
                child: GestureDetector(
                  onTap: _isRunning
                      ? null
                      : () =>
                          setState(() => _selectedModelIndex = index),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? model.color.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(13),
                      border: isSelected
                          ? Border.all(
                              color: model.color, width: 1.5)
                          : null,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            if (hasResult)
                              Icon(Icons.check_circle,
                                  size: 14, color: model.color),
                            if (hasResult)
                              const SizedBox(width: 4),
                            Text(
                              model.shortName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? model.color
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                        if (hasResult)
                          Text(
                            'Selesai',
                            style: TextStyle(
                              fontSize: 10,
                              color: model.color.withOpacity(0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        // ── Info bar ──────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDDE8DE)),
          ),
          child: Row(
            children: [
              const Icon(Icons.photo_library_rounded,
                  color: Color(0xFF3A7D44), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_testImages.length} citra uji dimuat',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C3D1E),
                  ),
                ),
              ),
              TextButton(
                onPressed: _isRunning
                    ? null
                    : () {
                        setState(() {
                          _testImages.clear();
                          _testImagesLoaded = false;
                        });
                      },
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Ganti'),
              ),
            ],
          ),
        ),

        // ── Scenario buttons ─────────────────────────────────────
        if (!_isRunning)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedModel.color,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(
                        Icons.play_arrow_rounded, size: 22),
                    label: Text(
                      'Jalankan Semua — ${_selectedModel.shortName}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: _runAllScenarios,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _ScenarioChip(
                      number: 1,
                      label: 'Speed',
                      icon: Icons.speed_rounded,
                      isDone: _currentResults.timingReport != null,
                      color: _selectedModel.color,
                      onTap: () => _runSingleScenario(1),
                    ),
                    const SizedBox(width: 5),
                    _ScenarioChip(
                      number: 2,
                      label: 'Accuracy',
                      icon: Icons.gps_fixed,
                      isDone:
                          _currentResults.accuracyReport != null,
                      color: _selectedModel.color,
                      onTap: () => _runSingleScenario(2),
                    ),
                    const SizedBox(width: 5),
                    _ScenarioChip(
                      number: 3,
                      label: 'CPU',
                      icon: Icons.memory_rounded,
                      isDone: _currentResults.cpuReport != null,
                      color: _selectedModel.color,
                      onTap: () => _runSingleScenario(3),
                    ),
                    const SizedBox(width: 5),
                    _ScenarioChip(
                      number: 4,
                      label: 'RAM',
                      icon: Icons.storage_rounded,
                      isDone: _currentResults.memoryReport != null,
                      color: _selectedModel.color,
                      onTap: () => _runSingleScenario(4),
                    ),
                    const SizedBox(width: 5),
                    _ScenarioChip(
                      number: 5,
                      label: 'Size',
                      icon: Icons.sd_card_rounded,
                      isDone:
                          _currentResults.modelSizeReport != null,
                      color: _selectedModel.color,
                      onTap: () => _runSingleScenario(5),
                    ),
                  ],
                ),
              ],
            ),
          ),

        const SizedBox(height: 8),

        // ── Log output ───────────────────────────────────────────
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: const BoxDecoration(
                      color: Color(0xFF16213E),
                      border: Border(
                        bottom: BorderSide(
                            color: Color(0xFF0F3460), width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isRunning
                                ? _selectedModel.color
                                : const Color(0xFF666666),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isRunning
                              ? '${_selectedModel.shortName} — Scenario $_currentScenario'
                              : 'Benchmark Log',
                          style: const TextStyle(
                            color: Color(0xFF8899AA),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (_logEntries.isNotEmpty)
                          GestureDetector(
                            onTap: () =>
                                setState(() => _logEntries.clear()),
                            child: const Icon(Icons.delete_outline,
                                color: Color(0xFF8899AA), size: 16),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _logEntries.isEmpty
                        ? Center(
                            child: Text(
                              'Pilih model di atas lalu jalankan benchmark',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(12),
                            itemCount: _logEntries.length,
                            itemBuilder: (context, index) {
                              final line = _logEntries[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  line,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11.5,
                                    height: 1.4,
                                    color: _getLogColor(line),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getLogColor(String line) {
    if (line.startsWith('✅') || line.contains('🎉')) {
      return const Color(0xFF4CAF50);
    }
    if (line.startsWith('❌')) return const Color(0xFFEF5350);
    if (line.startsWith('⚠️') || line.startsWith('📌')) {
      return const Color(0xFFFFB74D);
    }
    if (line.startsWith('╔') ||
        line.startsWith('║') ||
        line.startsWith('╚') ||
        line.startsWith('══') ||
        line.startsWith('──')) {
      return const Color(0xFF42A5F5);
    }
    if (line.startsWith('📊') ||
        line.startsWith('🎯') ||
        line.startsWith('🔥') ||
        line.startsWith('💾') ||
        line.startsWith('📦')) {
      return const Color(0xFF42A5F5);
    }
    if (line.startsWith('📋')) return const Color(0xFF80CBC4);
    if (line.startsWith('📂') || line.startsWith('🔄')) {
      return const Color(0xFF81D4FA);
    }
    if (line.contains('│') ||
        line.contains('┌') ||
        line.contains('└')) {
      return const Color(0xFF90CAF9);
    }
    return const Color(0xFFCCDDEE);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGET — Scenario Chip
// ══════════════════════════════════════════════════════════════════════════════

class _ScenarioChip extends StatelessWidget {
  final int number;
  final String label;
  final IconData icon;
  final bool isDone;
  final Color color;
  final VoidCallback onTap;

  const _ScenarioChip({
    required this.number,
    required this.label,
    required this.icon,
    required this.isDone,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: isDone
            ? color.withOpacity(0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDone
                    ? color
                    : const Color(0xFFDDE8DE),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  isDone ? Icons.check_circle : icon,
                  size: 18,
                  color: isDone
                      ? color
                      : const Color(0xFF7A9E82),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDone
                        ? color
                        : const Color(0xFF7A9E82),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGET — Comparison Bottom Sheet
// ══════════════════════════════════════════════════════════════════════════════

class _ComparisonSheet extends StatelessWidget {
  final ModelConfig model0;
  final ModelConfig model1;
  final ModelBenchmarkResults results0;
  final ModelBenchmarkResults results1;

  const _ComparisonSheet({
    required this.model0,
    required this.model1,
    required this.results0,
    required this.results1,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF4F8F5),
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.compare_arrows_rounded,
                        color: Color(0xFF1C3D1E)),
                    const SizedBox(width: 8),
                    const Text(
                      'Perbandingan Model',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1C3D1E),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding:
                      const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  children: [
                    _buildComparisonCard(
                      title: 'Skenario 1 — Kecepatan Inferensi',
                      icon: Icons.speed_rounded,
                      rows: _buildSpeedComparison(),
                    ),
                    const SizedBox(height: 12),
                    _buildComparisonCard(
                      title: 'Skenario 2 — Akurasi Deteksi',
                      icon: Icons.gps_fixed,
                      rows: _buildAccuracyComparison(),
                    ),
                    const SizedBox(height: 12),
                    _buildComparisonCard(
                      title: 'Skenario 3 — CPU Stress Test',
                      icon: Icons.memory_rounded,
                      rows: _buildCpuComparison(),
                    ),
                    const SizedBox(height: 12),
                    _buildComparisonCard(
                      title: 'Skenario 4 — Penggunaan RAM',
                      icon: Icons.storage_rounded,
                      rows: _buildMemoryComparison(),
                    ),
                    const SizedBox(height: 12),
                    _buildComparisonCard(
                      title: 'Skenario 5 — Ukuran Model',
                      icon: Icons.sd_card_rounded,
                      rows: _buildSizeComparison(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildComparisonCard({
    required String title,
    required IconData icon,
    required List<_ComparisonRow> rows,
  }) {
    if (rows.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDDE8DE)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey.shade400, size: 20),
            const SizedBox(width: 8),
            Text(title,
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 13)),
            const Spacer(),
            Text('Belum ada data',
                style: TextStyle(
                    color: Colors.grey.shade400, fontSize: 12)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE8DE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(icon,
                    color: const Color(0xFF1C3D1E), size: 18),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1C3D1E),
                    )),
              ],
            ),
          ),
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            color: const Color(0xFFF5F8F5),
            child: Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text('Metrik',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600))),
                Expanded(
                    flex: 2,
                    child: Text(model0.shortName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: model0.color))),
                Expanded(
                    flex: 2,
                    child: Text(model1.shortName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: model1.color))),
                const Expanded(
                    flex: 1,
                    child: Text('🏆',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11))),
              ],
            ),
          ),
          // Table rows
          ...rows.map((row) => Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                        flex: 3,
                        child: Text(row.metric,
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF444444)))),
                    Expanded(
                      flex: 2,
                      child: Text(row.value0,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: row.winnerIndex == 0
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: row.winnerIndex == 0
                                ? model0.color
                                : const Color(0xFF666666),
                          )),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(row.value1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: row.winnerIndex == 1
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: row.winnerIndex == 1
                                ? model1.color
                                : const Color(0xFF666666),
                          )),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        row.winnerIndex == 0
                            ? 'M'
                            : row.winnerIndex == 1
                                ? 'E'
                                : '-',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: row.winnerIndex == 0
                              ? model0.color
                              : row.winnerIndex == 1
                                  ? model1.color
                                  : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  List<_ComparisonRow> _buildSpeedComparison() {
    final t0 = results0.timingReport;
    final t1 = results1.timingReport;
    if (t0 == null || t1 == null) return [];

    return [
      _ComparisonRow(
        metric: 'Avg (ms)',
        value0: t0.overallAverageMs.toStringAsFixed(2),
        value1: t1.overallAverageMs.toStringAsFixed(2),
        winnerIndex:
            t0.overallAverageMs < t1.overallAverageMs ? 0 : 1,
      ),
      _ComparisonRow(
        metric: 'Min (ms)',
        value0: t0.overallMinMs.toStringAsFixed(2),
        value1: t1.overallMinMs.toStringAsFixed(2),
        winnerIndex: t0.overallMinMs < t1.overallMinMs ? 0 : 1,
      ),
      _ComparisonRow(
        metric: 'Max (ms)',
        value0: t0.overallMaxMs.toStringAsFixed(2),
        value1: t1.overallMaxMs.toStringAsFixed(2),
        winnerIndex: t0.overallMaxMs < t1.overallMaxMs ? 0 : 1,
      ),
      _ComparisonRow(
        metric: 'Std Dev (ms)',
        value0: t0.overallStdDevMs.toStringAsFixed(2),
        value1: t1.overallStdDevMs.toStringAsFixed(2),
        winnerIndex:
            t0.overallStdDevMs < t1.overallStdDevMs ? 0 : 1,
      ),
    ];
  }

  List<_ComparisonRow> _buildAccuracyComparison() {
    final a0 = results0.accuracyReport;
    final a1 = results1.accuracyReport;
    if (a0 == null || a1 == null) return [];

    final rows = <_ComparisonRow>[
      _ComparisonRow(
        metric: 'Overall Accuracy',
        value0:
            '${(a0.overallAccuracy * 100).toStringAsFixed(1)}%',
        value1:
            '${(a1.overallAccuracy * 100).toStringAsFixed(1)}%',
        winnerIndex:
            a0.overallAccuracy > a1.overallAccuracy ? 0 : 1,
      ),
      _ComparisonRow(
        metric: 'Benar / Total',
        value0: '${a0.totalCorrect}/${a0.totalImages}',
        value1: '${a1.totalCorrect}/${a1.totalImages}',
        winnerIndex: a0.totalCorrect > a1.totalCorrect ? 0 : 1,
      ),
    ];

    // Per-class accuracy comparison
    final allClasses = <String>{
      ...a0.perClassAccuracy.map((c) => c.className),
      ...a1.perClassAccuracy.map((c) => c.className),
    }.toList()
      ..sort();

    for (final cls in allClasses) {
      final c0 = a0.perClassAccuracy
          .where((c) => c.className == cls)
          .firstOrNull;
      final c1 = a1.perClassAccuracy
          .where((c) => c.className == cls)
          .firstOrNull;

      if (c0 != null && c1 != null) {
        rows.add(_ComparisonRow(
          metric: cls.length > 18
              ? '${cls.substring(0, 15)}...'
              : cls,
          value0:
              '${(c0.accuracy * 100).toStringAsFixed(0)}%',
          value1:
              '${(c1.accuracy * 100).toStringAsFixed(0)}%',
          winnerIndex:
              c0.accuracy > c1.accuracy ? 0 : 1,
        ));
      }
    }

    return rows;
  }

  List<_ComparisonRow> _buildCpuComparison() {
    final c0 = results0.cpuReport;
    final c1 = results1.cpuReport;
    if (c0 == null || c1 == null) return [];

    return [
      _ComparisonRow(
        metric: 'Avg Inferensi (ms)',
        value0: c0.averageInferenceMs.toStringAsFixed(2),
        value1: c1.averageInferenceMs.toStringAsFixed(2),
        winnerIndex: c0.averageInferenceMs < c1.averageInferenceMs
            ? 0
            : 1,
      ),
      _ComparisonRow(
        metric: 'Total Durasi (ms)',
        value0:
            c0.totalDuration.inMilliseconds.toString(),
        value1:
            c1.totalDuration.inMilliseconds.toString(),
        winnerIndex:
            c0.totalDuration < c1.totalDuration ? 0 : 1,
      ),
    ];
  }

  List<_ComparisonRow> _buildMemoryComparison() {
    final m0 = results0.memoryReport;
    final m1 = results1.memoryReport;
    if (m0 == null || m1 == null) return [];

    return [
      _ComparisonRow(
        metric: 'Delta Used (MB)',
        value0: m0.deltaUsedMB.toStringAsFixed(2),
        value1: m1.deltaUsedMB.toStringAsFixed(2),
        winnerIndex:
            m0.deltaUsedMB.abs() < m1.deltaUsedMB.abs() ? 0 : 1,
      ),
      _ComparisonRow(
        metric: 'Delta Heap (MB)',
        value0: m0.deltaDartHeapMB.toStringAsFixed(2),
        value1: m1.deltaDartHeapMB.toStringAsFixed(2),
        winnerIndex:
            m0.deltaDartHeapMB.abs() < m1.deltaDartHeapMB.abs()
                ? 0
                : 1,
      ),
    ];
  }

  List<_ComparisonRow> _buildSizeComparison() {
    final s0 = results0.modelSizeReport;
    final s1 = results1.modelSizeReport;
    if (s0 == null || s1 == null) return [];

    final rows = <_ComparisonRow>[];

    final f32_0 = s0.models
        .where((m) => m.quantizationType == 'Float32')
        .firstOrNull;
    final f32_1 = s1.models
        .where((m) => m.quantizationType == 'Float32')
        .firstOrNull;
    if (f32_0 != null && f32_1 != null) {
      rows.add(_ComparisonRow(
        metric: 'Float32 (MB)',
        value0: f32_0.sizeMB >= 0
            ? f32_0.sizeMB.toStringAsFixed(2)
            : 'N/A',
        value1: f32_1.sizeMB >= 0
            ? f32_1.sizeMB.toStringAsFixed(2)
            : 'N/A',
        winnerIndex: (f32_0.sizeMB >= 0 && f32_1.sizeMB >= 0)
            ? (f32_0.sizeMB < f32_1.sizeMB ? 0 : 1)
            : -1,
      ));
    }

    final int8_0 = s0.models
        .where((m) => m.quantizationType == 'INT8')
        .firstOrNull;
    final int8_1 = s1.models
        .where((m) => m.quantizationType == 'INT8')
        .firstOrNull;
    if (int8_0 != null && int8_1 != null) {
      rows.add(_ComparisonRow(
        metric: 'INT8 (MB)',
        value0: int8_0.sizeMB >= 0
            ? int8_0.sizeMB.toStringAsFixed(2)
            : 'N/A',
        value1: int8_1.sizeMB >= 0
            ? int8_1.sizeMB.toStringAsFixed(2)
            : 'N/A',
        winnerIndex: (int8_0.sizeMB >= 0 && int8_1.sizeMB >= 0)
            ? (int8_0.sizeMB < int8_1.sizeMB ? 0 : 1)
            : -1,
      ));
    }

    return rows;
  }
}

class _ComparisonRow {
  final String metric;
  final String value0;
  final String value1;
  final int winnerIndex; // 0, 1, or -1 (tie/N/A)

  const _ComparisonRow({
    required this.metric,
    required this.value0,
    required this.value1,
    required this.winnerIndex,
  });
}
