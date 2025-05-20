/**
 * 设备连接类型枚举
 */
export enum PPDeviceConnectType {
  PPDeviceConnectTypeUnknow,
  PPDeviceConnectTypeBroadcast, // 广播
  PPDeviceConnectTypeDirect, // 直连
  PPDeviceConnectTypeLte, // (4G设备)
}

/**
 * 设备外设类型枚举
 */
export enum PPDevicePeripheralType {
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

/**
 * 设备类型枚举
 */
export enum PPDeviceType {
  PPDeviceTypeUnknow, // 未知
  PPDeviceTypeCF, // 体脂秤
  PPDeviceTypeCE, // 体重秤
  PPDeviceTypeCB, // 婴儿秤
  PPDeviceTypeCA, // 厨房秤
}

/**
 * 设备协议类型枚举
 */
export enum PPDeviceProtocolType {
  PPDeviceProtocolTypeUnknow,
  PPDeviceProtocolTypeV2,
  PPDeviceProtocolTypeV3,
  PPDeviceProtocolTypeTorre,
  PPDeviceProtocolTypeV4,
  PPDeviceProtocolTypeBorre,
  PPDeviceProtocolTypeDorre,
  PPDeviceProtocolTypeForre,
}

/**
 * 设备计算类型枚举
 */
export enum PPDeviceCalculateType {
  PPDeviceCalculateTypeUnknow,
  PPDeviceCalculateTypeInScale,
  PPDeviceCalculateTypeDirect,
  PPDeviceCalculateTypeAlternate,
  PPDeviceCalculateTypeAlternate8,
  PPDeviceCalculateTypeNormal,
  PPDeviceCalculateTypeNeedNot,
  PPDeviceCalculateTypeAlternate8_0,
  PPDeviceCalculateTypeAlternate8_1,
  PPDeviceCalculateTypeAlternate8_2,
  PPDeviceCalculateTypeAlternate8_3,
  PPDeviceCalculateTypeAlternate8_4,
  PPDeviceCalculateTypeAlternate4_0,
  PPDeviceCalculateTypeAlternate4_1,
}

/**
 * 设备精度类型枚举
 */
export enum PPDeviceAccuracyType {
  PPDeviceAccuracyTypeUnknow,
  PPDeviceAccuracyTypePoint01,
  PPDeviceAccuracyTypePoint005,
  PPDeviceAccuracyTypePointG,
  PPDeviceAccuracyTypePoint01G,
  PPDeviceAccuracyTypePoint001,
}

/**
 * 设备电源类型枚举
 */
export enum PPDevicePowerType {
  PPDevicePowerTypeUnknow,
  PPDevicePowerTypeBattery,
  PPDevicePowerTypeSolar,
  PPDevicePowerTypeCharge,
}

/**
 * 设备功能类型枚举
 */
export enum PPDeviceFuncType {
  /** 称重 (1 << 0) */
  PPDeviceFuncTypeWeight = 1 << 0, // 0x01

  /** 测体脂 (1 << 1) */
  PPDeviceFuncTypeFat = 1 << 1, // 0x02

  /** 心率 (1 << 2) */
  PPDeviceFuncTypeHeartRate = 1 << 2, // 0x04

  /** 历史数据 (1 << 3) */
  PPDeviceFuncTypeHistory = 1 << 3, // 0x08

  /** 安全模式/孕妇模式 (1 << 4) */
  PPDeviceFuncTypeSafe = 1 << 4, // 0x10

  /** 闭幕单脚 (1 << 5) */
  PPDeviceFuncTypeBMDJ = 1 << 5, // 0x20

  /** 抱婴模式 (1 << 6) */
  PPDeviceFuncTypeBaby = 1 << 6, // 0x40

  /** wifi配网 (1 << 7) */
  PPDeviceFuncTypeWifi = 1 << 7, // 0x80

  /** 时钟功能 (1 << 8) */
  PPDeviceFuncTypeTime = 1 << 8, // 0x0100

  /** 按键声音 (1 << 9) */
  PPDeviceFuncTypeKeyVoice = 1 << 9, // 0x0200

  /** 双向广播功能 (1 << 10) */
  PPDeviceFuncTypeBidirectional = 1 << 10, // 0x0400

  /** 呼吸灯 (1 << 11) */
  PPDeviceFuncTypeLight = 1 << 11, // 0x0800

  /** 用户信息支持 (1 << 12) */
  PPDeviceFuncTypeUserInfo = 1 << 12, // 0x1000

  /** 时间制式 (1 << 13) */
  PPDeviceFuncTypeTimeFormat = 1 << 13, // 0x2000

  /** 语言切换 (1 << 14) */
  PPDeviceFuncTypeLanguageSwitch = 1 << 14, // 0x4000

  /** 语音播报-四电极 (1 << 15) */
  PPDeviceFuncTypeVoiceType4 = 1 << 15, // 0x8000

  /** 语音播报-八电极 (1 << 16) */
  PPDeviceFuncTypeVoiceType8 = 1 << 16, // 0x010000

  /** 语音播报-CF610 (1 << 17) */
  PPDeviceFuncTypeVoiceTypecf610 = 1 << 17, // 0x020000

  /** 下发体重信息类型(条) (1 << 18) */
  PPDeviceFuncTypeWeightInfoType = 1 << 18, // 0x040000

  /** 脚长测试功能 (1 << 19) */
  PPDeviceFuncTypeFootLen = 1 << 19,// 0x080000
}

/**
 * 设备单位类型枚举
 */
export enum PPDeviceUnitType {
  PPDeviceUnitTypeKG,
  PPDeviceUnitTypeLB,
  PPDeviceUnitTypeST,
  PPDeviceUnitTypeJin,
  PPDeviceUnitTypeSTLB,
}

/**
 * 用户性别枚举
 */

export enum PPUserGender {
  PPUserGenderFemale,
  PPUserGenderMale,
}

export enum TimeFormat {
  HOUR_24 = 0,
  HOUR_12 = 1
}
