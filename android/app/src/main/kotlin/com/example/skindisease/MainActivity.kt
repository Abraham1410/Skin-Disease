package com.example.skindisease

import android.app.ActivityManager
import android.content.Context
import android.os.Debug
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.skindisease/memory_info"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getMemoryInfo" -> {
                    result.success(getMemoryInfo())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    /**
     * Mengambil informasi penggunaan memori perangkat dan aplikasi.
     *
     * Returns:
     * - totalMemoryMB: Total RAM perangkat
     * - availableMemoryMB: RAM yang tersedia
     * - usedMemoryMB: RAM yang digunakan (total - available)
     * - nativeHeapMB: Native heap yang dialokasikan aplikasi
     * - dalvikHeapMB: Dalvik/ART heap yang dialokasikan
     * - totalPssMB: Total PSS (Proportional Set Size) aplikasi
     */
    private fun getMemoryInfo(): Map<String, Double> {
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager

        // ─── System-wide memory info ────────────────────────────────────
        val memInfo = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memInfo)

        val totalMemoryMB = memInfo.totalMem.toDouble() / (1024 * 1024)
        val availableMemoryMB = memInfo.availMem.toDouble() / (1024 * 1024)
        val usedMemoryMB = totalMemoryMB - availableMemoryMB

        // ─── App-specific memory info ───────────────────────────────────
        val nativeHeapMB = Debug.getNativeHeapAllocatedSize().toDouble() / (1024 * 1024)
        val dalvikHeapMB = Runtime.getRuntime().let {
            (it.totalMemory() - it.freeMemory()).toDouble() / (1024 * 1024)
        }

        // ─── PSS (Proportional Set Size) ────────────────────────────────
        // PSS memberikan estimasi yang lebih akurat tentang
        // penggunaan memori aplikasi
        var totalPssMB = 0.0
        try {
            val pids = intArrayOf(android.os.Process.myPid())
            val memInfoArray = activityManager.getProcessMemoryInfo(pids)
            if (memInfoArray.isNotEmpty()) {
                totalPssMB = memInfoArray[0].totalPss.toDouble() / 1024 // KB -> MB
            }
        } catch (e: Exception) {
            // Beberapa device mungkin membatasi akses
        }

        return mapOf(
            "totalMemoryMB" to totalMemoryMB,
            "availableMemoryMB" to availableMemoryMB,
            "usedMemoryMB" to usedMemoryMB,
            "nativeHeapMB" to nativeHeapMB,
            "dalvikHeapMB" to dalvikHeapMB,
            "totalPssMB" to totalPssMB,
            "isLowMemory" to if (memInfo.lowMemory) 1.0 else 0.0,
            "threshold" to memInfo.threshold.toDouble() / (1024 * 1024)
        )
    }
}

