import { Any, MethodResult } from '@ohos/flutter_ohos';
import { PPDeviceModel } from 'ppsdkkit/src/main/ets/vo/PPDeviceModel';
import { PPWifiModel } from 'ppsdkkit/src/main/ets/vo/PPWifiModel';
import { PPBodyBaseModel } from 'ppsdkkit/src/main/ets/vo/PPBodyBaseModel';
import { PPLefuBleConnectManager } from '../PPLefuBleConnectManager';
import { PPLefuStreamHandler } from '../PPLefuStreamHandler';
import { PPUnitType } from 'ppsdkkit/src/main/ets/enums/PPUnitType';
import { PPScaleStatePowerType } from 'ppsdkkit/src/main/ets/enums/PPScaleState';

export class PPLefuBleExtensionData {
  private bleManager: PPLefuBleConnectManager;

  constructor(bleManager: PPLefuBleConnectManager) {
    this.bleManager = bleManager;
  }

  static convert180A(model: PPDeviceModel): Device180A {
    const dict: Device180A = {
      modelNumber: model.modelNumber ?? "",
      firmwareRevision: model.firmwareVersion ?? "",
      softwareRevision: model.softwareVersion ?? "",
      hardwareRevision: model.hardwareVersion ?? "",
      serialNumber: model.serialNumber ?? "",
      manufacturerName: model.manufacturerName ?? ""
    };

    return dict;
  }

  static convertDeviceDict(device: PPDeviceModel): DeviceDict {
    return {
      deviceSettingId: device.deviceSettingId ?? 0,
      deviceMac: device.deviceMac ?? "",
      deviceName: device.deviceName ?? "",
      devicePower: device.devicePower ?? -1,
      rssi: device.rssi ?? 0,
      deviceType: device.deviceType ?? 0,
      deviceProtocolType: device.deviceProtocolType ?? 0,
      deviceCalculateType: device.deviceCalculateType ?? 0,
      deviceAccuracyType: device.deviceAccuracyType ?? 0,
      devicePowerType: device.devicePowerType ?? 0,
      deviceConnectType: device.deviceConnectType ?? 0,
      deviceFuncType: device.deviceFuncType ?? 0,
      deviceUnitType: device.deviceUnitType ?? "",
      peripheralType: device.getDevicePeripheralType(),
      sign: device.sign ?? "",
      advLength: device.advLength ?? 0,
      macAddressStart: device.macAddressStart ?? 0,
      standardType: device.standardType ?? 0
    };
  }


  static convertMeasurementDict(model: PPBodyBaseModel): MeasurementDict {

    let isPowerOff = false;

    if (model.scaleState) {
      if (model.scaleState?.powerType == PPScaleStatePowerType.POWER_ON) {
        isPowerOff = true
      }
    }

    const dict: MeasurementDict = {
      weight: model.weight ?? 0,
      impedance: model.impedance ?? 0,
      impedance100EnCode: model.ppImpedance100EnCode ?? 0,
      isHeartRating: model.isHeartRating ?? false,
      heartRate: model.heartRate ?? 0,
      isOverload: model.isOverload ?? false,
      isPlus: model.isPlus ?? false,
      measureTime: model.measureTime ?? 0,
      memberId: model.memberId ?? "",
      footLen: model.footLen ?? 0,
      unit: model.unit?.type ?? PPUnitType.Unit_KG.type,
      z100KhzLeftArmEnCode: model.z100KhzLeftArmEnCode ?? 0,
      z100KhzLeftLegEnCode: model.z100KhzLeftLegEnCode ?? 0,
      z100KhzRightArmEnCode: model.z100KhzRightArmEnCode ?? 0,
      z100KhzRightLegEnCode: model.z100KhzRightLegEnCode ?? 0,
      z100KhzTrunkEnCode: model.z100KhzTrunkEnCode ?? 0,
      z20KhzLeftArmEnCode: model.z20KhzLeftArmEnCode ?? 0,
      z20KhzLeftLegEnCode: model.z20KhzLeftLegEnCode ?? 0,
      z20KhzRightArmEnCode: model.z20KhzRightArmEnCode ?? 0,
      z20KhzRightLegEnCode: model.z20KhzRightLegEnCode ?? 0,
      z20KhzTrunkEnCode: model.z20KhzTrunkEnCode ?? 0,

      isPowerOff: isPowerOff ?? false
    };

    return dict;
  }

  static sendMeasureData(model: PPBodyBaseModel, advModel: PPDeviceModel, measureState: number): Any {
    const deviceDict = PPLefuBleExtensionData.convertDeviceDict(advModel);
    const dataDict = PPLefuBleExtensionData.convertMeasurementDict(model);

    // this.bleManager.loggerStreamHandler?.success(`测量状态:${measureState}`);
    // this.bleManager.measureStreamHandler?.success(dict);
    return {
      measurementState: measureState,
      device: deviceDict,
      data: dataDict
    };
  }

  static sendHistoryData(models: PPBodyBaseModel[]): MeasurementDict[] {
    const dataList = models.map(model => PPLefuBleExtensionData.convertMeasurementDict(model));
    return dataList;
  }


  // 1. 发送WiFi连接结果
  sendWIFIResult(isSuccess: boolean, sn: string | null, errorCode: number | null, callBack: MethodResult): void {

    callBack.success({
      success: isSuccess,
      errorCode: errorCode ?? 0,
      sn: sn ?? ""
    });
  }

  // 2. 发送WiFi SSID信息
  sendWIFISSID(ssId: string | null, callBack: MethodResult): void {

    callBack.success({
      ssId: ssId ?? "",
      isConnectWIFI: (ssId == null || ssId == "") ? false : true,
    });
  }

  // 3. 发送WiFi列表
  sendWifiList(wifiList: PPWifiModel[], callBack: MethodResult): void {
    // const array = wifiList.map(model => model.ssid);
    // callBack.success({ wifiList: array });
  }

  // 4. 发送OTA结果
  sendWifiOTA(isSuccess: boolean, errorCode: number, callBack: MethodResult): void {
    callBack.success({
      isSuccess: isSuccess,
      errorCode: errorCode
    });
  }


  // 6. 发送DFU结果（通过流）
  sendDfuResult(progress: number, isSuccess: boolean): void {
    // this.dfuStreamHandler?.event?.({
    //   progress: progress,
    //   isSuccess: isSuccess
    // });
  }

  // 7. 发送扫描状态
  sendScanState(scaning: boolean): void {
    const code = scaning ? 1 : 0;
    // this.scanStateStreamHandler?.event?.({ state: code });
  }


}


export interface MeasureDataDict {
  measurementState: number,
  device: DeviceDict,
  data: MeasurementDict
}

export interface MeasurementDict {
  weight: number;
  impedance: number;
  impedance100EnCode: number;
  isHeartRating: boolean;
  heartRate: number;
  isOverload: boolean;
  isPlus: boolean;
  measureTime: number;
  memberId: string;
  footLen: number;
  unit: number;
  z100KhzLeftArmEnCode: number;
  z100KhzLeftLegEnCode: number;
  z100KhzRightArmEnCode: number;
  z100KhzRightLegEnCode: number;
  z100KhzTrunkEnCode: number;
  z20KhzLeftArmEnCode: number;
  z20KhzLeftLegEnCode: number;
  z20KhzRightArmEnCode: number;
  z20KhzRightLegEnCode: number;
  z20KhzTrunkEnCode: number;
  isPowerOff: boolean;
}

// 先定义明确的接口类型
export interface Device180A {
  modelNumber: string;
  firmwareRevision: string;
  softwareRevision: string;
  hardwareRevision: string;
  serialNumber: string;
  manufacturerName: string;
}

export interface DeviceDict {
  deviceSettingId: number;
  deviceMac: string;
  deviceName: string;
  devicePower: number;
  rssi: number;
  deviceType: number;
  deviceProtocolType: number;
  deviceCalculateType: number;
  deviceAccuracyType: number;
  devicePowerType: number;
  deviceConnectType: number;
  deviceFuncType: number;
  deviceUnitType: string;
  peripheralType: number;
  sign: string;
  advLength: number;
  macAddressStart: number;
  standardType: number;
}