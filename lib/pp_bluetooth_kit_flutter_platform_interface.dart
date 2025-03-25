import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'pp_bluetooth_kit_flutter_method_channel.dart';

abstract class PpBluetoothKitFlutterPlatform extends PlatformInterface {
  /// Constructs a PpBluetoothKitFlutterPlatform.
  PpBluetoothKitFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static PpBluetoothKitFlutterPlatform _instance = MethodChannelPpBluetoothKitFlutter();

  /// The default instance of [PpBluetoothKitFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelPpBluetoothKitFlutter].
  static PpBluetoothKitFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PpBluetoothKitFlutterPlatform] when
  /// they register themselves.
  static set instance(PpBluetoothKitFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
