/// Data models untuk seluruh skenario benchmark on-device inference.
///
/// Skenario 1: Inference Time
/// Skenario 2: Akurasi On-Device
/// Skenario 3: CPU Usage (stress test trigger)
/// Skenario 4: RAM Usage
/// Skenario 5: Ukuran Model TFLite

// ══════════════════════════════════════════════════════════════════════════════
// SKENARIO 1 — Inference Time
// ══════════════════════════════════════════════════════════════════════════════

/// Hasil pengukuran waktu inferensi untuk satu citra
class SingleImageTimingResult {
  final String imageName;
  final String classLabel;
  final List<double> timingsMs; // waktu tiap repetisi (ms)

  SingleImageTimingResult({
    required this.imageName,
    required this.classLabel,
    required this.timingsMs,
  });

  double get averageMs =>
      timingsMs.reduce((a, b) => a + b) / timingsMs.length;

  double get minMs =>
      timingsMs.reduce((a, b) => a < b ? a : b);

  double get maxMs =>
      timingsMs.reduce((a, b) => a > b ? a : b);

  double get stdDevMs {
    final mean = averageMs;
    final squaredDiffs = timingsMs.map((t) => (t - mean) * (t - mean));
    return _sqrt(squaredDiffs.reduce((a, b) => a + b) / timingsMs.length);
  }

  Map<String, dynamic> toMap() => {
        'image': imageName,
        'class': classLabel,
        'avg_ms': averageMs.toStringAsFixed(2),
        'min_ms': minMs.toStringAsFixed(2),
        'max_ms': maxMs.toStringAsFixed(2),
        'std_ms': stdDevMs.toStringAsFixed(2),
        'repetitions': timingsMs.length,
      };
}

/// Hasil keseluruhan Skenario 1
class InferenceTimingReport {
  final List<SingleImageTimingResult> results;
  final int repetitionsPerImage;
  final DateTime timestamp;

  InferenceTimingReport({
    required this.results,
    required this.repetitionsPerImage,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  double get overallAverageMs =>
      results.map((r) => r.averageMs).reduce((a, b) => a + b) /
      results.length;

  double get overallMinMs =>
      results.map((r) => r.minMs).reduce((a, b) => a < b ? a : b);

  double get overallMaxMs =>
      results.map((r) => r.maxMs).reduce((a, b) => a > b ? a : b);

  double get overallStdDevMs {
    final allTimings = results.expand((r) => r.timingsMs).toList();
    final mean = allTimings.reduce((a, b) => a + b) / allTimings.length;
    final squaredDiffs = allTimings.map((t) => (t - mean) * (t - mean));
    return _sqrt(squaredDiffs.reduce((a, b) => a + b) / allTimings.length);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SKENARIO 2 — Akurasi On-Device
// ══════════════════════════════════════════════════════════════════════════════

/// Hasil prediksi untuk satu citra
class SinglePredictionResult {
  final String imageName;
  final String trueLabel;
  final String predictedLabel;
  final double confidence;

  SinglePredictionResult({
    required this.imageName,
    required this.trueLabel,
    required this.predictedLabel,
    required this.confidence,
  });

  bool get isCorrect => trueLabel == predictedLabel;
}

/// Akurasi per kelas
class ClassAccuracy {
  final String className;
  final int totalImages;
  final int correctPredictions;

  ClassAccuracy({
    required this.className,
    required this.totalImages,
    required this.correctPredictions,
  });

  double get accuracy =>
      totalImages > 0 ? correctPredictions / totalImages : 0.0;
}

/// Hasil keseluruhan Skenario 2
class AccuracyReport {
  final List<SinglePredictionResult> predictions;
  final List<ClassAccuracy> perClassAccuracy;
  final DateTime timestamp;

  AccuracyReport({
    required this.predictions,
    required this.perClassAccuracy,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  double get overallAccuracy {
    final correct = predictions.where((p) => p.isCorrect).length;
    return predictions.isNotEmpty ? correct / predictions.length : 0.0;
  }

  int get totalCorrect => predictions.where((p) => p.isCorrect).length;
  int get totalImages => predictions.length;

  /// Confusion matrix: map[trueLabel][predictedLabel] = count
  Map<String, Map<String, int>> get confusionMatrix {
    final matrix = <String, Map<String, int>>{};
    final allLabels =
        perClassAccuracy.map((c) => c.className).toSet().toList()..sort();

    for (final trueLabel in allLabels) {
      matrix[trueLabel] = {};
      for (final predLabel in allLabels) {
        matrix[trueLabel]![predLabel] = 0;
      }
    }

    for (final pred in predictions) {
      if (matrix.containsKey(pred.trueLabel) &&
          matrix[pred.trueLabel]!.containsKey(pred.predictedLabel)) {
        matrix[pred.trueLabel]![pred.predictedLabel] =
            (matrix[pred.trueLabel]![pred.predictedLabel] ?? 0) + 1;
      }
    }

    return matrix;
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SKENARIO 3 — CPU Usage (trigger untuk Android Profiler)
// ══════════════════════════════════════════════════════════════════════════════

/// Log entry untuk setiap inferensi selama stress test
class CpuStressEntry {
  final int index;
  final String imageName;
  final double inferenceTimeMs;
  final DateTime startTime;
  final DateTime endTime;

  CpuStressEntry({
    required this.index,
    required this.imageName,
    required this.inferenceTimeMs,
    required this.startTime,
    required this.endTime,
  });
}

/// Hasil Skenario 3
class CpuStressReport {
  final List<CpuStressEntry> entries;
  final DateTime testStartTime;
  final DateTime testEndTime;

  CpuStressReport({
    required this.entries,
    required this.testStartTime,
    required this.testEndTime,
  });

  Duration get totalDuration => testEndTime.difference(testStartTime);

  double get averageInferenceMs =>
      entries.map((e) => e.inferenceTimeMs).reduce((a, b) => a + b) /
      entries.length;
}

// ══════════════════════════════════════════════════════════════════════════════
// SKENARIO 4 — RAM Usage
// ══════════════════════════════════════════════════════════════════════════════

/// Snapshot penggunaan memori
class MemorySnapshot {
  final double totalMemoryMB;
  final double usedMemoryMB;
  final double availableMemoryMB;
  final double dartHeapUsageMB;
  final DateTime timestamp;

  MemorySnapshot({
    required this.totalMemoryMB,
    required this.usedMemoryMB,
    required this.availableMemoryMB,
    required this.dartHeapUsageMB,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Hasil Skenario 4
class MemoryUsageReport {
  final MemorySnapshot idleSnapshot;
  final MemorySnapshot duringInferenceSnapshot;
  final DateTime timestamp;

  MemoryUsageReport({
    required this.idleSnapshot,
    required this.duringInferenceSnapshot,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  double get deltaUsedMB =>
      duringInferenceSnapshot.usedMemoryMB - idleSnapshot.usedMemoryMB;

  double get deltaDartHeapMB =>
      duringInferenceSnapshot.dartHeapUsageMB - idleSnapshot.dartHeapUsageMB;
}

// ══════════════════════════════════════════════════════════════════════════════
// SKENARIO 5 — Ukuran Model TFLite
// ══════════════════════════════════════════════════════════════════════════════

/// Info ukuran satu model
class ModelSizeInfo {
  final String modelName;
  final String quantizationType; // "Float32" atau "INT8"
  final double sizeMB;

  ModelSizeInfo({
    required this.modelName,
    required this.quantizationType,
    required this.sizeMB,
  });
}

/// Hasil Skenario 5
class ModelSizeReport {
  final List<ModelSizeInfo> models;
  final DateTime timestamp;

  ModelSizeReport({
    required this.models,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Persentase reduksi dari Float32 ke INT8 untuk model yang sama
  double reductionPercentage(String modelName) {
    final float32 = models.firstWhere(
      (m) => m.modelName == modelName && m.quantizationType == 'Float32',
      orElse: () => ModelSizeInfo(
          modelName: modelName, quantizationType: 'Float32', sizeMB: 0),
    );
    final int8 = models.firstWhere(
      (m) => m.modelName == modelName && m.quantizationType == 'INT8',
      orElse: () => ModelSizeInfo(
          modelName: modelName, quantizationType: 'INT8', sizeMB: 0),
    );
    if (float32.sizeMB == 0) return 0;
    return ((float32.sizeMB - int8.sizeMB) / float32.sizeMB) * 100;
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// HELPER
// ══════════════════════════════════════════════════════════════════════════════

double _sqrt(double value) {
  if (value <= 0) return 0;
  double guess = value / 2;
  for (int i = 0; i < 50; i++) {
    guess = (guess + value / guess) / 2;
  }
  return guess;
}
