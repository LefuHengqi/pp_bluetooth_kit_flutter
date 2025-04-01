
import 'package:pp_bluetooth_kit_flutter/channel/pp_bluetooth_kit_flutter_platform_interface.dart';
import 'package:pp_bluetooth_kit_flutter/enums/pp_scale_enums.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_body_base_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_model.dart';
import 'package:pp_bluetooth_kit_flutter/utils/pp_bluetooth_kit_logger.dart';


class PPBluetoothKitManager {

  /// 初始化SDK
  /// [appKey] 应用唯一标识
  /// [appSecret] 应用密钥（
  /// [filePath] 配置文件存储路径
  static void initSDK(String appKey, String appSecret, String filePath) {
    PPBluetoothKitFlutterPlatform.instance.initSDK(appKey, appSecret, filePath);
  }

  /// 开始扫描蓝牙设备
  /// [callBack] 设备发现回调，返回PPDeviceModel设备模型
  static void startScan(Function(PPDeviceModel device) callBack) {
    PPBluetoothKitFlutterPlatform.instance.startScan(callBack);
  }

  /// 停止扫描蓝牙设备
  /// 使用场景：页面退出或扫描到目标设备后调用
  static void stopScan() {
    PPBluetoothKitFlutterPlatform.instance.stopScan();
  }


  /// 蓝牙权限变化-监听
  static void addBlePermissionListener({required Function(PPBlePermissionState state) callBack}) {
    PPBluetoothKitFlutterPlatform.instance.blePermissionListener(callBack: callBack);
  }

  /// 连接指定蓝牙设备
  /// [device] 要连接的设备模型（来自 startScan 扫描结果）
  /// [callBack] 连接状态回调，返回PPDeviceConnectionState枚举，连接成功/断开连接都会回调
  static void connectDevice(PPDeviceModel device, {required Function(PPDeviceConnectionState state) callBack}) {
    PPBluetoothKitFlutterPlatform.instance.connectDevice(device, callBack: callBack);
  }


  /// 测量数据监听器
  /// [callBack] 测量数据回调，包含三个参数：
  /// measurementState 测量状态，人体秤：为 completed 时，才能获取到“阻抗”值，并用于计算身体数据
  /// dataModel 测量数据模型
  /// device 产生数据的设备模型
  static void addMeasurementListener({required Function(PPMeasurementDataState measurementState, PPBodyBaseModel dataModel, PPDeviceModel device) callBack}) {
    PPBluetoothKitFlutterPlatform.instance.addMeasurementListener(callBack: callBack);
  }


  /// 启用/禁用控制台日志输出
  /// [enable] true-开启日志 false-关闭日志
  static void setLoggerEnable(bool enable) {
    PPBluetoothKitLogger.enabled = enable;
  }

  /// 添加日志监听回调
  /// [callBack] 日志内容回调函数，接收String类型的日志内容
  /// 使用场景：需要将日志输出到自定义界面或文件时使用
  static void addLoggerListener({required Function(String text) callBack}) {
    PPBluetoothKitFlutterPlatform.instance.loggerListener((content) {
      callBack(content);
    });
  }

  /// 设置设备配置信息
  /// [deviceContent] 设备配置的JSON字符串
  static void setDeviceSetting(String deviceContent) {
    PPBluetoothKitFlutterPlatform.instance.setDeviceSetting(deviceContent);
  }

  /// 获取已连接设备
  static Future<PPDeviceModel?> fetchConnectedDevice() async {
    return PPBluetoothKitFlutterPlatform.instance.fetchConnectedDevice();
  }

}