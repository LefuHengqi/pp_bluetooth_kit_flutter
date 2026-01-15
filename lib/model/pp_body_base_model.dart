

import 'package:pp_bluetooth_kit_flutter/enums/pp_scale_enums.dart';

///@author liyp
///@email liyp520@foxmail.com
///@date 2025/2/6 15:39

class PPBodyBaseModel {
  // 体重，单位为KG放大100倍
  int weight = 0;

  // 4电极算法阻抗
  int impedance = 0;

  // 100kHz密文阻抗(4电极双频)
  int impedance100EnCode = 0;

  // 心率是否测量中
  bool isHeartRating = false;

  // 设备单位，默认kg
  PPUnitType? unit;

  // 心率
  int heartRate = 0;

  // 是否超载
  bool isOverload = false;

  // 是否是正数
  bool isPlus = true;

  //格式ms
  int measureTime = 0;

  // 数据归属 torre协议用
  String memberId = "";

  // 100KHz 左手阻抗加密值
  int z100KhzLeftArmEnCode = 0;

  // 100KHz 左脚阻抗加密值
  int z100KhzLeftLegEnCode = 0;

  // 100KHz 右手阻抗加密值
  int z100KhzRightArmEnCode = 0;

  // 100KHz 右脚阻抗加密值
  int z100KhzRightLegEnCode = 0;

  // 100KHz 躯干阻抗加密值
  int z100KhzTrunkEnCode = 0;

  // 20KHz 左手阻抗加密值
  int z20KhzLeftArmEnCode = 0;

  // 20KHz 左脚阻抗加密值
  int z20KhzLeftLegEnCode = 0;

  // 20KHz 右手阻抗加密值
  int z20KhzRightArmEnCode = 0;

  // 20KHz 右脚阻抗加密值
  int z20KhzRightLegEnCode = 0;

  // 20KHz 躯干阻抗加密值
  int z20KhzTrunkEnCode = 0;


  double getPpWeightKg() {
    return weight / 100.0;
  }

  void resetBodyFat() {

    z20KhzRightArmEnCode = 0;
    z100KhzRightArmEnCode = 0;
    z20KhzLeftArmEnCode = 0;
    z100KhzLeftArmEnCode = 0;
    z20KhzTrunkEnCode = 0;
    z100KhzTrunkEnCode = 0;
    z20KhzRightLegEnCode = 0;
    z100KhzRightLegEnCode = 0;
    z20KhzLeftLegEnCode = 0;
    z100KhzLeftLegEnCode = 0;
    impedance = 0;
    impedance100EnCode = 0;
    heartRate = 0;

  }

  PPBodyBaseModel();

  @override
  String toString() {
    return 'PPBodyBaseModel(weight=$weight,\n'
        'isHeartRating=$isHeartRating,\n'
        'unit=$unit,\n'
        'heartRate=$heartRate,\n'
        'isOverload=$isOverload,\n'
        'isPlus=$isPlus,\n'
        'measureTime=$measureTime,\n'
        'memberId=$memberId,\n'
        'z100KhzLeftArmEnCode=$z100KhzLeftArmEnCode,\n'
        'z100KhzLeftLegEnCode=$z100KhzLeftLegEnCode,\n'
        'z100KhzRightArmEnCode=$z100KhzRightArmEnCode,\n'
        'z100KhzRightLegEnCode=$z100KhzRightLegEnCode,\n'
        'z100KhzTrunkEnCode=$z100KhzTrunkEnCode,\n'
        'z20KhzLeftArmEnCode=$z20KhzLeftArmEnCode,\n'
        'z20KhzLeftLegEnCode=$z20KhzLeftLegEnCode,\n'
        'z20KhzRightArmEnCode=$z20KhzRightArmEnCode,\n'
        'z20KhzRightLegEnCode=$z20KhzRightLegEnCode,\n'
        'z20KhzTrunkEnCode=$z20KhzTrunkEnCode';
  }

  factory PPBodyBaseModel.fromJson(Map<String, dynamic> json) {

    PPUnitType zrType = PPUnitType.Unit_KG;
    final type = (json["unit"] as num?)?.toInt() ?? 0;
    if (type >= 0 && type < PPUnitType.values.length) {
      zrType = PPUnitType.values[type];
    }

    return PPBodyBaseModel()
      ..weight = (json["weight"] as num?)?.toInt() ?? 0
      ..impedance = (json["impedance"] as num?)?.toInt() ?? 0
      ..impedance100EnCode = (json["impedance100EnCode"] as num?)?.toInt() ?? 0
      ..isHeartRating = json["isHeartRating"] as bool? ?? false
      ..heartRate = (json["heartRate"] as num?)?.toInt() ?? 0
      ..isOverload = json["isOverload"] as bool? ?? false
      ..isPlus = json["isPlus"] as bool? ?? true
      ..measureTime = (json["measureTime"] as num?)?.toInt() ?? 0
      ..memberId = json["memberId"] as String? ?? ""
      ..z100KhzLeftArmEnCode = (json["z100KhzLeftArmEnCode"] as num?)?.toInt() ?? 0
      ..z100KhzLeftLegEnCode = (json["z100KhzLeftLegEnCode"] as num?)?.toInt() ?? 0
      ..z100KhzRightArmEnCode = (json["z100KhzRightArmEnCode"] as num?)?.toInt() ?? 0
      ..z100KhzRightLegEnCode = (json["z100KhzRightLegEnCode"] as num?)?.toInt() ?? 0
      ..z100KhzTrunkEnCode = (json["z100KhzTrunkEnCode"] as num?)?.toInt() ?? 0
      ..z20KhzLeftArmEnCode = (json["z20KhzLeftArmEnCode"] as num?)?.toInt() ?? 0
      ..z20KhzLeftLegEnCode = (json["z20KhzLeftLegEnCode"] as num?)?.toInt() ?? 0
      ..z20KhzRightArmEnCode = (json["z20KhzRightArmEnCode"] as num?)?.toInt() ?? 0
      ..z20KhzRightLegEnCode = (json["z20KhzRightLegEnCode"] as num?)?.toInt() ?? 0
      ..z20KhzTrunkEnCode = (json["z20KhzTrunkEnCode"] as num?)?.toInt() ?? 0
      ..unit = zrType;
  }

  Map<String, dynamic> toJson() {
    return {
      "weight": weight,
      "impedance": impedance,
      "impedance100EnCode": impedance100EnCode,
      "isHeartRating": isHeartRating,
      "heartRate": heartRate,
      "isOverload": isOverload,
      "isPlus": isPlus,
      "measureTime": measureTime,
      "memberId": memberId,
      "z100KhzLeftArmEnCode": z100KhzLeftArmEnCode,
      "z100KhzLeftLegEnCode": z100KhzLeftLegEnCode,
      "z100KhzRightArmEnCode": z100KhzRightArmEnCode,
      "z100KhzRightLegEnCode": z100KhzRightLegEnCode,
      "z100KhzTrunkEnCode": z100KhzTrunkEnCode,
      "z20KhzLeftArmEnCode": z20KhzLeftArmEnCode,
      "z20KhzLeftLegEnCode": z20KhzLeftLegEnCode,
      "z20KhzRightArmEnCode": z20KhzRightArmEnCode,
      "z20KhzRightLegEnCode": z20KhzRightLegEnCode,
      "z20KhzTrunkEnCode": z20KhzTrunkEnCode,
    };
  }


}
