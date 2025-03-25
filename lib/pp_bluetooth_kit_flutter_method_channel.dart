import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'pp_bluetooth_kit_flutter_platform_interface.dart';

/// An implementation of [PpBluetoothKitFlutterPlatform] that uses method channels.
class MethodChannelPpBluetoothKitFlutter extends PpBluetoothKitFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('pp_bluetooth_kit_flutter');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
