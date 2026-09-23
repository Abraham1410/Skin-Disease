import 'package:flutter/material.dart';

import 'package:skindisease/features/benchmark/data/benchmark_models.dart';

/// Screen untuk menampilkan hasil benchmark dalam format tabel detail.
///
/// Menampilkan hasil dari seluruh skenario uji coba dalam format
/// yang sesuai untuk dokumentasi penelitian (Tabel 3.24).
class BenchmarkResultDetailScreen extends StatelessWidget {
  final InferenceTimingReport? timingReport;
  final AccuracyReport? accuracyReport;
  final CpuStressReport? cpuReport;
  final MemoryUsageReport? memoryReport;
  final ModelSizeReport? modelSizeReport;

  const BenchmarkResultDetailScreen({
    super.key,
    this.timingReport,
    this.accuracyReport,
    this.cpuReport,
    this.memoryReport,
    this.modelSizeReport,
  });

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF1C3D1E);
    const Color bg = Color(0xFFF4F8F5);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text(
          'Hasil Benchmark',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (timingReport != null) ...[
              _buildTimingTable(),
              const SizedBox(height: 24),
            ],
            if (accuracyReport != null) ...[
              _buildAccuracyTable(),
              const SizedBox(height: 24),
              _buildConfusionMatrix(),
              const SizedBox(height: 24),
            ],
            if (cpuReport != null) ...[
              _buildCpuTable(),
              const SizedBox(height: 24),
            ],
            if (memoryReport != null) ...[
              _buildMemoryTable(),
              const SizedBox(height: 24),
            ],
            if (modelSizeReport != null) ...[
              _buildModelSizeTable(),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TABEL SKENARIO 1 — Inference Time
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTimingTable() {
    final report = timingReport!;

    return _ResultCard(
      title: 'Skenario 1 — Kecepatan Inferensi',
      icon: Icons.speed_rounded,
      child: Column(
        children: [
          // Summary row
          _SummaryRow(
            items: [
              _SummaryItem(
                label: 'Rata-rata',
                value: '${report.overallAverageMs.toStringAsFixed(2)} ms',
              ),
              _SummaryItem(
                label: 'Min',
                value: '${report.overallMinMs.toStringAsFixed(2)} ms',
              ),
              _SummaryItem(
                label: 'Max',
                value: '${report.overallMaxMs.toStringAsFixed(2)} ms',
              ),
              _SummaryItem(
                label: 'Std Dev',
                value: '${report.overallStdDevMs.toStringAsFixed(2)} ms',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Detail table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor:
                  WidgetStateProperty.all(const Color(0xFFE8F5E9)),
              columnSpacing: 20,
              dataRowMinHeight: 36,
              dataRowMaxHeight: 40,
              columns: const [
                DataColumn(label: Text('No', style: _headerStyle)),
                DataColumn(label: Text('Citra', style: _headerStyle)),
                DataColumn(label: Text('Kelas', style: _headerStyle)),
                DataColumn(
                    label: Text('Avg (ms)', style: _headerStyle),
                    numeric: true),
                DataColumn(
                    label: Text('Min (ms)', style: _headerStyle),
                    numeric: true),
                DataColumn(
                    label: Text('Max (ms)', style: _headerStyle),
                    numeric: true),
                DataColumn(
                    label: Text('Std (ms)', style: _headerStyle),
                    numeric: true),
              ],
              rows: report.results.asMap().entries.map((entry) {
                final i = entry.key;
                final r = entry.value;
                return DataRow(cells: [
                  DataCell(Text('${i + 1}', style: _cellStyle)),
                  DataCell(Text(
                    r.imageName.length > 20
                        ? '${r.imageName.substring(0, 17)}...'
                        : r.imageName,
                    style: _cellStyle,
                  )),
                  DataCell(Text(r.classLabel, style: _cellStyle)),
                  DataCell(Text(r.averageMs.toStringAsFixed(2),
                      style: _cellStyle)),
                  DataCell(
                      Text(r.minMs.toStringAsFixed(2), style: _cellStyle)),
                  DataCell(
                      Text(r.maxMs.toStringAsFixed(2), style: _cellStyle)),
                  DataCell(
                      Text(r.stdDevMs.toStringAsFixed(2), style: _cellStyle)),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TABEL SKENARIO 2 — Akurasi
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAccuracyTable() {
    final report = accuracyReport!;

    return _ResultCard(
      title: 'Skenario 2 — Akurasi Deteksi On-Device',
      icon: Icons.gps_fixed,
      child: Column(
        children: [
          _SummaryRow(
            items: [
              _SummaryItem(
                label: 'Overall Accuracy',
                value:
                    '${(report.overallAccuracy * 100).toStringAsFixed(1)}%',
                isHighlighted: true,
              ),
              _SummaryItem(
                label: 'Benar',
                value: '${report.totalCorrect}/${report.totalImages}',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Per-class accuracy table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor:
                  WidgetStateProperty.all(const Color(0xFFE8F5E9)),
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Text('Kelas', style: _headerStyle)),
                DataColumn(
                    label: Text('Total', style: _headerStyle), numeric: true),
                DataColumn(
                    label: Text('Benar', style: _headerStyle), numeric: true),
                DataColumn(
                    label: Text('Akurasi', style: _headerStyle),
                    numeric: true),
              ],
              rows: report.perClassAccuracy.map((c) {
                final pct = (c.accuracy * 100).toStringAsFixed(1);
                return DataRow(cells: [
                  DataCell(Text(c.className, style: _cellStyle)),
                  DataCell(
                      Text('${c.totalImages}', style: _cellStyle)),
                  DataCell(Text('${c.correctPredictions}',
                      style: _cellStyle)),
                  DataCell(Text(
                    '$pct%',
                    style: _cellStyle.copyWith(
                      color: c.accuracy >= 0.8
                          ? const Color(0xFF2D7A3A)
                          : c.accuracy >= 0.5
                              ? const Color(0xFFD4880A)
                              : const Color(0xFFC0392B),
                      fontWeight: FontWeight.w700,
                    ),
                  )),
                ]);
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Detail prediksi
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Detail Prediksi',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor:
                  WidgetStateProperty.all(const Color(0xFFF5F5F5)),
              columnSpacing: 16,
              dataRowMinHeight: 36,
              dataRowMaxHeight: 40,
              columns: const [
                DataColumn(label: Text('No', style: _headerStyle)),
                DataColumn(label: Text('Citra', style: _headerStyle)),
                DataColumn(label: Text('Label Asli', style: _headerStyle)),
                DataColumn(label: Text('Prediksi', style: _headerStyle)),
                DataColumn(
                    label: Text('Confidence', style: _headerStyle),
                    numeric: true),
                DataColumn(label: Text('Status', style: _headerStyle)),
              ],
              rows: report.predictions.asMap().entries.map((entry) {
                final i = entry.key;
                final p = entry.value;
                return DataRow(
                  color: WidgetStateProperty.all(
                    p.isCorrect
                        ? Colors.transparent
                        : const Color(0xFFFFF3F3),
                  ),
                  cells: [
                    DataCell(Text('${i + 1}', style: _cellStyle)),
                    DataCell(Text(
                      p.imageName.length > 18
                          ? '${p.imageName.substring(0, 15)}...'
                          : p.imageName,
                      style: _cellStyle,
                    )),
                    DataCell(Text(p.trueLabel, style: _cellStyle)),
                    DataCell(Text(p.predictedLabel, style: _cellStyle)),
                    DataCell(Text(
                      '${(p.confidence * 100).toStringAsFixed(1)}%',
                      style: _cellStyle,
                    )),
                    DataCell(Icon(
                      p.isCorrect
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: p.isCorrect
                          ? const Color(0xFF2D7A3A)
                          : const Color(0xFFC0392B),
                      size: 18,
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONFUSION MATRIX
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildConfusionMatrix() {
    final report = accuracyReport!;
    final matrix = report.confusionMatrix;
    final labels = matrix.keys.toList()..sort();

    return _ResultCard(
      title: 'Confusion Matrix ${labels.length}×${labels.length}',
      icon: Icons.grid_on_rounded,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                const SizedBox(
                  width: 100,
                  child: Text(
                    'Actual ↓ / Pred →',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF888888),
                    ),
                  ),
                ),
                ...labels.map((l) => SizedBox(
                      width: 60,
                      child: Text(
                        l.length > 7 ? '${l.substring(0, 6)}.' : l,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    )),
              ],
            ),
            const Divider(height: 8),

            // Matrix rows
            ...labels.map((trueLabel) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        trueLabel.length > 12
                            ? '${trueLabel.substring(0, 11)}.'
                            : trueLabel,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    ...labels.map((predLabel) {
                      final count = matrix[trueLabel]?[predLabel] ?? 0;
                      final isDiagonal = trueLabel == predLabel;
                      return Container(
                        width: 60,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDiagonal
                              ? count > 0
                                  ? const Color(0xFFE8F5E9)
                                  : const Color(0xFFFFF8E1)
                              : count > 0
                                  ? const Color(0xFFFFF3F3)
                                  : Colors.transparent,
                          border: Border.all(
                            color: const Color(0xFFE0E0E0),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                count > 0 ? FontWeight.w700 : FontWeight.w400,
                            color: isDiagonal
                                ? const Color(0xFF2D7A3A)
                                : count > 0
                                    ? const Color(0xFFC0392B)
                                    : const Color(0xFFCCCCCC),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TABEL SKENARIO 3 — CPU Stress Test
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCpuTable() {
    final report = cpuReport!;

    return _ResultCard(
      title: 'Skenario 3 — CPU Stress Test',
      icon: Icons.memory_rounded,
      child: Column(
        children: [
          _SummaryRow(
            items: [
              _SummaryItem(
                label: 'Total Durasi',
                value: '${report.totalDuration.inMilliseconds} ms',
              ),
              _SummaryItem(
                label: 'Avg Inferensi',
                value: '${report.averageInferenceMs.toStringAsFixed(2)} ms',
              ),
            ],
          ),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8EC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE8C87A)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFFD4880A), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Untuk data CPU Usage (%) yang akurat, gunakan tab CPU '
                    'pada Android Studio Profiler saat menjalankan skenario ini.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF7A5200)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor:
                  WidgetStateProperty.all(const Color(0xFFE8F5E9)),
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Text('#', style: _headerStyle)),
                DataColumn(label: Text('Citra', style: _headerStyle)),
                DataColumn(
                    label: Text('Waktu (ms)', style: _headerStyle),
                    numeric: true),
                DataColumn(
                    label: Text('Timestamp', style: _headerStyle)),
              ],
              rows: report.entries.map((e) {
                return DataRow(cells: [
                  DataCell(Text('${e.index}', style: _cellStyle)),
                  DataCell(Text(
                    e.imageName.length > 20
                        ? '${e.imageName.substring(0, 17)}...'
                        : e.imageName,
                    style: _cellStyle,
                  )),
                  DataCell(Text(
                    e.inferenceTimeMs.toStringAsFixed(2),
                    style: _cellStyle,
                  )),
                  DataCell(Text(
                    '${e.startTime.hour}:${e.startTime.minute}:'
                    '${e.startTime.second}.${e.startTime.millisecond}',
                    style: _cellStyle.copyWith(fontSize: 10),
                  )),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TABEL SKENARIO 4 — RAM Usage
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMemoryTable() {
    final report = memoryReport!;

    return _ResultCard(
      title: 'Skenario 4 — Penggunaan Memori (RAM)',
      icon: Icons.storage_rounded,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor:
              WidgetStateProperty.all(const Color(0xFFE8F5E9)),
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text('Metrik', style: _headerStyle)),
            DataColumn(
                label: Text('Idle (MB)', style: _headerStyle),
                numeric: true),
            DataColumn(
                label: Text('Inferensi (MB)', style: _headerStyle),
                numeric: true),
            DataColumn(
                label: Text('Delta (MB)', style: _headerStyle),
                numeric: true),
          ],
          rows: [
            DataRow(cells: [
              const DataCell(Text('Used Memory', style: _cellStyle)),
              DataCell(Text(
                report.idleSnapshot.usedMemoryMB.toStringAsFixed(2),
                style: _cellStyle,
              )),
              DataCell(Text(
                report.duringInferenceSnapshot.usedMemoryMB
                    .toStringAsFixed(2),
                style: _cellStyle,
              )),
              DataCell(Text(
                report.deltaUsedMB.toStringAsFixed(2),
                style: _cellStyle.copyWith(
                  color: const Color(0xFFD4880A),
                  fontWeight: FontWeight.w700,
                ),
              )),
            ]),
            DataRow(cells: [
              const DataCell(
                  Text('Native Heap', style: _cellStyle)),
              DataCell(Text(
                report.idleSnapshot.dartHeapUsageMB.toStringAsFixed(2),
                style: _cellStyle,
              )),
              DataCell(Text(
                report.duringInferenceSnapshot.dartHeapUsageMB
                    .toStringAsFixed(2),
                style: _cellStyle,
              )),
              DataCell(Text(
                report.deltaDartHeapMB.toStringAsFixed(2),
                style: _cellStyle.copyWith(
                  color: const Color(0xFFD4880A),
                  fontWeight: FontWeight.w700,
                ),
              )),
            ]),
            DataRow(cells: [
              const DataCell(
                  Text('Available Memory', style: _cellStyle)),
              DataCell(Text(
                report.idleSnapshot.availableMemoryMB.toStringAsFixed(2),
                style: _cellStyle,
              )),
              DataCell(Text(
                report.duringInferenceSnapshot.availableMemoryMB
                    .toStringAsFixed(2),
                style: _cellStyle,
              )),
              DataCell(Text(
                (report.duringInferenceSnapshot.availableMemoryMB -
                        report.idleSnapshot.availableMemoryMB)
                    .toStringAsFixed(2),
                style: _cellStyle,
              )),
            ]),
            DataRow(cells: [
              const DataCell(Text('Total Memory',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A)))),
              DataCell(Text(
                report.idleSnapshot.totalMemoryMB.toStringAsFixed(2),
                style: _cellStyle,
              )),
              DataCell(Text(
                report.duringInferenceSnapshot.totalMemoryMB
                    .toStringAsFixed(2),
                style: _cellStyle,
              )),
              const DataCell(Text('-', style: _cellStyle)),
            ]),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TABEL SKENARIO 5 — Ukuran Model
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildModelSizeTable() {
    final report = modelSizeReport!;

    return _ResultCard(
      title: 'Skenario 5 — Ukuran Model TFLite',
      icon: Icons.sd_card_rounded,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor:
                  WidgetStateProperty.all(const Color(0xFFE8F5E9)),
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Text('Model', style: _headerStyle)),
                DataColumn(
                    label: Text('Quantization', style: _headerStyle)),
                DataColumn(
                    label: Text('Ukuran (MB)', style: _headerStyle),
                    numeric: true),
              ],
              rows: report.models.map((m) {
                return DataRow(cells: [
                  DataCell(Text(m.modelName, style: _cellStyle)),
                  DataCell(Text(
                    m.quantizationType,
                    style: _cellStyle.copyWith(
                      color: m.quantizationType == 'INT8'
                          ? const Color(0xFF2D7A3A)
                          : const Color(0xFF1A1A1A),
                    ),
                  )),
                  DataCell(Text(
                    m.sizeMB >= 0
                        ? m.sizeMB.toStringAsFixed(2)
                        : 'N/A',
                    style: _cellStyle,
                  )),
                ]);
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Reduction summary
          ...report.models
              .map((m) => m.modelName)
              .toSet()
              .map((name) {
            final reduction = report.reductionPercentage(name);
            if (reduction <= 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.trending_down,
                      color: Color(0xFF2D7A3A), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '$name: reduksi ${reduction.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D7A3A),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STYLES
  // ═══════════════════════════════════════════════════════════════════════════

  static const TextStyle _headerStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: Color(0xFF1C3D1E),
  );

  static const TextStyle _cellStyle = TextStyle(
    fontSize: 12,
    color: Color(0xFF444444),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

class _ResultCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _ResultCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF3A7D44), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final List<_SummaryItem> items;

  const _SummaryRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items
          .map((item) => Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: item.isHighlighted
                        ? const Color(0xFF3A7D44)
                        : const Color(0xFFF0F7F1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: item.isHighlighted
                              ? Colors.white70
                              : const Color(0xFF7A9E82),
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        child: Text(
                          item.value,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: item.isHighlighted
                                ? Colors.white
                                : const Color(0xFF1C3D1E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _SummaryItem {
  final String label;
  final String value;
  final bool isHighlighted;

  const _SummaryItem({
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });
}
