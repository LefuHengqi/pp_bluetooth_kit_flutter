import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../enums/pp_scale_enums.dart';
import '../model/pp_device_180a_model.dart';
import '../model/pp_wifi_result.dart';
import '../model/pp_body_base_model.dart';
import '../model/pp_device_model.dart';
import '../model/pp_device_user.dart';
import 'pp_bluetooth_kit_flutter_method_channel.dart';

abstract class PPBluetoothKitFlutterPlatform extends PlatformInterface {
  /// Constructs a PpBluetoothKitFlutterPlatform.
  PPBluetoothKitFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static PPBluetoothKitFlutterPlatform _instance = MethodChannelPpBluetoothKitFlutter();

  /// The default instance of [PpBluetoothKitFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelPpBluetoothKitFlutter].
  static PPBluetoothKitFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PpBluetoothKitFlutterPlatform] when
  /// they register themselves.
  static set instance(PPBluetoothKitFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }


  /// API

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<void> loggerListener(Function(String content) callBack) {
    throw UnimplementedError('stopScan has not been implemented.');
  }

  Future<void> initSDK(String appKey, String appSecret, String filePath) {
    throw UnimplementedError('initSDK has not been implemented.');
  }

  Future<void> setDeviceSetting(String deviceContent) {
    throw UnimplementedError('setDeviceSetting has not been implemented.');
  }

  Future<void> startScan(Function(PPDeviceModel device) callBack) {
    throw UnimplementedError('startScan has not been implemented.');
  }

  Future<void> stopScan() {
    throw UnimplementedError('stopScan has not been implemented.');
  }

  Future<void> connectDevice(PPDeviceModel device, {required Function(PPDeviceConnectionState state) callBack}) {
    throw UnimplementedError('connectDevice has not been implemented.');
  }

  Future<void> disconnect() {
    throw UnimplementedError('disconnect has not been implemented.');
  }

  Future<void> addMeasurementListener({required Function(PPMeasurementDataState measurementState, PPBodyBaseModel dataModel, PPDeviceModel device) callBack}) {
    throw UnimplementedError('addMeasurementListener has not been implemented.');
  }

  Future<void> fetchHistoryData({required Function(List<PPBodyBaseModel> dataList) callBack}) {
    throw UnimplementedError('fetchHistoryData has not been implemented.');
  }

  Future<void> deleteHistoryData() {
    throw UnimplementedError('deleteHistoryData has not been implemented.');
  }

  Future<void> syncUnit(PPDeviceUser deviceUser) {
    throw UnimplementedError('syncUnit has not been implemented.');
  }

  Future<bool?> syncTime({bool is24Hour = true}) {
    throw UnimplementedError('syncTime has not been implemented.');
  }

  Future<PPWifiResult> configWifi({required String domain, required String ssId, required String password}) {
    throw UnimplementedError('configWifi has not been implemented.');
  }

  Future<String?> fetchWifiInfo() {
    throw UnimplementedError('fetchWifiInfo has not been implemented.');
  }

  Future<PPDevice180AModel?> fetchDeviceInfo() {
    throw UnimplementedError('fetchDeviceInfo has not been implemented.');
  }

  Future<void> fetchBatteryInfo({required bool continuity, required Function(int power) callBack}) {
    throw UnimplementedError('fetchBatteryInfo has not been implemented.');
  }

  Future<void> resetDevice() {
    throw UnimplementedError('resetDevice has not been implemented.');
  }

}
