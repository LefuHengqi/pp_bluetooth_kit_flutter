import 'package:flutter_test/flutter_test.dart';
import 'package:pp_bluetooth_kit_flutter/pp_bluetooth_kit_flutter.dart';
import 'package:pp_bluetooth_kit_flutter/pp_bluetooth_kit_flutter_platform_interface.dart';
import 'package:pp_bluetooth_kit_flutter/pp_bluetooth_kit_flutter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPpBluetoothKitFlutterPlatform
    with MockPlatformInterfaceMixin
    implements PpBluetoothKitFlutterPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final PpBluetoothKitFlutterPlatform initialPlatform = PpBluetoothKitFlutterPlatform.instance;

  test('$MethodChannelPpBluetoothKitFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelPpBluetoothKitFlutter>());
  });

  test('getPlatformVersion', () async {
    PpBluetoothKitFlutter ppBluetoothKitFlutterPlugin = PpBluetoothKitFlutter();
    MockPpBluetoothKitFlutterPlatform fakePlatform = MockPpBluetoothKitFlutterPlatform();
    PpBluetoothKitFlutterPlatform.instance = fakePlatform;

    expect(await ppBluetoothKitFlutterPlugin.getPlatformVersion(), '42');
  });
}
