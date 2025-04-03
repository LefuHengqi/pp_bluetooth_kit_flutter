import 'dart:convert';

import 'package:pp_bluetooth_kit_flutter/enums/pp_scale_enums.dart';


///@author liyp
///@email liyp520@foxmail.com
///@date 2025/1/9 17:00
//@description


class PPDeviceModel {
  String? deviceMac = ""; //设备mac设备唯一标识
  String? deviceName = ""; //设备蓝牙名称，设备名称标识
  int? devicePower = -1; //电量 -1标识不支持 >0为有效值
  int? rssi = 0; //蓝牙信号强度
  String? firmwareVersion = ""; //固件版本号
  String? hardwareVersion = ""; //硬件版本号
  String? manufacturerName = ""; //制造商
  String? softwareVersion = ""; //软件版本号
  String? serialNumber = ""; //序列号
  String? modelNumber = ""; //时区编号
  String? calculateVersion = ""; //计算版本
  PPDeviceType? deviceType = PPDeviceType.unknown; //设备类型
  PPDeviceProtocolType? deviceProtocolType = PPDeviceProtocolType.unknown; //协议模式
  PPDeviceCalculateType? deviceCalculateType = PPDeviceCalculateType.alternate; //计算方式
  PPDeviceAccuracyType? deviceAccuracyType = PPDeviceAccuracyType.point01; //精度
  PPDevicePowerType? devicePowerType = PPDevicePowerType.battery; //供电模式
  PPDeviceConnectType? deviceConnectType = PPDeviceConnectType.direct; //设备连接类型
  int? deviceFuncType = 0; //功能类型
  String? deviceUnitType = ""; //支持的单位
  int? mtu = 20; //协议单包的长度
  int? illumination = -1; //光照强度
  int? advLength = 0; //广播数据长度
  int? macAddressStart = 0; //mac起始位置
  String? sign = "";
  int? deviceSettingId = 0; //设备配置ID
  String? imgUrl = ""; //产品图地址
  String? productModel = ""; //产品型号
  int? standardType = 0; //标准类型，0 亚洲标准, 1 WHO标准

  PPDeviceModel(this.deviceName, this.deviceMac);

  PPDevicePeripheralType getDevicePeripheralType() {
    if (deviceConnectType == PPDeviceConnectType.Lte) {
      return PPDevicePeripheralType.kiwifruit;
    } else if (deviceConnectType == PPDeviceConnectType.direct) {
      if (deviceProtocolType == PPDeviceProtocolType.v2) {
        if (deviceType == PPDeviceType.ca) {
          return PPDevicePeripheralType.egg;
        } else if (deviceCalculateType == PPDeviceCalculateType.inScale) {
          return PPDevicePeripheralType.durian;
        } else {
          return PPDevicePeripheralType.apple;
        }
      } else if (deviceProtocolType == PPDeviceProtocolType.v3) {
        if (deviceType == PPDeviceType.ca) {
          return PPDevicePeripheralType.fish;
        } else {
          return PPDevicePeripheralType.coconut;
        }
      } else if (deviceProtocolType == PPDeviceProtocolType.v4) {
        return PPDevicePeripheralType.ice;
      } else if (deviceProtocolType == PPDeviceProtocolType.torre) {
        return PPDevicePeripheralType.torre;
      } else if (deviceProtocolType == PPDeviceProtocolType.borre) {
        return PPDevicePeripheralType.borre;
      } else if (deviceProtocolType == PPDeviceProtocolType.dorre) {
        return PPDevicePeripheralType.dorre;
      } else if (deviceProtocolType == PPDeviceProtocolType.forre) {
        return PPDevicePeripheralType.forre;
      }
    } else {
      if (deviceProtocolType == PPDeviceProtocolType.v2) {
        if (deviceType == PPDeviceType.ca) {
          return PPDevicePeripheralType.grapes;
        } else {
          return PPDevicePeripheralType.banana;
        }
      } else if (deviceProtocolType == PPDeviceProtocolType.v3) {
        if (deviceType == PPDeviceType.ca) {
          return PPDevicePeripheralType.hamburger;
        } else {
          return PPDevicePeripheralType.jambul;
        }
      }
    }
    return PPDevicePeripheralType.apple;
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceMac': deviceMac,
      'deviceName': deviceName,
      'devicePower': devicePower,
      'rssi': rssi,
      'firmwareVersion': firmwareVersion,
      'hardwareVersion': hardwareVersion,
      'manufacturerName': manufacturerName,
      'softwareVersion': softwareVersion,
      'serialNumber': serialNumber,
      'modelNumber': modelNumber,
      'calculateVersion': calculateVersion,
      'deviceType': deviceType?.toString(),
      'deviceProtocolType': deviceProtocolType?.toString(),
      'deviceCalculateType': deviceCalculateType?.toString(),
      'deviceAccuracyType': deviceAccuracyType?.toString(),
      'devicePowerType': devicePowerType?.toString(),
      'deviceConnectType': deviceConnectType?.toString(),
      'deviceFuncType': deviceFuncType,
      'deviceUnitType': deviceUnitType,
      'mtu': mtu,
      'illumination': illumination,
      'advLength': advLength,
      'macAddressStart': macAddressStart,
      'sign': sign,
      'deviceSettingId': deviceSettingId,
      'imgUrl': imgUrl,
      'productModel': productModel,
      'standardType': standardType,
    };
  }

  static PPDeviceModel fromJson(Map<String, dynamic> json) {
    PPDeviceModel model = PPDeviceModel("", "");
    model.deviceMac = json['deviceMac'];
    model.deviceName = json['deviceName'];
    model.devicePower = json['devicePower'];
    model.rssi = json['rssi'];
    model.firmwareVersion = json['firmwareVersion'];
    model.hardwareVersion = json['hardwareVersion'];
    model.manufacturerName = json['manufacturerName'];
    model.softwareVersion = json['softwareVersion'];
    model.serialNumber = json['serialNumber'];
    model.modelNumber = json['modelNumber'];
    model.calculateVersion = json['calculateVersion'];
    model.deviceType = json['deviceType'] != null ? PPDeviceType.values[json['deviceType']] : null;
    model.deviceProtocolType = json['deviceProtocolType'] != null ? PPDeviceProtocolType.values[json['deviceProtocolType']] : null;
    model.deviceCalculateType = json['deviceCalculateType'] != null ? PPDeviceCalculateType.values[json['deviceCalculateType']] : null;
    model.deviceAccuracyType = json['deviceAccuracyType'] != null ? PPDeviceAccuracyType.values[json['deviceAccuracyType']] : null;
    model.devicePowerType = json['devicePowerType'] != null ? PPDevicePowerType.values[json['devicePowerType']] : null;
    model.deviceConnectType = json['deviceConnectType'] != null ? PPDeviceConnectType.values[json['deviceConnectType']] : null;
    model.deviceFuncType = json['deviceFuncType'];
    model.deviceUnitType = json['deviceUnitType'];
    model.mtu = json['mtu'];
    model.illumination = json['illumination'];
    model.advLength = json['advLength'];
    model.macAddressStart = json['macAddressStart'];
    model.sign = json['sign'];
    model.deviceSettingId = json['deviceSettingId'];
    model.imgUrl = json['imgUrl'];
    model.productModel = json['productModel'];
    model.standardType = json['standardType'];
    return model;
  }
}
