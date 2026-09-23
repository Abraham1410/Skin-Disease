import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart';

import 'package:skindisease/features/scan/data/tflite_predict_service.dart';
import 'package:skindisease/features/benchmark/data/benchmark_models.dart';
import 'package:skindisease/features/benchmark/data/memory_info_plugin.dart';

/// Service utama untuk menjalankan seluruh skenario benchmark
/// sesuai Tabel 3.24 - On-Device Inference Android.
///
/// Menggunakan [TFLitePredictService] yang sudah ada untuk melakukan inferensi.
class BenchmarkService {
  final TFLitePredictService _predictService;
  bool _isModelLoaded = false;
  String _currentModelPath = '';

  BenchmarkService({TFLitePredictService? predictService})
      : _predictService = predictService ?? TFLitePredictService();

  /// Callback untuk progress update
  Function(String message, double progress)? onProgress;

  /// Inisialisasi model dengan path tertentu.
  /// Jika model sudah di-load dengan path yang sama, skip.
  /// Jika path berbeda, tutup model lama dan load yang baru.
  Future<void> initialize({String? modelPath}) async {
    // Jika tidak ada path baru, JANGAN ganggu model yang sudah ter-load
    if (modelPath == null) {
      if (_isModelLoaded) return; // model apapun yang sudah ada, biarkan
      modelPath = 'assets/models/skin_disease_mobilenetv3large_float32.tflite';
    }

    if (_isModelLoaded && _currentModelPath == modelPath) {
      return; // Model sudah di-load dengan path yang sama, skip
    }

    // Tutup model lama jika ada
    if (_isModelLoaded) {
      _predictService.close();
      _isModelLoaded = false;
    }

    await _predictService.loadModel(modelPath: modelPath);
    _currentModelPath = modelPath;
    _isModelLoaded = true;
  }

  /// Tutup model
  void dispose() {
    _predictService.close();
    _isModelLoaded = false;
    _currentModelPath = '';
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SKENARIO 1 — Pengujian Kecepatan Inferensi On-Device
  // ════════════════════════════════════════════════════════════════════════════

  /// Menjalankan benchmark kecepatan inferensi.
  ///
  /// [testImages] — Map dari File gambar ke label kelas (ground truth).
  /// [repetitions] — Jumlah pengulangan per citra (default: 5).
  ///
  /// Sesuai skenario: 30 citra uji, diulang 5 kali per citra.
  Future<InferenceTimingReport> runInferenceTimeBenchmark({
    required Map<File, String> testImages,
    int repetitions = 5,
  }) async {
    await initialize();

    final results = <SingleImageTimingResult>[];
    int current = 0;
    final total = testImages.length;

    for (final entry in testImages.entries) {
      current++;
      final file = entry.key;
      final label = entry.value;
      final fileName = file.path.split(Platform.pathSeparator).last;

      onProgress?.call(
        'Skenario 1: Inferensi $fileName ($current/$total)',
        current / total,
      );

      final timings = <double>[];

      // Warm-up run (tidak dihitung)
      await _predictService.predict(file);

      for (int i = 0; i < repetitions; i++) {
        final stopwatch = Stopwatch()..start();
        await _predictService.predict(file);
        stopwatch.stop();
        timings.add(stopwatch.elapsedMicroseconds / 1000.0); // ke ms
      }

      results.add(SingleImageTimingResult(
        imageName: fileName,
        classLabel: label,
        timingsMs: timings,
      ));
    }

    return InferenceTimingReport(
      results: results,
      repetitionsPerImage: repetitions,
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SKENARIO 2 — Pengujian Akurasi Deteksi On-Device
  // ════════════════════════════════════════════════════════════════════════════

  /// Menjalankan benchmark akurasi.
  ///
  /// [testImages] — Map dari File gambar ke label kelas sebenarnya.
  ///
  /// Sesuai skenario: 30 citra yang sama (9 kelas).
  Future<AccuracyReport> runAccuracyBenchmark({
    required Map<File, String> testImages,
  }) async {
    await initialize();

    final predictions = <SinglePredictionResult>[];
    int current = 0;
    final total = testImages.length;

    for (final entry in testImages.entries) {
      current++;
      final file = entry.key;
      final trueLabel = entry.value;
      final fileName = file.path.split(Platform.pathSeparator).last;

      onProgress?.call(
        'Skenario 2: Prediksi $fileName ($current/$total)',
        current / total,
      );

      final result = await _predictService.predict(file);

      predictions.add(SinglePredictionResult(
        imageName: fileName,
        trueLabel: trueLabel,
        predictedLabel: result.label,
        confidence: result.confidence,
      ));
    }

    // Hitung akurasi per kelas
    final classLabels = testImages.values.toSet().toList()..sort();
    final perClass = <ClassAccuracy>[];

    for (final className in classLabels) {
      final classImages =
          predictions.where((p) => p.trueLabel == className).toList();
      final correct = classImages.where((p) => p.isCorrect).length;

      perClass.add(ClassAccuracy(
        className: className,
        totalImages: classImages.length,
        correctPredictions: correct,
      ));
    }

    return AccuracyReport(
      predictions: predictions,
      perClassAccuracy: perClass,
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SKENARIO 3 — Pengujian Penggunaan CPU
  // ════════════════════════════════════════════════════════════════════════════

  /// Menjalankan stress test CPU: 10 citra berturut-turut.
  ///
  /// Didesain untuk dimonitor bersamaan dengan Android Studio Profiler.
  /// Memberikan delay 2 detik sebelum mulai agar user sempat memulai profiling.
  ///
  /// Sesuai skenario: monitoring CPU usage saat inferensi 10 citra berturut-turut.
  Future<CpuStressReport> runCpuStressTest({
    required List<File> testImages,
    int imageCount = 10,
  }) async {
    await initialize();

    final imagesToTest = testImages.take(imageCount).toList();
    final entries = <CpuStressEntry>[];

    onProgress?.call(
      'Skenario 3: Menunggu 3 detik sebelum stress test dimulai...\n'
      'Buka Android Studio Profiler sekarang!',
      0.0,
    );

    // Delay agar user bisa membuka Profiler
    await Future.delayed(const Duration(seconds: 3));

    final testStart = DateTime.now();

    for (int i = 0; i < imagesToTest.length; i++) {
      final file = imagesToTest[i];
      final fileName = file.path.split(Platform.pathSeparator).last;

      onProgress?.call(
        'Skenario 3: CPU Stress Test ${i + 1}/${imagesToTest.length}',
        (i + 1) / imagesToTest.length,
      );

      final startTime = DateTime.now();
      final stopwatch = Stopwatch()..start();

      await _predictService.predict(file);

      stopwatch.stop();
      final endTime = DateTime.now();

      entries.add(CpuStressEntry(
        index: i + 1,
        imageName: fileName,
        inferenceTimeMs: stopwatch.elapsedMicroseconds / 1000.0,
        startTime: startTime,
        endTime: endTime,
      ));
    }

    final testEnd = DateTime.now();

    return CpuStressReport(
      entries: entries,
      testStartTime: testStart,
      testEndTime: testEnd,
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SKENARIO 4 — Pengujian Penggunaan Memori (RAM)
  // ════════════════════════════════════════════════════════════════════════════

  /// Mengukur penggunaan RAM: baseline (idle) vs saat inferensi.
  ///
  /// Sesuai skenario: monitoring RAM sebelum dan saat inferensi aktif.
  Future<MemoryUsageReport> runMemoryBenchmark({
    required File testImage,
  }) async {
    await initialize();

    onProgress?.call('Skenario 4: Mengukur memori idle...', 0.2);

    // Tunggu sebentar agar state idle stabil
    await Future.delayed(const Duration(seconds: 2));

    // Ambil snapshot idle
    final idleMemory = await _captureMemorySnapshot();

    onProgress?.call('Skenario 4: Mengukur memori saat inferensi...', 0.5);

    // Lakukan inferensi beberapa kali dan ambil snapshot di tengah proses
    MemorySnapshot? duringInference;

    // Jalankan beberapa inferensi berturut-turut untuk membuat tekanan memori
    for (int i = 0; i < 5; i++) {
      // ignore: unawaited_futures
      _predictService.predict(testImage);

      if (i == 2) {
        // Ambil snapshot di tengah-tengah proses
        duringInference = await _captureMemorySnapshot();
      }
    }

    // Pastikan terakhir selesai
    await _predictService.predict(testImage);

    // Ambil snapshot terakhir jika belum berhasil di tengah
    duringInference ??= await _captureMemorySnapshot();

    onProgress?.call('Skenario 4: Selesai', 1.0);

    return MemoryUsageReport(
      idleSnapshot: idleMemory,
      duringInferenceSnapshot: duringInference,
    );
  }

  Future<MemorySnapshot> _captureMemorySnapshot() async {
    final memInfo = await MemoryInfoPlugin.getMemoryInfo();

    return MemorySnapshot(
      totalMemoryMB: memInfo['totalMemoryMB'] ?? 0,
      usedMemoryMB: memInfo['usedMemoryMB'] ?? 0,
      availableMemoryMB: memInfo['availableMemoryMB'] ?? 0,
      dartHeapUsageMB: memInfo['nativeHeapMB'] ?? 0,
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SKENARIO 5 — Pengujian Ukuran Model TFLite
  // ════════════════════════════════════════════════════════════════════════════

  /// Mengukur ukuran file .tflite (Float32 vs INT8).
  ///
  /// [modelPaths] — Map dari nama model ke path file .tflite di filesystem.
  ///
  /// Contoh:
  /// ```dart
  /// {
  ///   'MobileNetV3-Large Float32': '/path/to/mobilenetv3_float32.tflite',
  ///   'MobileNetV3-Large INT8': '/path/to/mobilenetv3_int8.tflite',
  ///   'EfficientNet-Lite0 Float32': '/path/to/efficientnet_float32.tflite',
  ///   'EfficientNet-Lite0 INT8': '/path/to/efficientnet_int8.tflite',
  /// }
  /// ```
  Future<ModelSizeReport> measureModelSizes({
    required Map<String, String> modelPaths,
  }) async {
    onProgress?.call('Skenario 5: Mengukur ukuran model...', 0.5);

    final models = <ModelSizeInfo>[];

    for (final entry in modelPaths.entries) {
      final name = entry.key;
      final path = entry.value;

      double sizeMB = 0;

      // Coba baca dari filesystem
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.length();
        sizeMB = bytes / (1024 * 1024);
      } else {
        // Coba baca dari assets
        try {
          final data = await rootBundle.load(path);
          sizeMB = data.lengthInBytes / (1024 * 1024);
        } catch (_) {
          // File tidak ditemukan
          sizeMB = -1;
        }
      }

      // Tentukan tipe quantization dari nama
      final quantType = name.toLowerCase().contains('int8') ? 'INT8' : 'Float32';
      final modelName = name
          .replaceAll('Float32', '')
          .replaceAll('INT8', '')
          .replaceAll('float32', '')
          .replaceAll('int8', '')
          .trim();

      models.add(ModelSizeInfo(
        modelName: modelName,
        quantizationType: quantType,
        sizeMB: sizeMB,
      ));
    }

    onProgress?.call('Skenario 5: Selesai', 1.0);

    return ModelSizeReport(models: models);
  }

  // ════════════════════════════════════════════════════════════════════════════
  // UTILITY — Export CSV
  // ════════════════════════════════════════════════════════════════════════════

  /// Generate CSV string untuk Skenario 1
  String generateTimingCsv(InferenceTimingReport report) {
    final buffer = StringBuffer();
    buffer.writeln('Image,Class,Avg(ms),Min(ms),Max(ms),StdDev(ms),Repetitions');

    for (final r in report.results) {
      buffer.writeln(
        '${r.imageName},${r.classLabel},'
        '${r.averageMs.toStringAsFixed(2)},'
        '${r.minMs.toStringAsFixed(2)},'
        '${r.maxMs.toStringAsFixed(2)},'
        '${r.stdDevMs.toStringAsFixed(2)},'
        '${r.timingsMs.length}',
      );
    }

    buffer.writeln();
    buffer.writeln('SUMMARY');
    buffer.writeln('Overall Average (ms),${report.overallAverageMs.toStringAsFixed(2)}');
    buffer.writeln('Overall Min (ms),${report.overallMinMs.toStringAsFixed(2)}');
    buffer.writeln('Overall Max (ms),${report.overallMaxMs.toStringAsFixed(2)}');
    buffer.writeln('Overall StdDev (ms),${report.overallStdDevMs.toStringAsFixed(2)}');

    return buffer.toString();
  }

  /// Generate CSV string untuk Skenario 2
  String generateAccuracyCsv(AccuracyReport report) {
    final buffer = StringBuffer();

    // Detail prediksi
    buffer.writeln('Image,True Label,Predicted Label,Confidence,Correct');
    for (final p in report.predictions) {
      buffer.writeln(
        '${p.imageName},${p.trueLabel},${p.predictedLabel},'
        '${(p.confidence * 100).toStringAsFixed(1)}%,'
        '${p.isCorrect ? "Yes" : "No"}',
      );
    }

    buffer.writeln();

    // Per-class accuracy
    buffer.writeln('CLASS ACCURACY');
    buffer.writeln('Class,Total,Correct,Accuracy');
    for (final c in report.perClassAccuracy) {
      buffer.writeln(
        '${c.className},${c.totalImages},${c.correctPredictions},'
        '${(c.accuracy * 100).toStringAsFixed(1)}%',
      );
    }

    buffer.writeln();
    buffer.writeln('Overall Accuracy,${(report.overallAccuracy * 100).toStringAsFixed(1)}%');
    buffer.writeln('Total Images,${report.totalImages}');
    buffer.writeln('Total Correct,${report.totalCorrect}');

    return buffer.toString();
  }

  /// Generate CSV string untuk Skenario 4
  String generateMemoryCsv(MemoryUsageReport report) {
    final buffer = StringBuffer();
    buffer.writeln('Metric,Idle (MB),During Inference (MB),Delta (MB)');
    buffer.writeln(
      'Used Memory,'
      '${report.idleSnapshot.usedMemoryMB.toStringAsFixed(2)},'
      '${report.duringInferenceSnapshot.usedMemoryMB.toStringAsFixed(2)},'
      '${report.deltaUsedMB.toStringAsFixed(2)}',
    );
    buffer.writeln(
      'Dart/Native Heap,'
      '${report.idleSnapshot.dartHeapUsageMB.toStringAsFixed(2)},'
      '${report.duringInferenceSnapshot.dartHeapUsageMB.toStringAsFixed(2)},'
      '${report.deltaDartHeapMB.toStringAsFixed(2)}',
    );
    buffer.writeln(
      'Available Memory,'
      '${report.idleSnapshot.availableMemoryMB.toStringAsFixed(2)},'
      '${report.duringInferenceSnapshot.availableMemoryMB.toStringAsFixed(2)},'
      '${(report.duringInferenceSnapshot.availableMemoryMB - report.idleSnapshot.availableMemoryMB).toStringAsFixed(2)}',
    );
    return buffer.toString();
  }

  /// Generate CSV string untuk Skenario 5
  String generateModelSizeCsv(ModelSizeReport report) {
    final buffer = StringBuffer();
    buffer.writeln('Model,Quantization,Size (MB)');
    for (final m in report.models) {
      buffer.writeln(
        '${m.modelName},${m.quantizationType},${m.sizeMB.toStringAsFixed(2)}',
      );
    }

    // Hitung reduksi per model
    final modelNames = report.models.map((m) => m.modelName).toSet();
    buffer.writeln();
    buffer.writeln('SIZE REDUCTION');
    buffer.writeln('Model,Reduction (%)');
    for (final name in modelNames) {
      final reduction = report.reductionPercentage(name);
      buffer.writeln('$name,${reduction.toStringAsFixed(1)}%');
    }

    return buffer.toString();
  }
}
