
import 'package:pp_bluetooth_kit_flutter/channel/pp_bluetooth_kit_flutter_platform_interface.dart';
import 'package:pp_bluetooth_kit_flutter/enums/pp_scale_enums.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_body_base_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_180a_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_user.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_torre_user_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_wifi_result.dart';

class PPPeripheralTorre {
  static final _peripheralType = PPDevicePeripheralType.PeripheralTorre.value;


  /// 获取指定用户历史数据
  /// userID：下发给设备的 userID
  /// memberID：下发给设备的 memberID
  /// [callBack] 返回的是设备离线测量的数据
  static void fetchUserHistoryData(String userID, String memberID, {required Function(List<PPBodyBaseModel> dataList, bool isSuccess) callBack}) {
    PPBluetoothKitFlutterPlatform.instance.fetchHistoryData(userID: userID, memberID: memberID, peripheralType:_peripheralType,callBack: callBack);
  }

  /// 获取游客历史数据
  /// [callBack] 返回的是设备离线测量的数据
  static void fetchTouristsHistoryData({required Function(List<PPBodyBaseModel> dataList, bool isSuccess) callBack}) {
    PPBluetoothKitFlutterPlatform.instance.fetchHistoryData(userID: "30", memberID: "", peripheralType:_peripheralType,callBack: callBack);
  }

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
  static void syncUnit(PPDeviceUser deviceUser) {
    PPBluetoothKitFlutterPlatform.instance.syncUnit(_peripheralType, deviceUser);
  }

  /// 配网（Wi-Fi）
  /// 参数说明：
  ///   - [domain] 配网服务器域名
  ///   - [ssId] Wi-Fi的名称（区分大小写）
  ///   - [password] Wi-Fi的密码
  ///   - [callBack] 配网结果回调函数，包含三个参数：
  ///     1. [success] true:成功，false：失败
  ///     2. [sn] sn
  ///     3. [errorCode] 错误码
  static Future<PPWifiResult> configWifi({required String domain, required String ssId, required String password}) async {
    return PPBluetoothKitFlutterPlatform.instance.configWifi(_peripheralType,domain: domain, ssId: ssId, password: password);
  }

  /// 是否已配网（Wi-Fi）
  /// 返回: true：已配网，false：未配网
  static Future<bool?> isConnectWIFI() async {
    return PPBluetoothKitFlutterPlatform.instance.isConnectWIFI(_peripheralType);
  }

  /// 获取 WIFI MAC 地址
  /// 举例：MAC 地址：01:02:03:04:05:06
  static Future<String?> fetchWifiMac(int peripheralType) async {
    return PPBluetoothKitFlutterPlatform.instance.fetchWifiMac(peripheralType);
  }

  /// 获取周围Wi-Fi热点
  /// 返回：获取到的Wi-Fi热点列表
  static Future<List<String>?> scanWifiNetworks(int peripheralType) async {
    return PPBluetoothKitFlutterPlatform.instance.scanWifiNetworks(peripheralType);
  }

  /// 获取设备信息
  static Future<PPDevice180AModel?> fetchDeviceInfo() async {
    return PPBluetoothKitFlutterPlatform.instance.fetchDeviceInfo(_peripheralType);
  }

  /// 获取设备电量
  /// continuity true:返回实时电量，false:只返回一次电量
  static void fetchBatteryInfo({required bool continuity, required Function(int power) callBack}) {
    PPBluetoothKitFlutterPlatform.instance.fetchBatteryInfo(_peripheralType,continuity: continuity, callBack: callBack);
  }

  /// Wi-Fi OTA升级
  static Future<bool> wifiOTA() async {
    return PPBluetoothKitFlutterPlatform.instance.wifiOTA(_peripheralType);
  }

  /// 心率控制开关
  /// open： true-开，false-关
  static Future<bool> heartRateSwitchControl(bool open) async {
    return PPBluetoothKitFlutterPlatform.instance.heartRateSwitchControl(_peripheralType, open);
  }

  /// 获取心率开关状态
  /// 返回： true-开，false-关
  static Future<bool> fetchHeartRateSwitch() async {
    return PPBluetoothKitFlutterPlatform.instance.fetchHeartRateSwitch(_peripheralType);
  }

  /// 阻抗控制开关
  /// open： true-开，false-关
  static Future<bool> impedanceSwitchControl(bool open) async {
    return PPBluetoothKitFlutterPlatform.instance.impedanceSwitchControl(_peripheralType, open);
  }

  /// 获取阻抗开关状态
  /// 返回： true-开，false-关
  static Future<bool> fetchImpedanceSwitch() async {
    return PPBluetoothKitFlutterPlatform.instance.fetchImpedanceSwitch(_peripheralType);
  }

  /// 设置绑定状态
  /// binding: true-绑定 false-取消绑定
  static Future<bool> setBindingState(bool binding) async {
    return PPBluetoothKitFlutterPlatform.instance.setBindingState(_peripheralType, binding);
  }

  /// 获取绑定状态
  /// 返回：true-已绑定，false-未绑定
  static Future<bool> fetchBindingState() async {
    return PPBluetoothKitFlutterPlatform.instance.fetchBindingState(_peripheralType);
  }

  /// 设置屏幕亮度
  /// brightness：0-100的数值用来表示屏幕亮度
  static Future<bool> setScreenBrightness(int brightness) async {
    return PPBluetoothKitFlutterPlatform.instance.setScreenBrightness(_peripheralType, brightness);
  }

  /// 同步单个用户到设备
  /// userModel：用户信息
  static Future<bool> syncUserInfo(PPTorreUserModel userModel) async {
    return PPBluetoothKitFlutterPlatform.instance.syncUserInfo(_peripheralType, userModel);
  }

  /// 获取设备中用户ID列表
  /// 返回：设备中用户 userID 列表
  static Future<List<String>> fetchUserIDList() async {
    return PPBluetoothKitFlutterPlatform.instance.fetchUserIDList(_peripheralType);
  }

  /// 选择测量用户
  /// userID ：下发给设备的 userID
  /// memberID：下发给设备的 memberID
  static Future<bool> selectDeviceUser(String userID, String memberID) async {
    return PPBluetoothKitFlutterPlatform.instance.selectUser(_peripheralType, userID, memberID);
  }

  /// 设备中用户
  /// userID ：下发给设备的 userID
  /// memberID：下发给设备的 memberID，如果传“”空字符串，则删除 userID 下所有成员，否则只删除 memberID 匹配的成员
  static Future<bool> deleteDeviceUser(String userID, String memberID) async {
    return PPBluetoothKitFlutterPlatform.instance.deleteUser(_peripheralType, userID, memberID);
  }

  /// 开始测量
  static Future<bool> startMeasure() async {
    return PPBluetoothKitFlutterPlatform.instance.startMeasure(_peripheralType);
  }

  /// 停止测量
  static Future<bool> stopMeasure() async {
    return PPBluetoothKitFlutterPlatform.instance.stopMeasure(_peripheralType);
  }
}