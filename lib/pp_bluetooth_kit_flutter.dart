
import 'pp_bluetooth_kit_flutter_platform_interface.dart';

class PpBluetoothKitFlutter {
  Future<String?> getPlatformVersion() {
    return PpBluetoothKitFlutterPlatform.instance.getPlatformVersion();
  }
}
