// PPScaleHelper.ets
import { PPDeviceCalculateType, PPDeviceFuncType, PPDevicePowerType } from "../enums/PPDeviceEnums";

export class PPScaleHelper {
  /** 是否支持历史数据 */
  static isSupportHistoryData(deviceFuncType?: number): boolean {
    return !!(deviceFuncType && (deviceFuncType & PPDeviceFuncType.PPDeviceFuncTypeHistory));
  }

  /** 是否支持Wifi */
  static isFuncTypeWifi(deviceFuncType?: number): boolean {
    return !!(deviceFuncType && (deviceFuncType & PPDeviceFuncType.PPDeviceFuncTypeWifi));
  }

  /** 是否支持时间制式 */
  static isFuncTypeTimeFormat(deviceFuncType?: number): boolean {
    return !!(deviceFuncType && (deviceFuncType & PPDeviceFuncType.PPDeviceFuncTypeTimeFormat));
  }

  /** 是否支持语言切换 */
  static isFuncTypeLanguageSwitch(deviceFuncType?: number): boolean {
    return !!(deviceFuncType && (deviceFuncType & PPDeviceFuncType.PPDeviceFuncTypeLanguageSwitch));
  }

  /** 语音播报-四电极 */
  static isVoiceTypeH4(deviceFuncType?: number): boolean {
    return !!(deviceFuncType && (deviceFuncType & PPDeviceFuncType.PPDeviceFuncTypeVoiceType4));
  }

  /** 是否支持8电极 */
  static isVoiceTypeH8(deviceFuncType?: number): boolean {
    return !!(deviceFuncType && (deviceFuncType & PPDeviceFuncType.PPDeviceFuncTypeVoiceType8));
  }

  /** CF610 */
  static isVoiceTypeCf610(deviceFuncType?: number): boolean {
    return !!(deviceFuncType && (deviceFuncType & PPDeviceFuncType.PPDeviceFuncTypeVoiceTypecf610));
  }

  /** 下发体重信息类型(条) */
  static isSevenWeightInfoType(deviceFuncType?: number): boolean {
    return !!(deviceFuncType && (deviceFuncType & PPDeviceFuncType.PPDeviceFuncTypeWeightInfoType));
  }

  /** 是否支持呼吸灯 */
  static isFuncTypeLight(deviceFuncType?: number): boolean {
    return !!(deviceFuncType && (deviceFuncType & PPDeviceFuncType.PPDeviceFuncTypeLight));
  }

  /** Apple系列是否支持用户信息下发 */
  static isFuncTypeUserInfo(deviceFuncType?: number): boolean {
    return !!(deviceFuncType && (deviceFuncType & PPDeviceFuncType.PPDeviceFuncTypeUserInfo));
  }

  static isFuncTypeTwoBroadcast(deviceFuncType?: number): boolean {
    return !!(deviceFuncType && (deviceFuncType & PPDeviceFuncType.PPDeviceFuncTypeBidirectional));
  }

  /** 是否支持测脂 */
  static isFat(deviceFuncType?: number): boolean {
    return !!(deviceFuncType && (deviceFuncType & PPDeviceFuncType.PPDeviceFuncTypeFat));
  }

  /** 是否支持心率 */
  static isHeartRate(deviceFuncType?: number): boolean {
    return !!(deviceFuncType && (deviceFuncType & PPDeviceFuncType.PPDeviceFuncTypeHeartRate));
  }

  /** 是否是8电极 */
  static isCalcute8(calcuteType?: number): boolean {
    return calcuteType === PPDeviceCalculateType.PPDeviceCalculateTypeAlternate8 ||
      calcuteType === PPDeviceCalculateType.PPDeviceCalculateTypeAlternate8_0 ||
      calcuteType === PPDeviceCalculateType.PPDeviceCalculateTypeAlternate8_1 ||
      calcuteType === PPDeviceCalculateType.PPDeviceCalculateTypeAlternate8_2 ||
      calcuteType === PPDeviceCalculateType.PPDeviceCalculateTypeAlternate8_3 ||
      calcuteType === PPDeviceCalculateType.PPDeviceCalculateTypeAlternate8_4;
  }

  /** 是否支持光能充电 */
  static isFuncTypeSolar(devicePowerType?: number): boolean {
    return devicePowerType === PPDevicePowerType.PPDevicePowerTypeSolar;
  }

  /**
   * 是否支持脚长测量
   */
  static isSupportFootLen(deviceFuncType?: number): boolean {
    return !!(deviceFuncType && (deviceFuncType & PPDeviceFuncType.PPDeviceFuncTypeFootLen));
  }

}