///@author liyp
///@email liyp520@foxmail.com
///@date 2025/1/9 16:57



//@description
enum PPDeviceConnectType {
  PPDeviceConnectTypeUnknow,
  PPDeviceConnectTypeBroadcast, //广播
  PPDeviceConnectTypeDirect, //直连
  PPDeviceConnectTypeLte, //(4G设备)
}

enum PPDevicePeripheralType {
  PeripheralApple,
  PeripheralBanana,
  PeripheralCoconut,
  PeripheralDurian,
  PeripheralEgg,
  PeripheralFish,
  PeripheralGrapes,
  PeripheralHamburger,
  PeripheralTorre,
  PeripheralIce,
  PeripheralJambul,
  PeripheralKiwifruit,
  PeripheralBorre,
  PeripheralDorre,
  PeripheralForre,
}

enum PPDeviceType {
  PPDeviceTypeUnknow, // 未知
  PPDeviceTypeCF, // 体脂秤
  PPDeviceTypeCE, //体重秤
  PPDeviceTypeCB, // 婴儿秤
  PPDeviceTypeCA, // 厨房秤
}

enum PPDeviceProtocolType {
  PPDeviceProtocolTypeUnknow,
  PPDeviceProtocolTypeV2,
  PPDeviceProtocolTypeV3,
  PPDeviceProtocolTypeTorre,
  PPDeviceProtocolTypeV4,
  PPDeviceProtocolTypeBorre,
  PPDeviceProtocolTypeDorre,
  PPDeviceProtocolTypeForre,
}

enum PPDeviceCalculateType {
  PPDeviceCalculateTypeUnknow,
  PPDeviceCalculateTypeInScale,
  PPDeviceCalculateTypeDirect,
  PPDeviceCalculateTypeAlternate,
  PPDeviceCalculateTypeAlternate8,
  PPDeviceCalculateTypeNormal,
  PPDeviceCalculateTypeNeedNot,
  PPDeviceCalculateTypeAlternate8_0,
  PPDeviceCalculateTypeAlternate8_1,
  PPDeviceCalculateTypeAlternate4_0,
  PPDeviceCalculateTypeAlternate4_1,
  PPDeviceCalculateTypeAlternate8_2,
  PPDeviceCalculateTypeAlternate8_3,
  PPDeviceCalculateTypeAlternate8_4,
}

enum PPDeviceAccuracyType {
  PPDeviceAccuracyTypeUnknow,
  PPDeviceAccuracyTypePoint01,
  PPDeviceAccuracyTypePoint005,
  PPDeviceAccuracyTypePointG,
  PPDeviceAccuracyTypePoint01G,
  PPDeviceAccuracyTypePoint001,
}

enum PPDevicePowerType {
  PPDevicePowerTypeUnknow,
  PPDevicePowerTypeBattery,
  PPDevicePowerTypeSolar,
  PPDevicePowerTypeCharge,
}

/// 功能类型，可多功能叠加
enum PPDeviceFuncType {
  // 称重
  PPDeviceFuncTypeWeight(0x01),

  // 测体脂
  PPDeviceFuncTypeFat(0x02),

  // 心率
  PPDeviceFuncTypeHeartRate(0x04),

  // 历史数据
  PPDeviceFuncTypeHistory(0x08),

  // 安全模式，孕妇模式
  PPDeviceFuncTypeSafe(0x10),

  // 闭幕单脚
  PPDeviceFuncTypeBMDJ(0x20),

  // 抱婴模式
  PPDeviceFuncTypeBaby(0x40),

  // wifi配网
  PPDeviceFuncTypeWifi(0x80),

  // 时钟功能
  PPDeviceFuncTypeTime(0x0100),

  // 按键声音
  PPDeviceFuncTypeKeyVoice(0x0200),

  // 双向广播功能
  PPDeviceFuncTypeBidirectional(0x0400),

  // 呼吸灯
  PPDeviceFuncTypeLight(0x0800),

  // V2.0是否支持用户信息
  PPDeviceFuncTypeUserInfo(0x1000),

  // 时间制式
  PPDeviceFuncTypeTimeFormat(0x2000),

  // 语言切换,其实就是二进制 100000000000000 转换为16进制，
  PPDeviceFuncTypeLanguageSwitch(0x4000),

  // 语音播报-四电极
  PPDeviceFuncTypeVoiceType4(0x8000),

  // 语音播报-八电极
  PPDeviceFuncTypeVoiceType8(0x010000),

  // 语音播报-CF610
  PPDeviceFuncTypeVoiceTypecf610(0x020000),

  // 下发体重信息类型(条)---选中按条下发体重信息给秤, 未选中按天/条下发体重信息给秤
  PPDeviceFuncTypeWeightInfoType(0x040000);

  final int type;

  const PPDeviceFuncType(this.type);

  /// 获取类型值
  int getType() {
    return type;
  }
}

enum PPDeviceUnitType {
  PPDeviceUnitTypeKG,
  PPDeviceUnitTypeLB,
  PPDeviceUnitTypeST,
  PPDeviceUnitTypeJin,
  PPDeviceUnitTypeSTLB,
}

enum PPDeviceConnectionState {
  disconnected,
  connected,
  error,
  undefine,
}

enum PPUnitType {
  Unit_KG(0),
  Unit_LB(1),
  PPUnitST_LB(2),
  PPUnitJin(3),
  PPUnitG(4),
  PPUnitLBOZ(5),
  PPUnitOZ(6),
  PPUnitMLWater(7),
  PPUnitMLMilk(8),
  PPUnitFL_OZ_WATER(9),
  PPUnitFL_OZ_MILK(10),
  PPUnitST(11);

  final int type;

  const PPUnitType(this.type);
}

enum PPMeasurementDataState {
  processData, //过程数据
  measuringBodyFat,//测量体脂中（部分设备无此状态）
  measuringHeartRate,//测量心率中（部分设备无此状态）
  completed, //测量完成，此状态下获取 阻抗 计算身体数据
}

enum PPUserGender {
  PPUserGenderFemale(0),
  PPUserGenderMale(1);

  final int type;

  const PPUserGender(this.type);
}