///@author liyp
///@email liyp520@foxmail.com
///@date 2025/1/10 11:15
//@description


class PPBluetoothKitLogger {
  static PPBluetoothKitLoggerListener? listener;

  static bool enabled = false;

  static void i(String msg) {
    PPBluetoothKitLogger.listener?.i("[PPSDK]:$msg");
    if (PPBluetoothKitLogger.enabled) {
      print("[PPSDK]:$msg");
    }
  }

  static void addListener(bool isDebug, PPBluetoothKitLoggerListener listener) {
    PPBluetoothKitLogger.enabled = isDebug;
    PPBluetoothKitLogger.listener = listener;
  }
}

abstract class PPBluetoothKitLoggerListener {

  void i(String msg);

}

