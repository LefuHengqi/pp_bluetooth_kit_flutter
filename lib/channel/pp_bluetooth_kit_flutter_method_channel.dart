import 'dart:async';
import 'package:flutter/services.dart';
import 'package:pp_bluetooth_kit_flutter/enums/pp_scale_enums.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_body_base_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_180a_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_user.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_wifi_result.dart';
import 'package:pp_bluetooth_kit_flutter/utils/pp_bluetooth_kit_logger.dart';


import 'pp_bluetooth_kit_flutter_platform_interface.dart';

/// An implementation of [PpBluetoothKitFlutterPlatform] that uses method channels.
class MethodChannelPpBluetoothKitFlutter extends PPBluetoothKitFlutterPlatform {

  StreamSubscription? _logSubscription;
  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectSubscription;
  StreamSubscription? _measurementSubscription;
  StreamSubscription? _historySubscription;
  StreamSubscription? _batterySubscription;
  StreamSubscription? _blePermissionSubscription;

  final methodChannel = const MethodChannel('pp_bluetooth_kit_flutter');

  final _bleChannel = const MethodChannel('pp_ble_channel');
  
  final _loggerEvent = const EventChannel('pp_logger_streams');
  final _scanResultEvent = const EventChannel('pp_device_list_streams');
  final _connectStateEvent = const EventChannel('pp_connect_state_streams');
  final _measurementDataEvent = const EventChannel('pp_measurement_streams');
  final _historyDataEvent = const EventChannel('pp_history_data_streams');
  final _batteryEvent = const EventChannel('pp_battery_streams');
  final _blePermissionEvent = const EventChannel('pp_ble_permission_streams');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<void> loggerListener(Function(String content) callBack) async {
    _logSubscription?.cancel();
    _logSubscription = _loggerEvent.receiveBroadcastStream().listen((event) {
      final content = '$event';
      PPBluetoothKitLogger.i(content);

    });

  }

  @override
  Future<void> initSDK(String appKey, String appSecret, String filePath) async {
    // PPBluetoothKitLogger.i('执行initSDK appKey:$appKey appSecret:$appSecret filePath:$filePath');
    await _bleChannel.invokeMethod('initSDK',<String, dynamic>{'appKey': appKey, 'appSecret': appSecret, 'filePath':filePath});
  }

  @override
  Future<void> setDeviceSetting(String deviceContent) async {
    // PPBluetoothKitLogger.i('执行setDeviceSetting');
    await _bleChannel.invokeMethod('setDeviceSetting',<String, dynamic>{'deviceContent':deviceContent});
  }

  @override
  Future<void> startScan(Function(PPDeviceModel device) callBack) async {
    _scanSubscription?.cancel();
    _scanSubscription = _scanResultEvent.receiveBroadcastStream().listen((event) {

      if (event is Map){
        try {

          final retJson = event.cast<String, dynamic>();
          PPDeviceModel model =PPDeviceModel.fromJson(retJson);
          callBack(model);

        } catch(e) {
          PPBluetoothKitLogger.i('设备返回结果异常:$e');
        }
      } else {
        PPBluetoothKitLogger.i('设备返回数据格式不正确');
      }
    });

    // PPBluetoothKitLogger.i('执行 开启扫描');
    await _bleChannel.invokeMethod('startScan');
  }

  @override
  Future<void> stopScan() async {
    // PPBluetoothKitLogger.i('执行 停止扫描');
    await _bleChannel.invokeMethod('stopScan');
  }

  @override
  Future<void> connectDevice(PPDeviceModel device, {required Function(PPDeviceConnectionState state) callBack}) async {
    final deviceMac = device.deviceMac;
    final deviceName = device.deviceName;

    if (deviceMac == null || deviceMac.isEmpty) {
      callBack(PPDeviceConnectionState.error);
      PPBluetoothKitLogger.i('deviceMac 为空');
      return;
    }
    if (deviceName == null || deviceName.isEmpty) {
      callBack(PPDeviceConnectionState.error);
      PPBluetoothKitLogger.i('deviceName 为空');
      return;
    }

    _connectSubscription?.cancel();
    _connectSubscription = _connectStateEvent.receiveBroadcastStream().listen((event) {
      if (event is Map){
        try {

          final retJson = event.cast<String, dynamic>();
          int state = retJson['state'] as int;
          if (state == 0) {
            callBack(PPDeviceConnectionState.disconnected);
          } else if (state == 1) {
            callBack(PPDeviceConnectionState.connected);
          } else if (state == 2) {
            callBack(PPDeviceConnectionState.error);
          } else {
            callBack(PPDeviceConnectionState.undefine);
          }

        } catch(e) {
          PPBluetoothKitLogger.i('连接状态-返回结果异常:$e');
        }
      } else {
        PPBluetoothKitLogger.i('连接状态-返回数据格式不正确');
      }
    });

    // PPBluetoothKitLogger.i('执行connectDevice');
    await _bleChannel.invokeMethod('connectDevice',<String, dynamic>{'deviceMac': deviceMac, 'deviceName': deviceName});

  }
  
  @override
  Future<void> disconnect() async {
    // PPBluetoothKitLogger.i('执行disconnect');
    await _bleChannel.invokeMethod("disconnect");
  }

  @override
  Future<void> addMeasurementListener({required Function(PPMeasurementDataState measurementState, PPBodyBaseModel dataModel, PPDeviceModel device) callBack}) async {
    // PPBluetoothKitLogger.i('执行addMeasurementListener');
    _measurementSubscription?.cancel();
    _measurementSubscription = _measurementDataEvent.receiveBroadcastStream().listen((event) {
      if (event is Map){
        try {

          final retJson = event.cast<String, dynamic>();
          final stateCode = retJson['measurementState'] as int;
          final device = retJson['device'].cast<String, dynamic>();
          final data = retJson['data'].cast<String, dynamic>();

          var state = PPMeasurementDataState.processData;
          switch (stateCode) {
            case 1:
              state = PPMeasurementDataState.measuringBodyFat;
              break;
            case 2:
              state = PPMeasurementDataState.measuringHeartRate;
              break;
            case 10:
              state = PPMeasurementDataState.completed;
              break;
          }

          final model = PPBodyBaseModel.fromJson(data);
          final deviceModel = PPDeviceModel.fromJson(device);

          callBack(state, model, deviceModel);

        } catch(e) {
          PPBluetoothKitLogger.i('测量数据-返回结果异常:$e');
        }
      } else {
        PPBluetoothKitLogger.i('测量数据-返回数据格式不正确');
      }
    });
  }
  
  
  @override
  Future<void> fetchHistoryData({required Function(List<PPBodyBaseModel> dataList) callBack}) async {
    _historySubscription?.cancel();
    _historySubscription = _historyDataEvent.receiveBroadcastStream().listen((event) {
      if (event is Map){
        try {

          final retList = <PPBodyBaseModel>[];
          final retJson = event.cast<String, dynamic>();
          final array = retJson['dataList'] as List;
          if (array.isNotEmpty) {

            for(int i = 0; i < array.length; ++i) {
              final map = array[i].cast<String, dynamic>();
              final model = PPBodyBaseModel.fromJson(map);
              retList.add(model);
            }
          }

          callBack(retList);

        } catch(e) {
          PPBluetoothKitLogger.i('历史数据-返回结果异常:$e');

          callBack([]);
        }
      } else {
        PPBluetoothKitLogger.i('历史数据-返回数据格式不正确');

        callBack([]);
      }

      // 返回数据，则不需要订阅
      _historySubscription?.cancel();

    });

    // PPBluetoothKitLogger.i('执行fetchHistoryData');
    await _bleChannel.invokeMethod('fetchHistory');
  }

  @override
  Future<void> deleteHistoryData() async {
    // PPBluetoothKitLogger.i('执行deleteHistoryData');
    await _bleChannel.invokeMethod('deleteHistory');
  }
  
  @override
  Future<void> syncUnit(PPDeviceUser deviceUser) async {
    // PPBluetoothKitLogger.i('执行 同步单位');

    await _bleChannel.invokeMethod("syncUnit",<String, dynamic>{
      'unit': deviceUser.unitType.type,
      'sex': deviceUser.sex.type,
      'age':deviceUser.age,
      'height':deviceUser.userHeight,
      'isPregnantMode':deviceUser.isPregnantMode,
      'isAthleteMode':deviceUser.isAthleteMode
    });

  }
  
  @override
  Future<bool?> syncTime({bool is24Hour = true}) async {
    // PPBluetoothKitLogger.i('执行 同步时间');

    try {

      final ret = await _bleChannel.invokeMethod<Map>('syncTime');
      final retJson = ret?.cast<String, dynamic>();
      final state = (retJson?["state"] as int? ) ?? 0;

      return state == 1;
    } catch(e) {
      PPBluetoothKitLogger.i('同步时间-返回结果异常:$e');

      return false;
    }

  }

  @override
  Future<PPWifiResult> configWifi({required String domain, required String ssId, required String password}) async {
    // PPBluetoothKitLogger.i('执行 配网-域名:$domain wifi:$ssId');

    try {

      final ret = await _bleChannel.invokeMethod<Map>('configWifi',<String, dynamic>{
        'domain': domain,
        'ssId': ssId,
        'password':password
      });

      final retJson = ret?.cast<String, dynamic>();
      final success = retJson?["success"] as bool? ?? false;
      final sn = retJson?["sn"] as String?;
      final errorCode = retJson?["errorCode"] as int?;

      final retObj = PPWifiResult(success:success, sn: sn, errorCode: errorCode);

      return retObj;
    } catch(e) {

      PPBluetoothKitLogger.i('配网-返回结果异常:$e');
      return PPWifiResult(success:false,sn: null, errorCode: -1);
    }
  }

  @override
  Future<String?> fetchWifiInfo() async {
    // PPBluetoothKitLogger.i('执行 获取配网信息');

    try {

      final ret = await _bleChannel.invokeMethod<Map>('fetchWifiInfo');

      final retJson = ret?.cast<String, dynamic>();
      final ssId = retJson?["ssId"] as String?;

      return ssId;
    } catch(e) {

      PPBluetoothKitLogger.i('配网-返回结果异常:$e');
      return null;
    }

  }

  @override
  Future<PPDevice180AModel?> fetchDeviceInfo() async {
    // PPBluetoothKitLogger.i('执行 获取设备信息');

    try {

      final ret = await _bleChannel.invokeMethod<Map>('fetchDeviceInfo');
      final retJson = ret?.cast<String, dynamic>();
      final modelNumber = retJson?["modelNumber"] as String?;
      final firmwareRevision = retJson?["firmwareRevision"] as String?;
      final softwareRevision = retJson?["softwareRevision"] as String?;
      final hardwareRevision = retJson?["hardwareRevision"] as String?;
      final serialNumber = retJson?["serialNumber"] as String?;
      final manufacturerName = retJson?["manufacturerName"] as String?;

      final retObj = PPDevice180AModel(modelNumber: modelNumber,
          firmwareRevision: firmwareRevision,
          softwareRevision: softwareRevision,
          hardwareRevision: hardwareRevision,
          serialNumber: serialNumber,
          manufacturerName:
          manufacturerName);

      return retObj;
    } catch(e) {

      PPBluetoothKitLogger.i('获取设备信息-返回结果异常:$e');
      return null;
    }
  }

  @override
  Future<void> fetchBatteryInfo({required bool continuity, required Function(int power) callBack}) async {

    _batterySubscription?.cancel();
    _batterySubscription = _batteryEvent.receiveBroadcastStream().listen((event) {
      if (continuity == false) {
        _batterySubscription?.cancel();
      }

      if (event is Map){
        try {

          final retJson = event.cast<String, dynamic>();
          final power = retJson['power'] as int? ?? 0;
          callBack(power);

        } catch(e) {
          PPBluetoothKitLogger.i('获取电量-返回结果异常:$e');
          callBack(0);
        }
      } else {
        PPBluetoothKitLogger.i('获取电量-返回数据格式不正确');

        callBack(0);
      }

    });

    await _bleChannel.invokeMethod<Map>('fetchBatteryInfo');
  }

  @override
  Future<void> resetDevice() async {
    _bleChannel.invokeMethod<Map>('resetDevice');
  }

  @override
  Future<PPDeviceModel?> fetchConnectedDevice() async {
    try {

      final ret = await _bleChannel.invokeMethod('fetchConnectedDevice');
      if (ret is Map) {

        final retJson = ret.cast<String, dynamic>();
        PPDeviceModel model =PPDeviceModel.fromJson(retJson);
        if (model.deviceMac != null) {

          return model;
        } else {

          return null;
        }

      } else {
        return null;
      }
    } catch(e) {
      PPBluetoothKitLogger.i('获取已连接的设备-返回结果异常:$e');

      return null;
    }

  }

  @override
  Future<void> blePermissionListener({required Function(PPBlePermissionState state) callBack}) async {

    _blePermissionSubscription?.cancel();
    _blePermissionSubscription = _blePermissionEvent.receiveBroadcastStream().listen((event) {

      if (event is Map){
        try {

          final retJson = event.cast<String, dynamic>();
          final stateValue = retJson['state'] as int? ?? 0;
          final state = PPBlePermissionState.fromInt(stateValue);
          callBack(state);

        } catch(e) {

          PPBluetoothKitLogger.i('蓝牙权限变化-监听结果异常:$e');
          callBack(PPBlePermissionState.unknown);
        }
      } else {

        PPBluetoothKitLogger.i('蓝牙权限变化-返回数据格式不正确');
        callBack(PPBlePermissionState.unknown);
      }

    });

    _bleChannel.invokeMethod('addBlePermissionListener');

  }

}
