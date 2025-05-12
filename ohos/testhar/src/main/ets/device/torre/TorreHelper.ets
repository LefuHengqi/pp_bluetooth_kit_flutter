import {
  PPScaleState,
  PPScaleStateCaptureZeroType,
  PPScaleStateHeartRateType,
  PPScaleStateImpedanceType,
  PPScaleStateMeasureModeType,
  PPScaleStateMeasureResultType,
  PPScaleStatePowerType,
  PPScaleStateWeightType
} from "../../enums/PPScaleState";
import { PPLogger } from "../../log/PPLogger";
import { ByteUtil } from "../../utils/ByteUtil";
import { ble } from "@kit.ConnectivityKit";
import { BusinessError } from "@kit.BasicServicesKit";

const CCCD: string = "2902";


export class TorreHelper {
  // MTU 相关
  static normalMtuLen: number = 244;
  static userIdMormalLen: number = 64;
  static memberIdMormalLen: number = 64;
  // 发送标签
  static SEND_TAG_NORMAL: number = -1; // 默认状态
  static SEND_TAG_LOG: number = 1; // 读取日志
  static SEND_TAG_HISTORY: number = 2; // 历史数据
  static SEND_TAG_WIFI_LIST: number = 4; // WiFi列表
  static SEND_TAG_INDEX_ACQUISITION: number = 6; // 指标获取
  static SEND_TAG_USER_LIST: number = 7; // 用户列表
  static SEND_TAG_MATHCH_USER: number = 8; // 匹配用户
  static SEND_TAG_CONFIG_WIFI_INFO: number = 9; // WiFi配置信息
  static SEND_TAG_ALL_HISTORY: number = 10; // 全部历史数据
  static SEND_TAG_USER_HISTORY: number = 11; // 指定用户历史数据

  // WiFi配置标签
  static CONFIG_WIFI_TAG_SSID: number = 1;
  static CONFIG_WIFI_TAG_PASSWORD: number = 2;
  static CONFIG_WIFI_TAG_DOMAIN: number = 3;
  // 时间控制（使用bigint处理长整型）
  static lastSendOrReceiveDataTime: bigint = 0n;
  static lastSendDataTimes: bigint = 0n;
  // 状态标志
  static isDFU: boolean = false; // DFU升级控制


  static ABNORMAL_HISTORY_INTERVAL_TIME = 1577808000000; //历史数据处理2020-01-01之前老数据，起因秤端会有出厂时间下的历史数据，App过滤
  static ABNORMAL_HISTORY_INTERVAL_TIME_TORRE = 1675353600000; //历史数据处理2023-02-03之前老数据，起因秤端会有出厂时间下的历史数据，App过滤


  static TouristUID = "0000000000000000000000000000000000000000000000000000000000000000";
  static deleteNormalMemberId = "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";
  static normalMemberId = "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
  static normalDeleteUId = "DE000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";


  public static readonly ENABLE_NOTIFICATION_VALUE: number[] = [0x01, 0x00];
  public static readonly ENABLE_INDICATION_VALUE: number[] = [0x02, 0x00];
  public static readonly DISABLE_NOTIFICATION_VALUE: number[] = [0x00, 0x00];

  /**
   * 开启notify并设置描述符
   * @param gatt
   * @param characteristic
   * @returns
   */
  static async notify(gatt: ble.GattClientDevice, characteristic: ble.BLECharacteristic): Promise<boolean> {

    await gatt.setCharacteristicChangeNotification(characteristic, characteristic.properties?.notify);

    let u8Array: Uint8Array = new Uint8Array(TorreHelper.ENABLE_NOTIFICATION_VALUE)

    let descriptor: ble.BLEDescriptor | null = TorreHelper.getDescriptorFromArray(CCCD, characteristic.descriptors);
    if (descriptor == null) {
      let uuid: string = TorreHelper.uuidStr(characteristic.serviceUuid);
      PPLogger.e("setNotifyValue gatt.setCharacteristicChangeNotification() returned false uuid:" + uuid)
      return false;
    }
    descriptor.descriptorValue = TorreHelper.typedArrayToBuffer(u8Array)

    gatt.writeDescriptorValue(descriptor).then((writeDescriptor) => {
      PPLogger.i('writeDescriptorValue promise success');
    }).catch((e: BusinessError) => {
      PPLogger.e("setNotifyValue gatt.writeDescriptor() returned false");
      return false;
    });

    return true;
  }

  /**
   * 开启indicate并设置描述符，不设置描述符无法接收数据
   * @param gatt
   * @param characteristic
   * @returns
   */
  static async indicate(gatt: ble.GattClientDevice, characteristic: ble.BLECharacteristic): Promise<boolean> {

    await gatt.setCharacteristicChangeNotification(characteristic,
      characteristic.properties?.indicate);

    let u8Array: Uint8Array = new Uint8Array(TorreHelper.ENABLE_INDICATION_VALUE)

    let descriptor: ble.BLEDescriptor | null = TorreHelper.getDescriptorFromArray(CCCD, characteristic.descriptors);
    if (descriptor == null) {
      let uuid: string = TorreHelper.uuidStr(characteristic.serviceUuid);
      PPLogger.e("setNotifyValue gatt.setCharacteristicChangeNotification() returned false uuid:" + uuid)
      return false;
    }
    descriptor.descriptorValue = TorreHelper.typedArrayToBuffer(u8Array)

    gatt.writeDescriptorValue(descriptor).then((writeDescriptor) => {
      PPLogger.i('writeDescriptorValue promise success');
    }).catch((e: BusinessError) => {
      PPLogger.e("setNotifyValue gatt.writeDescriptor() returned false");
      return false;
    });

    return true;
  }


  /**
   * 获取体重（克）
   * 两个字节换位，并转为Int
   * @param data
   * @returns
   */
  static getWeightG(data: Uint8Array): number {
    // Check minimum length (original 10 chars = 5 bytes)
    if (data.length < 2) {
      return 0;
    }
    // Combine bytes in little-endian order (low + high)
    return (data[1] << 8) | data[0];
  }

  /**
   * 从Uint8Array中解析阻抗值
   * @param receiveData 包含阻抗数据的Uint8Array（长度至少为4）
   * @returns 拼接后的阻抗值（小端序转十进制）
   */
  static getImpedance(receiveData: Uint8Array): number {
    if (receiveData.length < 4) {
      throw new Error("Input data too short, need at least 4 bytes");
    }

    // 按照小端序拼接字节（原Java代码的逻辑：低字节+中2+中1+高字节）
    const impedanceValue =
      (receiveData[3] << 24) | // 高字节
        (receiveData[2] << 16) | // 中1
        (receiveData[1] << 8) | // 中2
      receiveData[0]; // 低字节

    return impedanceValue >>> 0; // 确保结果为无符号整数
  }

  static generateRandomFourDigitNumber(): number {
    // 使用安全随机范围算法
    const min = 1000;
    const max = 9999;
    return Math.floor(Math.random() * (max - min + 1)) + min;
  }


  /**
   * 更新测量状态（ArkTS版）
   * @param measuStateLowByte 低字节状态值
   * @param measuStateHighByte 高字节状态值
   * @param scaleState 待更新的状态对象
   * @returns 更新后的状态对象
   */
  static updateMeasureState(
    measuStateLowByte: number,
    measuStateHighByte: number,
    scaleState: PPScaleState | null
  ): PPScaleState | null {
    if (!scaleState) {
      PPLogger.w("updateMeasureState: scaleState is null");
      return null;
    }

    // 抓零状态处理
    if ((measuStateLowByte & 0x01) === 0x01) {
      PPLogger.d("protocolDataF3 抓零成功");
      scaleState.captureZeroType = PPScaleStateCaptureZeroType.CAPTURE_ZERO_SUCCESS;
    } else {
      PPLogger.d("protocolDataF3 抓零中");
      scaleState.captureZeroType = PPScaleStateCaptureZeroType.CAPTURE_ZERO_ING;
    }

    // 测量模式处理
    scaleState.measureModeType = ((measuStateLowByte & 0x02) === 0x02)
      ? PPScaleStateMeasureModeType.CALIBRATION_MODE
      : PPScaleStateMeasureModeType.MEASURE_MODE;
    PPLogger.d(`protocolDataF3 ${scaleState.measureModeType === PPScaleStateMeasureModeType.CALIBRATION_MODE ? "标定模式" : "测量模式"}`);

    // 重量状态处理
    if ((measuStateLowByte & 0x0C) === 0x0C) {
      PPLogger.d("protocolDataF3 离秤");
      scaleState.weightType = PPScaleStateWeightType.WEIGHT_LEAVE_SCALE;
    } else if ((measuStateLowByte & 0x08) === 0x08) {
      PPLogger.e("protocolDataF3 超重");
      scaleState.weightType = PPScaleStateWeightType.WEIGHT_OVERWEIGHT;
    } else if ((measuStateLowByte & 0x04) === 0x04) {
      PPLogger.d("protocolDataF3 稳定重量");
      scaleState.weightType = PPScaleStateWeightType.WEIGHT_LOCK;
    } else {
      PPLogger.d("protocolDataF3 实时重量");
      scaleState.weightType = PPScaleStateWeightType.WEIGHT_PROCESSING;
    }

    // 阻抗状态处理
    if ((measuStateLowByte & 0x30) === 0x30) {
      PPLogger.e("protocolDataF3 阻抗测量失败");
      scaleState.impedanceType = PPScaleStateImpedanceType.IMPEDANCE_FAIL;
    } else if ((measuStateLowByte & 0x20) === 0x20) {
      PPLogger.e("protocolDataF3 阻抗测量成功");
      scaleState.impedanceType = PPScaleStateImpedanceType.IMPEDANCE_SUCCESS;
    } else if ((measuStateLowByte & 0x10) === 0x10) {
      PPLogger.e("protocolDataF3 阻抗测量中");
      scaleState.impedanceType = PPScaleStateImpedanceType.IMPEDANCE_MEASURING;
    } else {
      PPLogger.e("protocolDataF3 阻抗未测量");
      scaleState.impedanceType = PPScaleStateImpedanceType.IMPEDANCE_NO_MEASURE;
    }

    // 电源状态处理
    scaleState.powerType = ((measuStateHighByte & 0x40) === 0x40)
      ? PPScaleStatePowerType.POWER_OFF
      : PPScaleStatePowerType.POWER_ON;
    if (scaleState.powerType === PPScaleStatePowerType.POWER_OFF) {
      PPLogger.e("protocolDataF3 秤关机了");
    }

    // 心率状态处理
    if ((measuStateLowByte & 0xC0) === 0xC0) {
      PPLogger.e("protocolDataF3 心率测量失败");
      scaleState.heartRateType = PPScaleStateHeartRateType.HEARTRATE_FAIL;
    } else if ((measuStateLowByte & 0x80) === 0x80) {
      PPLogger.e("protocolDataF3 心率测量成功");
      scaleState.heartRateType = PPScaleStateHeartRateType.HEARTRATE_SUCCESS;
    } else if ((measuStateLowByte & 0x40) === 0x40) {
      PPLogger.e("protocolDataF3 心率测量中");
      scaleState.heartRateType = PPScaleStateHeartRateType.HEARTRATE_MEASURING;
    } else {
      PPLogger.e("protocolDataF3 心率未测量");
      scaleState.heartRateType = PPScaleStateHeartRateType.HEARTRATE_NO_MEASURE;
    }

    // 测量结果处理
    scaleState.measureResultType = ((measuStateHighByte & 0x80) === 0x80)
      ? PPScaleStateMeasureResultType.MEASURE_RESULT_FINISH
      : PPScaleStateMeasureResultType.MEASURE_RESULT_PROCESSING;
    PPLogger.e(`protocolDataF3 ${scaleState.measureResultType === PPScaleStateMeasureResultType.MEASURE_RESULT_FINISH ? "测量完成" : "测量未完成"}`);

    return scaleState;
  }


  static typedArrayToBuffer(array: Uint8Array): ArrayBuffer {
    return array.buffer.slice(array.byteOffset, array.byteLength + array.byteOffset)
  }

  static getDescriptorFromArray(uuid: string, array: Array<ble.BLEDescriptor>): ble.BLEDescriptor | null {
    for (let i = 0; i < array.length; i++) {
      if (TorreHelper.uuid128(array[i].descriptorUuid) === TorreHelper.uuid128(uuid)) {
        return array[i]
      }
    }
    return null;
  }

  static uuid128(uuid: string): string {
    if (uuid.length === 4) {
      // 16-bit uuid
      return `0000${uuid}-0000-1000-8000-00805f9b34fb`.toLowerCase();
    } else if (uuid.length === 8) {
      // 32-bit uuid
      return `${uuid}-0000-1000-8000-00805f9b34fb`.toLowerCase();
    } else {
      // 128-bit uuid
      return uuid.toLowerCase();
    }
  }

  static uuidStr(uuid: string): string {
    uuid = TorreHelper.uuid128(uuid)
    let starts: boolean = uuid.startsWith("0000");
    let ends: boolean = uuid.endsWith("-0000-1000-8000-00805f9b34fb");
    if (starts && ends) {
      // 16-bit
      return uuid.substring(4, 8);
    } else if (ends) {
      // 32-bit
      return uuid.substring(0, 8);
    } else {
      // 128-bit
      return uuid;
    }
  }
}