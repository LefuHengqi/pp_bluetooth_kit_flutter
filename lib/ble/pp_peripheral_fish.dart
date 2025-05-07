import 'package:pp_bluetooth_kit_flutter/channel/pp_bluetooth_kit_flutter_platform_interface.dart';
import 'package:pp_bluetooth_kit_flutter/enums/pp_scale_enums.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_body_base_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_180a_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_user.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_wifi_result.dart';


class PPPeripheralFish {
  static final _peripheralType = PPDevicePeripheralType.fish.value;


  /// 同步时间
  /// 返回值：true:成功
  static Future<bool?> syncTime() async {
    return PPBluetoothKitFlutterPlatform.instance.syncTime(_peripheralType);
  }

  /// 同步单位
  /// deviceUser 用户信息
  /// unitType 单位，必传
  /// userHeight 身高，必传
  /// age 年龄，必传
  /// sex 性别，必传
  /// isAthleteMode 运动员模式，可以不传
  /// isPregnantMode 孕妇模式，可以不传
  static Future<bool?> syncUnit(PPDeviceUser deviceUser) async {
    return PPBluetoothKitFlutterPlatform.instance.syncUnit(_peripheralType, deviceUser);
  }

  /// 获取设备信息
  static Future<PPDevice180AModel?> fetchDeviceInfo() async {
    return PPBluetoothKitFlutterPlatform.instance.fetchDeviceInfo(_peripheralType);
  }

  /// 去皮/清零
  static Future<bool> toZero() async {
    return PPBluetoothKitFlutterPlatform.instance.toZero(_peripheralType);
  }


}