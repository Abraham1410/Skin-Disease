import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // ── MethodChannel: Memory Info (iOS equivalent of MainActivity.kt) ──
    let controller = window?.rootViewController as! FlutterViewController
    let memoryChannel = FlutterMethodChannel(
      name: "com.skindisease/memory_info",
      binaryMessenger: controller.binaryMessenger
    )

    memoryChannel.setMethodCallHandler { (call, result) in
      if call.method == "getMemoryInfo" {
        result(self.getMemoryInfo())
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Mengambil informasi penggunaan memori di iOS.
  ///
  /// iOS tidak menyediakan API selengkap Android untuk memory info,
  /// tapi kita bisa menggunakan:
  /// - ProcessInfo untuk total RAM
  /// - mach_task_basic_info untuk app memory usage
  private func getMemoryInfo() -> [String: Double] {
    let processInfo = ProcessInfo.processInfo

    // Total RAM perangkat
    let totalMemoryMB = Double(processInfo.physicalMemory) / (1024 * 1024)

    // App memory usage via mach_task_info
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
    let result = withUnsafeMutablePointer(to: &info) {
      $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
        task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
      }
    }

    var usedMemoryMB: Double = 0
    var nativeHeapMB: Double = 0

    if result == KERN_SUCCESS {
      // resident_size = total memory used by the app
      usedMemoryMB = Double(info.resident_size) / (1024 * 1024)
      nativeHeapMB = usedMemoryMB // iOS tidak pisahkan native vs dalvik
    }

    // Available memory (approximate)
    let availableMemoryMB = totalMemoryMB - usedMemoryMB

    return [
      "totalMemoryMB": totalMemoryMB,
      "availableMemoryMB": availableMemoryMB,
      "usedMemoryMB": usedMemoryMB,
      "nativeHeapMB": nativeHeapMB,
      "dalvikHeapMB": 0.0, // Tidak ada Dalvik di iOS
      "totalPssMB": usedMemoryMB, // Gunakan resident_size sebagai approximasi
      "isLowMemory": 0.0,
      "threshold": 0.0
    ]
  }
}
