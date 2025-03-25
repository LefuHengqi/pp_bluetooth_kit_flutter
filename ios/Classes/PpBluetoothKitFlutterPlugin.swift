import Flutter
import UIKit

public class PpBluetoothKitFlutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "pp_bluetooth_kit_flutter", binaryMessenger: registrar.messenger())
    let instance = PpBluetoothKitFlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS 桥接返回结果:" + UIDevice.current.systemVersion)
  }
}
