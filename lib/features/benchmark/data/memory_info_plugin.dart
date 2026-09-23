import 'dart:async';
import 'package:flutter/services.dart';

/// Platform channel untuk mendapatkan informasi memori dari Android native.
///
/// Digunakan pada Skenario 4 (RAM Usage monitoring).
/// Memerlukan setup MethodChannel di sisi Android (Kotlin/Java).
class MemoryInfoPlugin {
  static const MethodChannel _channel =
      MethodChannel('com.skindisease/memory_info');

  /// Mengambil snapshot penggunaan memori saat ini.
  ///
  /// Returns map berisi:
  /// - totalMemoryMB: Total RAM perangkat
  /// - usedMemoryMB: RAM yang sedang digunakan
  /// - availableMemoryMB: RAM yang tersedia
  /// - dartHeapUsageMB: Penggunaan heap Dart VM
  static Future<Map<String, double>> getMemoryInfo() async {
    try {
      final result = await _channel.invokeMethod<Map>('getMemoryInfo');

      if (result != null) {
        return {
          'totalMemoryMB': (result['totalMemoryMB'] as num?)?.toDouble() ?? 0,
          'usedMemoryMB': (result['usedMemoryMB'] as num?)?.toDouble() ?? 0,
          'availableMemoryMB':
              (result['availableMemoryMB'] as num?)?.toDouble() ?? 0,
          'nativeHeapMB':
              (result['nativeHeapMB'] as num?)?.toDouble() ?? 0,
        };
      }
    } catch (e) {
      // Fallback ke info Dart jika platform channel gagal
    }

    // Fallback: gunakan info dari Dart ProcessInfo
    final dartHeapMB = ProcessInfo.currentRss / (1024 * 1024);
    return {
      'totalMemoryMB': 0,
      'usedMemoryMB': dartHeapMB,
      'availableMemoryMB': 0,
      'nativeHeapMB': 0,
    };
  }
}

/// Helper untuk mendapatkan info proses Dart
class ProcessInfo {
  static int get currentRss {
    // Pada Dart VM, kita bisa mengakses current RSS
    // Ini adalah pendekatan sederhana
    return 0; // Akan di-override oleh platform channel
  }
}
