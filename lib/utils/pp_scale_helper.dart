import '../enums/pp_scale_enums.dart';

///@author liyp
///@email liyp520@foxmail.com
///@date 2025/2/6 17:54
//@description


class PPScaleHelper {



  /// 是否支持历史数据
  static bool isSupportHistoryData(int? deviceFuncType) {
    if (deviceFuncType != null) {
      return (deviceFuncType & PPDeviceFuncType.PPDeviceFuncTypeHistory.type ==
          PPDeviceFuncType.PPDeviceFuncTypeHistory.type);
    }
    return false;
  }

  /// 是否支持Wifi
  static bool isFuncTypeWifi(int? deviceFuncType) {
    if (deviceFuncType != null) {
      return (deviceFuncType & PPDeviceFuncType.PPDeviceFuncTypeWifi.type ==
          PPDeviceFuncType.PPDeviceFuncTypeWifi.type);
    }
    return false;
  }

  /// 是否支持时间制式
  static bool isFuncTypeTimeFormat(int? deviceFuncType) {
    if (deviceFuncType != null) {
      return (deviceFuncType & PPDeviceFuncType.PPDeviceFuncTypeTimeFormat.type ==
          PPDeviceFuncType.PPDeviceFuncTypeTimeFormat.type);
    }
    return false;
  }

  /// 是否支持语言切换
  static bool isFuncTypeLanguageSwitch(int? deviceFuncType) {
    if (deviceFuncType != null) {
      return (deviceFuncType & PPDeviceFuncType.PPDeviceFuncTypeLanguageSwitch.type ==
          PPDeviceFuncType.PPDeviceFuncTypeLanguageSwitch.type);
    }
    return false;
  }

  /// 语音播报-四电极
  static bool isVoiceTypeH4(int? deviceFuncType) {
    if (deviceFuncType != null) {
      return (deviceFuncType & PPDeviceFuncType.PPDeviceFuncTypeVoiceType4.type ==
          PPDeviceFuncType.PPDeviceFuncTypeVoiceType4.type);
    }
    return false;
  }

  /// 是否支持8电极
  static bool isVoiceTypeH8(int? deviceFuncType) {
    if (deviceFuncType != null) {
      return (deviceFuncType & PPDeviceFuncType.PPDeviceFuncTypeVoiceType8.type ==
          PPDeviceFuncType.PPDeviceFuncTypeVoiceType8.type);
    }
    return false;
  }

  /// CF610
  static bool isVoiceTypeCf610(int? deviceFuncType) {
    if (deviceFuncType != null) {
      return (deviceFuncType & PPDeviceFuncType.PPDeviceFuncTypeVoiceTypecf610.type ==
          PPDeviceFuncType.PPDeviceFuncTypeVoiceTypecf610.type);
    }
    return false;
  }

  /// 下发体重信息类型(条)
  static bool isSevenWeightInfoType(int? deviceFuncType) {
    if (deviceFuncType != null) {
      return (deviceFuncType & PPDeviceFuncType.PPDeviceFuncTypeWeightInfoType.type ==
          PPDeviceFuncType.PPDeviceFuncTypeWeightInfoType.type);
    }
    return false;
  }

  /// 是否支持呼吸灯
  static bool isFuncTypeLight(int? deviceFuncType) {
    if (deviceFuncType != null) {
      return (deviceFuncType & PPDeviceFuncType.PPDeviceFuncTypeLight.type ==
          PPDeviceFuncType.PPDeviceFuncTypeLight.type);
    }
    return false;
  }

  /// Apple系列是否支持用户信息下发
  static bool isFuncTypeUserInfo(int? deviceFuncType) {
    if (deviceFuncType != null) {
      return (deviceFuncType & PPDeviceFuncType.PPDeviceFuncTypeUserInfo.type ==
          PPDeviceFuncType.PPDeviceFuncTypeUserInfo.type);
    }
    return false;
  }

  static bool isFuncTypeTwoBroadcast(int? deviceFuncType) {
    if (deviceFuncType != null) {
      return (deviceFuncType & PPDeviceFuncType.PPDeviceFuncTypeBidirectional.type ==
          PPDeviceFuncType.PPDeviceFuncTypeBidirectional.type);
    }
    return false;
  }

  /// 是否支持测脂
  static bool isFat(int? deviceFuncType) {
    if (deviceFuncType != null) {
      return (deviceFuncType & PPDeviceFuncType.PPDeviceFuncTypeFat.type ==
          PPDeviceFuncType.PPDeviceFuncTypeFat.type);
    }
    return false;
  }

  /// 是否支持心率
  static bool isHeartRate(int? deviceFuncType) {
    if (deviceFuncType != null) {
      return (deviceFuncType & PPDeviceFuncType.PPDeviceFuncTypeHeartRate.type ==
          PPDeviceFuncType.PPDeviceFuncTypeHeartRate.type);
    }
    return false;
  }

  /// 是否是8电极
  static bool isCalcute8(int? calcuteType) {
    return calcuteType == PPDeviceCalculateType.PPDeviceCalculateTypeAlternate8.index ||
        calcuteType == PPDeviceCalculateType.PPDeviceCalculateTypeAlternate8_0.index ||
        calcuteType == PPDeviceCalculateType.PPDeviceCalculateTypeAlternate8_1.index ||
        calcuteType == PPDeviceCalculateType.PPDeviceCalculateTypeAlternate8_2.index ||
        calcuteType == PPDeviceCalculateType.PPDeviceCalculateTypeAlternate8_3.index ||
        calcuteType == PPDeviceCalculateType.PPDeviceCalculateTypeAlternate8_4.index;
  }

  /// 是否支持光能充电
  static bool isFuncTypeSolar(int? devicePowerType) {
    if (devicePowerType != null) {
      return (devicePowerType  == PPDevicePowerType.PPDevicePowerTypeSolar.index);
    }
    return false;
  }

}