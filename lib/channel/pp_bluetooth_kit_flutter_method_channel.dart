import 'dart:async';
import 'dart:ffi';
import 'package:flutter/services.dart';
import 'package:pp_bluetooth_kit_flutter/enums/pp_scale_enums.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_body_base_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_180a_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_user.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_torre_user_model.dart';
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
  StreamSubscription? _dfuSubscription;
  StreamSubscription? _deviceLogSubscription;
  StreamSubscription? _scanStateSubscription;

  final methodChannel = const MethodChannel('pp_bluetooth_kit_flutter');

  final _bleChannel = const MethodChannel('pp_ble_channel');
  
  final _loggerEvent = const EventChannel('pp_logger_streams');
  final _scanResultEvent = const EventChannel('pp_device_list_streams');
  final _connectStateEvent = const EventChannel('pp_connect_state_streams');
  final _measurementDataEvent = const EventChannel('pp_measurement_streams');
  final _historyDataEvent = const EventChannel('pp_history_data_streams');
  final _batteryEvent = const EventChannel('pp_battery_streams');
  final _blePermissionEvent = const EventChannel('pp_ble_permission_streams');
  final _dfuEvent = const EventChannel('pp_dfu_streams');
  final _deviceLogEvent = const EventChannel('device_log_streams');
  final _scanStateEvent = const EventChannel('pp_scan_state_streams');

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
  Future<void> fetchHistoryData({String? userID = "", required int peripheralType, required Function(List<PPBodyBaseModel> dataList, bool isSuccess) callBack}) async {

    if (peripheralType == PPDevicePeripheralType.torre.value) {
      if (userID == null || userID.isEmpty) {
        PPBluetoothKitLogger.i('历史数据-userID 为空');
        callBack([], false);
        return;
      }

    }

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

          callBack(retList, true);

        } catch(e) {
          PPBluetoothKitLogger.i('历史数据-返回结果异常:$e');

          callBack([], false);
        }
      } else {
        PPBluetoothKitLogger.i('历史数据-返回数据格式不正确');

        callBack([], false);
      }

      // 返回数据，则不需要订阅
      _historySubscription?.cancel();

    });

    // PPBluetoothKitLogger.i('执行fetchHistoryData');
    await _bleChannel.invokeMethod('fetchHistory',<String, dynamic>{
      'peripheralType': peripheralType,
      'userID': userID
    });
  }

  @override
  Future<void> deleteHistoryData(int peripheralType) async {
    // PPBluetoothKitLogger.i('执行deleteHistoryData');
    await _bleChannel.invokeMethod('deleteHistory',<String, dynamic>{
      'peripheralType': peripheralType
    });
  }
  
  @override
  Future<bool?> syncUnit(int peripheralType, PPDeviceUser deviceUser) async {
    // PPBluetoothKitLogger.i('执行 同步单位');

    try {

      final ret = await _bleChannel.invokeMethod("syncUnit",<String, dynamic>{
        'unit': deviceUser.unitType.type,
        'sex': deviceUser.sex.type,
        'age':deviceUser.age,
        'height':deviceUser.userHeight,
        'isPregnantMode':deviceUser.isPregnantMode,
        'isAthleteMode':deviceUser.isAthleteMode,
        'peripheralType':peripheralType
      });

      final retJson = ret?.cast<String, dynamic>();
      final state = retJson?["state"] as bool?;

      return state;
    } catch(e) {

      PPBluetoothKitLogger.i('同步单位-返回结果异常:$e');
      return false;
    }

  }
  
  @override
  Future<bool?> syncTime(int peripheralType,{bool is24Hour = true}) async {
    // PPBluetoothKitLogger.i('执行 同步时间');

    try {

      final ret = await _bleChannel.invokeMethod<Map>('syncTime',<String, dynamic>{
        'peripheralType':peripheralType
      });
      final retJson = ret?.cast<String, dynamic>();
      final state = (retJson?["state"] as bool? ) ?? false;

      return state;
    } catch(e) {
      PPBluetoothKitLogger.i('同步时间-返回结果异常:$e');

      return false;
    }

  }

  @override
  Future<PPWifiResult> configWifi(int peripheralType, {required String domain, required String ssId, required String password}) async {
    // PPBluetoothKitLogger.i('执行 配网-域名:$domain wifi:$ssId');

    try {

      final ret = await _bleChannel.invokeMethod<Map>('configWifi',<String, dynamic>{
        'domain': domain,
        'ssId': ssId,
        'password':password,
        'peripheralType':peripheralType
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
  Future<String?> fetchWifiInfo(int peripheralType) async {
    // PPBluetoothKitLogger.i('执行 获取配网信息');

    try {

      final ret = await _bleChannel.invokeMethod<Map>('fetchWifiInfo',<String, dynamic>{
        'peripheralType':peripheralType
      });

      final retJson = ret?.cast<String, dynamic>();
      final ssId = retJson?["ssId"] as String?;

      return ssId;
    } catch(e) {

      PPBluetoothKitLogger.i('获取配网信息-返回结果异常:$e');
      return null;
    }

  }

  @override
  Future<bool?> isConnectWIFI(int peripheralType) async {
    // PPBluetoothKitLogger.i('执行 获取配网信息');

    try {

      final ret = await _bleChannel.invokeMethod<Map>('fetchWifiInfo',<String, dynamic>{
        'peripheralType':peripheralType
      });

      final retJson = ret?.cast<String, dynamic>();
      final connectedWIFI = retJson?["isConnectWIFI"] as bool?;

      return connectedWIFI;
    } catch(e) {

      PPBluetoothKitLogger.i('获取是否配网-返回结果异常:$e');
      return null;
    }

  }

  @override
  Future<PPDevice180AModel?> fetchDeviceInfo(int peripheralType) async {
    // PPBluetoothKitLogger.i('执行 获取设备信息');

    try {

      final ret = await _bleChannel.invokeMethod<Map>('fetchDeviceInfo',<String, dynamic>{
        'peripheralType':peripheralType
      });
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
  Future<void> fetchBatteryInfo(int peripheralType, {required bool continuity, required Function(int power) callBack}) async {

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

    await _bleChannel.invokeMethod<Map>('fetchBatteryInfo',<String, dynamic>{
      'peripheralType':peripheralType
    });
  }

  @override
  Future<void> resetDevice(int peripheralType) async {
    _bleChannel.invokeMethod<Map>('resetDevice',<String, dynamic>{
      'peripheralType':peripheralType
    });
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

          PPBluetoothKitLogger.i('蓝牙权限-监听结果异常:$e');
          callBack(PPBlePermissionState.unknown);
        }
      } else {

        PPBluetoothKitLogger.i('蓝牙权限-返回数据格式不正确');
        callBack(PPBlePermissionState.unknown);
      }

    });

    _bleChannel.invokeMethod('addBlePermissionListener');

  }

  @override
  Future<String?> fetchWifiMac(int peripheralType) async {
    try {

      final ret = await _bleChannel.invokeMethod<Map>('fetchWifiMac',<String, dynamic>{
        'peripheralType':peripheralType
      });

      final retJson = ret?.cast<String, dynamic>();
      final wifiMac = retJson?["wifiMac"] as String?;

      return wifiMac;
    } catch(e) {

      PPBluetoothKitLogger.i('获取Wi-Fi Mac-异常:$e');
      return null;
    }
  }

  @override
  Future<List<String>?> scanWifiNetworks(int peripheralType) async {
    try {

      final ret = await _bleChannel.invokeMethod<Map>('scanWifiNetworks',<String, dynamic>{
        'peripheralType':peripheralType
      });

      final retJson = ret?.cast<String, dynamic>();
      final wifiList = retJson?["wifiList"] as List<String>?;

      return wifiList;
    } catch(e) {

      PPBluetoothKitLogger.i('获取周围Wi-Fi热点-异常:$e');
      return null;
    }
  }

  @override
  Future<bool> wifiOTA(int peripheralType) async {
    try {

      final ret = await _bleChannel.invokeMethod<Map>('wifiOTA',<String, dynamic>{
        'peripheralType':peripheralType
      });

      final retJson = ret?.cast<String, dynamic>();
      final isSuccess = retJson?["isSuccess"] as bool? ?? false;
      final errorCode = retJson?["errorCode"] as int?;
      PPBluetoothKitLogger.i('Wi-Fi OTA 状态:$isSuccess errorCode:$errorCode');

      return isSuccess;
    } catch(e) {

      PPBluetoothKitLogger.i('Wi-Fi OTA-异常:$e');
      return false;
    }
  }

  @override
  Future<bool> heartRateSwitchControl(int peripheralType, bool open) async {
    try {

      final ret = await _bleChannel.invokeMethod<Map>('heartRateSwitchControl',<String, dynamic>{
        'peripheralType':peripheralType,
        'open':open
      });

      final retJson = ret?.cast<String, dynamic>();
      final isSuccess = retJson?["state"] as bool? ?? false;

      return isSuccess;
    } catch(e) {

      PPBluetoothKitLogger.i('心率控制开关-异常:$e');
      return false;
    }
  }

  @override
  Future<bool> fetchHeartRateSwitch(int peripheralType) async {
    try {

      final ret = await _bleChannel.invokeMethod<Map>('fetchHeartRateSwitch',<String, dynamic>{
        'peripheralType':peripheralType
      });

      final retJson = ret?.cast<String, dynamic>();
      final open = retJson?["open"] as bool? ?? false;

      return open;
    } catch(e) {

      PPBluetoothKitLogger.i('获取心率开关状态-异常:$e');
      return false;
    }
  }

  @override
  Future<bool> impedanceSwitchControl(int peripheralType, bool open) async {
    try {

      final ret = await _bleChannel.invokeMethod<Map>('impedanceSwitchControl',<String, dynamic>{
        'peripheralType':peripheralType,
        'open':open
      });

      final retJson = ret?.cast<String, dynamic>();
      final isSuccess = retJson?["state"] as bool? ?? false;

      return isSuccess;
    } catch(e) {

      PPBluetoothKitLogger.i('阻抗控制开关-异常:$e');
      return false;
    }
  }

  @override
  Future<bool> fetchImpedanceSwitch(int peripheralType) async {
    try {

      final ret = await _bleChannel.invokeMethod<Map>('fetchImpedanceSwitch',<String, dynamic>{
        'peripheralType':peripheralType
      });

      final retJson = ret?.cast<String, dynamic>();
      final open = retJson?["open"] as bool? ?? false;

      return open;
    } catch(e) {

      PPBluetoothKitLogger.i('获取阻抗开关状态-异常:$e');
      return false;
    }
  }

  @override
  Future<bool> setBindingState(int peripheralType, bool binding) async {
    try {

      final ret = await _bleChannel.invokeMethod<Map>('setBindingState',<String, dynamic>{
        'peripheralType':peripheralType,
        'binding':binding
      });

      final retJson = ret?.cast<String, dynamic>();
      final isSuccess = retJson?["state"] as bool? ?? false;

      return isSuccess;
    } catch(e) {

      PPBluetoothKitLogger.i('设置设备绑定状态-异常:$e');
      return false;
    }
  }

  @override
  Future<bool> fetchBindingState(int peripheralType) async {
    try {

      final ret = await _bleChannel.invokeMethod<Map>('fetchBindingState',<String, dynamic>{
        'peripheralType':peripheralType
      });

      final retJson = ret?.cast<String, dynamic>();
      final binding = retJson?["binding"] as bool? ?? false;

      return binding;
    } catch(e) {

      PPBluetoothKitLogger.i('获取设备绑定状态-异常:$e');
      return false;
    }
  }

  @override
  Future<bool> setScreenBrightness(int peripheralType, int brightness) async {
    if (brightness < 0 || brightness > 100) {
      PPBluetoothKitLogger.i('设置屏幕亮度-参数异常-brightness:$brightness');
      return false;
    }

    try {

      final ret = await _bleChannel.invokeMethod<Map>('setScreenBrightness',<String, dynamic>{
        'peripheralType':peripheralType,
        'brightness':brightness
      });

      final retJson = ret?.cast<String, dynamic>();
      final state = retJson?["state"] as bool? ?? false;

      return state;
    } catch(e) {

      PPBluetoothKitLogger.i('设置设备绑定状态-异常:$e');
      return false;
    }
  }

  @override
  Future<int> fetchScreenBrightness(int peripheralType) async {
    try {

      final ret = await _bleChannel.invokeMethod<Map>('peripheralType',peripheralType);

      final retJson = ret?.cast<String, dynamic>();
      final brightness = retJson?["brightness"] as int? ?? 0;

      return brightness;
    } catch(e) {

      PPBluetoothKitLogger.i('获取屏幕亮度-异常:$e');
      return 0;
    }

  }

  @override
  Future<bool> syncUserInfo(int peripheralType, PPTorreUserModel userModel) async {

    if (userModel.userID.isEmpty || userModel.memberID.isEmpty) {
      PPBluetoothKitLogger.i('同步用户- userID 或 memberID 为空');
      return false;
    }

    try {

    Map<String, dynamic> userMap  = userModel.toJson();
    userMap['peripheralType'] = peripheralType;

      final ret = await _bleChannel.invokeMethod<Map>('syncUserInfo',userMap);

      final retJson = ret?.cast<String, dynamic>();
      final state = retJson?["state"] as bool? ?? false;

      return state;
    } catch(e) {

      PPBluetoothKitLogger.i('同步单个用户-异常:$e');
      return false;
    }

  }

  @override
  Future<bool> syncUserList(int peripheralType, List<PPTorreUserModel> userList) async {
    try {
      List<Map<String, dynamic>> list = [];

      for (var model in userList) {

        if (model.userID.isEmpty || model.memberID.isEmpty) {
          PPBluetoothKitLogger.i('同步用户列表- userID 或 memberID 为空');
          return false;
        }

        final map = model.toJson();
        list.add(map);
      }

      Map<String, dynamic> userMap  = {
        'userList':list,
        'peripheralType':peripheralType
      };

      final ret = await _bleChannel.invokeMethod<Map>('syncUserList',userMap);

      final retJson = ret?.cast<String, dynamic>();
      final state = retJson?["state"] as bool? ?? false;

      return state;
    } catch(e) {

      PPBluetoothKitLogger.i('同步用户列表-异常:$e');
      return false;
    }
  }

  @override
  Future<List<String>> fetchUserIDList(int peripheralType) async {
    try {

      final ret = await _bleChannel.invokeMethod<Map>('fetchUserIDList',<String, dynamic>{
        'peripheralType':peripheralType
      });

      final retJson = ret?.cast<String, dynamic>();
      final userIDList = retJson?["userIDList"] as List<String>? ?? [];

      return userIDList;
    } catch(e) {

      PPBluetoothKitLogger.i('获取设备用户ID列表-异常:$e');
      return [];
    }
  }

  @override
  Future<bool> selectUser(int peripheralType, String userID, String memberID) async {
    try {

      final ret = await _bleChannel.invokeMethod<Map>('selectUser',<String, dynamic>{
        'peripheralType':peripheralType,
        'userID':userID,
        'memberID':memberID
      });

      final retJson = ret?.cast<String, dynamic>();
      final state = retJson?["state"] as bool? ?? false;

      return state;
    } catch(e) {

      PPBluetoothKitLogger.i('选择测量用户-异常:$e');
      return false;
    }
  }

  @override
  Future<bool> deleteUser(int peripheralType, String userID, String memberID) async {
    if (userID.isEmpty) {
      PPBluetoothKitLogger.i('删除设备用户失败- userID 为空');
      return false;
    }

    if (memberID.isEmpty) { // 删除 userID 下所有成员
      memberID = "ff";
    }

    try {

      final ret = await _bleChannel.invokeMethod<Map>('deleteUser',<String, dynamic>{
        'peripheralType':peripheralType,
        'userID':userID,
        'memberID':memberID
      });

      final retJson = ret?.cast<String, dynamic>();
      final state = retJson?["state"] as bool? ?? false;

      return state;
    } catch(e) {

      PPBluetoothKitLogger.i('删除设备用户-异常:$e');
      return false;
    }
  }

  @override
  Future<bool> startMeasure(int peripheralType) async {
    try {

      final ret = await _bleChannel.invokeMethod<Map>('startMeasure',<String, dynamic>{
        'peripheralType':peripheralType
      });

      final retJson = ret?.cast<String, dynamic>();
      final state = retJson?["state"] as bool? ?? false;

      return state;
    } catch(e) {

      PPBluetoothKitLogger.i('开始测量-异常:$e');
      return false;
    }
  }


  @override
  Future<bool> stopMeasure(int peripheralType) async {
    try {

      final ret = await _bleChannel.invokeMethod<Map>('stopMeasure',<String, dynamic>{
        'peripheralType':peripheralType
      });

      final retJson = ret?.cast<String, dynamic>();
      final state = retJson?["state"] as bool? ?? false;

      return state;
    } catch(e) {

      PPBluetoothKitLogger.i('停止测量-异常:$e');
      return false;
    }
  }

  @override
  Future<bool> startBabyModel(int peripheralType, PPBabyModelStep step, int weight) async {

    PPBluetoothKitLogger.i('开始抱婴模式-step:$step weight:$weight');

    try {

      final ret = await _bleChannel.invokeMethod<Map>('startBabyModel',<String, dynamic>{
        'peripheralType':peripheralType,
        'step':step,
        'weight':weight
      });

      final retJson = ret?.cast<String, dynamic>();
      final state = retJson?["state"] as bool? ?? false;

      return state;
    } catch(e) {

      PPBluetoothKitLogger.i('开始抱婴模式-异常:$e');
      return false;
    }
  }

  @override
  Future<bool> exitBabyModel(int peripheralType) async {
    try {

      final ret = await _bleChannel.invokeMethod<Map>('startBabyModel',<String, dynamic>{
        'peripheralType':peripheralType
      });

      final retJson = ret?.cast<String, dynamic>();
      final state = retJson?["state"] as bool? ?? false;

      return state;
    } catch(e) {

      PPBluetoothKitLogger.i('退出抱婴模式-异常:$e');
      return false;
    }
  }


  @override
  void dfuStart(int peripheralType, String filePath, String deviceFirmwareVersion, bool isForceCompleteUpdate,{required Function(double progress, bool isSuccess)callBack}) async {

    if (filePath.isEmpty) {
      PPBluetoothKitLogger.i('蓝牙DFU-失败-升级包路径为空');
      callBack(0, false);
      return;
    }

    if (deviceFirmwareVersion.isEmpty) {
      deviceFirmwareVersion = '000.000.000.000';
    }

    _dfuSubscription?.cancel();
    _dfuSubscription = _dfuEvent.receiveBroadcastStream().listen((event) {

      if (event is Map){
        try {

          final retJson = event.cast<String, dynamic>();
          final progress = retJson['progress'] as double? ?? 0;
          final isSuccess = retJson['isSuccess'] as bool? ?? false;

          callBack(progress, isSuccess);
        } catch(e) {

          PPBluetoothKitLogger.i('蓝牙DFU-返回结果异常:$e');
          callBack(0, false);
        }
      } else {

        PPBluetoothKitLogger.i('蓝牙DFU-返回数据格式不正确');
        callBack(0, false);
      }

    });

    await _bleChannel.invokeMethod<Map>('dfuStart',<String, dynamic>{
      'peripheralType':peripheralType,
      'filePath':filePath,
      'deviceFirmwareVersion':deviceFirmwareVersion,
      'isForceCompleteUpdate':isForceCompleteUpdate
    });
  }

  @override
  void syncDeviceLog(int peripheralType, String logFolder, {required Function(double progress, bool isSuccess, String? filePath) callBack}) async {

    if (logFolder.isEmpty) {
      PPBluetoothKitLogger.i('同步设备日志-失败-日志文件夹为空');
      callBack(0, false, null);
      return;
    }

    _deviceLogSubscription?.cancel();
    _deviceLogSubscription = _deviceLogEvent.receiveBroadcastStream().listen((event) {

      try {

        final retJson = event.cast<String, dynamic>();
        final progress = retJson['progress'] as double? ?? 0;
        final filePath = retJson['filePath'] as String?;
        final isSuccess = retJson['isSuccess'] as bool? ?? false;
        callBack(progress, isSuccess, filePath);

      } catch(e) {
        PPBluetoothKitLogger.i('获取设备日志-返回结果异常:$e');
        callBack(0, false, null);
      }

    });

    await _bleChannel.invokeMethod<Map>('syncDeviceLog',<String, dynamic>{
      'peripheralType':peripheralType,
      'logFolder':logFolder
    });
  }

  @override
  void addScanStateListener({required Function(bool isScanning) callBack}) async {
    _scanStateSubscription?.cancel();
    _scanStateSubscription = _scanStateEvent.receiveBroadcastStream().listen((event) {
      try {

        final retJson = event.cast<String, dynamic>();
        final state = retJson['state'] as int? ?? 0;
        bool isScanning = state == 1;
        callBack(isScanning);

      } catch(e) {
        PPBluetoothKitLogger.i('扫描状态-返回结果异常:$e');
        callBack(false);
      }
    });
  }
  
  @override
  Future<void> keepAlive(int peripheralType) async {
    await _bleChannel.invokeMethod('keepAlive');
  }

}
