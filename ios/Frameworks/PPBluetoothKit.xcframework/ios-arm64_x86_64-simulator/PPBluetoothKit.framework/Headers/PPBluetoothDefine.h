//
//  PPBluetoothDefine.h
//  PPBluetoothKIt
//
//  Created by 彭思远 on 2023/3/27.
//

#ifndef PPBluetoothDefine_h
#define PPBluetoothDefine_h

#import <PPBaseKit/PPBaseDefine.h>

#define kBLEAdvDataManufacturerData @"kCBAdvDataManufacturerData"
#define kBLEAdvDataLocalName @"kCBAdvDataLocalName"
#define kBLEAdvDataIsConnectable @"kCBAdvDataIsConnectable"

#define kBleuetoothSDKCode 2

typedef NS_ENUM(NSInteger, PPBluetoothState) {
    PPBluetoothStateUnknown = 0,
    PPBluetoothStateResetting,
    PPBluetoothStateUnsupported,
    PPBluetoothStateUnauthorized,
    PPBluetoothStatePoweredOff,
    PPBluetoothStatePoweredOn,
} ;

// 设备类型
typedef NS_ENUM(NSUInteger, PPDeviceConnectType) {
    
    PPDeviceConnectTypeUnknow = 0, // 未知
    PPDeviceConnectTypeBleAdv, // 蓝牙广播秤
    PPDeviceConnectTypeBleConnect, // 蓝牙连接秤
    PPDeviceConnectTypeLTE, // 4G-LTE
};

// 设备类型
typedef NS_ENUM(NSUInteger, PPDeviceType) {
    
    PPDeviceTypeUnknow = 0, // 未知
    PPDeviceTypeCF, // 体脂秤
    PPDeviceTypeCE, //体重秤
    PPDeviceTypeCB, // 婴儿秤
    PPDeviceTypeCA, // 厨房秤
};

// 设备蓝牙协议版本
typedef NS_ENUM(NSUInteger, PPDeviceProtocolType) {
    
    PPDeviceProtocolTypeUnknow = 0, // 未知
    PPDeviceProtocolTypeV2, // 2.x版本
    PPDeviceProtocolTypeV3, // 3.x版本
    PPDeviceProtocolTypeTorre, // torre版本
    PPDeviceProtocolTypeV4, // 4.x版本
    PPDeviceProtocolTypeBorre, // Borre版本
    PPDeviceProtocolTypeDorre, // Dorre版本
    PPDeviceProtocolTypeForre, // Forre版本
    PPDeviceProtocolTypeBorre_A, // Borre-A，属于Borre子集，CF625_PRO专用
    PPDeviceProtocolTypeKorre, // korre
    PPDeviceProtocolTypeLorre, // lorre
};


// 设备供电方式
typedef NS_ENUM(NSUInteger, PPDevicePowerType) {
    
    PPDevicePowerTypeUnknow = 0, // 未知
    PPDevicePowerTypeBattery, // 电池
    PPDevicePowerTypeSolar, // 太阳能
    PPDevicePowerTypeCharge, // 充电
};

// 设备功能类型
typedef NS_OPTIONS(NSUInteger, PPDeviceFuncType) {
    
    PPDeviceFuncTypeWeight = 1 << 0, // 称重
    PPDeviceFuncTypeFat = 1 << 1, // 测脂
    PPDeviceFuncTypeHeartRate = 1 << 2, // 心律
    PPDeviceFuncTypeHistory = 1 << 3, // 历史
    PPDeviceFuncTypeSafe = 1 << 4, // 孕妇
    PPDeviceFuncTypeBMDJ = 1 << 5, // 闭目单脚
    PPDeviceFuncTypeBaby = 1 << 6, // 抱婴模式
    PPDeviceFuncTypeWifi = 1 << 7, // wifi配网(支持2.4G)
    PPDeviceFuncTypeTime = 1 << 8, // 时钟
    PPDeviceFuncTypeKeyVoice = 1 << 9, // 按键音量
    PPDeviceFuncTypeBidirectional = 1 << 10, // 双向广播
    PPDeviceFuncTypeLight = 1 << 11, // 双向广播
    PPDeviceFuncTypeUserInfo = 1 << 12, // 下发用户信息功能
    PPDeviceFuncTypeTimeFormat = 1 << 13, // 时间制式(12/24小时制)
    PPDeviceFuncTypeLanguageSwitch = 1 << 14, // 语言切换
    PPDeviceFuncTypeVoiceBroadcast4Electrodes = 1 << 15, // 语音播报-四电极
    PPDeviceFuncTypeVoiceBroadcast8Electrodes = 1 << 16, // 语音播报-八电极
    PPDeviceFuncTypeVoiceBroadcastCF610 = 1 << 17, // 语音播报-CF610
    PPDeviceFuncTypeWeightInformationType = 1 << 18, // 选中按条下发体重信息给秤,未选中按天下发体重信息给秤
    PPDeviceFuncTypeFootLengthTest = 1 << 19, // 脚长测试
    PPDeviceFuncTypeWifi5G = 1 << 20, // wifi配网(支持5G)
};

// 设备精度
typedef NS_ENUM(NSUInteger, PPDeviceAccuracyType) {
    
    PPDeviceAccuracyTypeUnknow = 0, // 未知
    PPDeviceAccuracyTypePoint01, // 0.1KG精度
    PPDeviceAccuracyTypePoint005, // 0.05KG精度
    PPDeviceAccuracyTypePointG, // 1G精度
    PPDeviceAccuracyTypePoint01G, // 0.1G精度
    PPDeviceAccuracyTypePoint001, // 0.01KG精度

};



// 配网错误状态状态
typedef NS_ENUM(NSUInteger, PPWIFIConfigState) {
    
    PPWIFIConfigStateUnknow,
    PPWIFIConfigStateStartFailed,
    PPWIFIConfigStateDomainSendFailed,
    PPWIFIConfigStateDomainSendCodeFailed,
    PPWIFIConfigStateSSIDSendFailed,
    PPWIFIConfigStateSSIDSendCodeFailed,
    PPWIFIConfigStatePasswordSendFailed,
    PPWIFIConfigStatePasswordSendCodeFailed,
    PPWIFIConfigStateRegistSuccess,
    PPWIFIConfigStateRegistFailedTimeOut,
    PPWIFIConfigStateRegistFailedConnect,
    PPWIFIConfigStateRegistFailedHTTP,
    PPWIFIConfigStateRegistFailedHTTPS,
    PPWIFIConfigStateRegistFailedRegist,
    PPWIFIConfigStateRegistFailedCommand,
};


/**
 * 设备分组类型
 */
typedef NS_ENUM(NSUInteger, PPDevicePeripheralType) {
    //2.x /连接 /人体秤
    PPDevicePeripheralTypePeripheralApple,
    //2.x /广播 /人体秤
    PPDevicePeripheralTypePeripheralBanana,
    //3.x /连接 /人体秤
    PPDevicePeripheralTypePeripheralCoconut,
    //2.x /设备端计算的连接 /人体秤
    PPDevicePeripheralTypePeripheralDurian,
    //2.x /连接 /厨房秤
    PPDevicePeripheralTypePeripheralEgg,
    //3.x /连接 /厨房秤
    PPDevicePeripheralTypePeripheralFish,
    //2.x /广播 /厨房秤
    PPDevicePeripheralTypePeripheralGrapes,
    //3.x /广播 /厨房秤
    PPDevicePeripheralTypePeripheralHamburger,
    //torre /连接 /人体秤
    PPDevicePeripheralTypePeripheralTorre,
    //ice //CF597 /连接 /人体秤
    PPDevicePeripheralTypePeripheralIce,
    // Jambul 3.x /广播 /人体秤
    PPDevicePeripheralTypePeripheralJambul,
    // 4G LET设备
    PPDevicePeripheralTypePeripheralKiwifruit,
    
    //Borre /连接 /人体秤
    PPDevicePeripheralTypePeripheralBorre,
    
    //Dorre /连接 /人体秤
    PPDevicePeripheralTypePeripheralDorre,
    
    //Forre /连接 /人体秤
    PPDevicePeripheralTypePeripheralForre,
    //Korre /连接 /营养秤
    PPDevicePeripheralTypePeripheralKorre,
    //Lorre /连接 /营养秤
    PPDevicePeripheralTypePeripheralLorre,
};

/// 抓零状态
typedef NS_ENUM(NSUInteger, PPScaleCaptureZeroType) {
    // 抓零中
    PPScaleCaptureZeroTypeProcessing = 0,
    // 抓零成功
    PPScaleCaptureZeroTypeZeroSuccess,
};

/// 心率测量状态
typedef NS_ENUM(NSUInteger, PPScaleHeartRateType) {
    //心率未测量
    PPScaleHeartRateTypeNotMeasured = 0,
    //心率测量中
    PPScaleHeartRateTypeMeasuring,
    //心率测量成功
    PPScaleHeartRateTypeMeasureSuccess,
    //心率测量失败
    PPScaleHeartRateTypeMeasureFail
};

/// 阻抗测量状态
typedef NS_ENUM(NSUInteger, PPScaleImpedanceType) {
    //阻抗未测量
    PPScaleImpedanceTypeNotMeasured = 0,
    //阻抗测量中
    PPScaleImpedanceTypeMeasuring,
    //阻抗成功
    PPScaleImpedanceTypeMeasureSuccess,
    //阻抗失败
    PPScaleImpedanceTypeMeasureFail
};

/// 测量模式
typedef NS_ENUM(NSUInteger, PPScaleMeasureModeType) {
    //测量模式
    PPScaleMeasureModeTypeMeasure = 0,
    //标定模式
    PPScaleMeasureModeTypeCalibration
};

/// 测量结果
typedef NS_ENUM(NSUInteger, PPScaleMeasureResultType) {
    // 测量未完成
    PPScaleMeasureResultTypeProcessing = 0,
    // 测量完成
    PPScaleMeasureResultTypeCompleted
};

/// 电源状态
typedef NS_ENUM(NSUInteger, PPScalePowerType) {
    // 开机
    PPScalePowerTypePowerOn = 0,
    // 关机
    PPScalePowerTypePowerOff
};


/// 重量状态
typedef NS_ENUM(NSUInteger, PPScaleWeightType) {
    // 实时重量
    PPScaleWeightTypeProcessing = 0,
    // 稳定重量
    PPScaleWeightTypeLock,
    // 超重
    PPScaleWeightTypeOverweight,
    // 离秤
    PPScaleWeightTypeLeaveScale
};

// 设备功能类型
typedef NS_ENUM(NSInteger, PPTimeFormat) {
    PPTimeFormat24HourClock = 0, // 24小时制
    PPTimeFormat12HourClock = 1, // 12小时制
    
};

// 头像类型
typedef NS_ENUM(NSInteger, PPAvatarTypeType) {
    
    PPAvatarTypeTypeTorreV1 = 0, // 第1套头像
    PPAvatarTypeTypeTorreV2, // 第2套头像

};

// 鉴权状态，部分设备才有
typedef NS_ENUM(NSUInteger, PPAuthState) {
    PPAuthStateUnknown = 0,
    PPAuthStateStart, // 开始鉴权
    PPAuthStateSuccess, // 鉴权成功
    PPAuthStateFail, // 鉴权失败
};

typedef NS_ENUM(NSUInteger, PPDeviceButtonType) {
    PPDeviceButtonTypeZero = 0, //去皮/清零按钮
};

typedef NS_ENUM(NSUInteger, PPDeviceButtonState) {
    PPDeviceButtonStateUnknown = 0,
    PPDeviceButtonStateExecuting = 1, // 执行中
    PPDeviceButtonStateSuccess = 2, // 执行成功
    PPDeviceButtonStateFail = 3, // 执行失败
};


#endif /* PPBluetoothDefine_h */
