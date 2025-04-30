import { PPLefuBleConnectManager } from '../PPLefuBleConnectManager';
import { PPLefuStreamHandler } from '../PPLefuStreamHandler';

export class PPLefuBleExtensionData {
  private bleManager: PPLefuBleConnectManager;

  constructor(bleManager: PPLefuBleConnectManager) {
    this.bleManager = bleManager;
  }

  convert180A(model: any): Record<string, any> {
    const dict: Record<string, any> = {
      modelNumber: model.modelNumber,
      firmwareRevision: model.firmwareRevision,
      softwareRevision: model.softwareRevision,
      hardwareRevision: model.hardwareRevision,
      serialNumber: model.serialNumber,
      manufacturerName: model.manufacturerName
    };

    return this.filterNullValues(dict);
  }

  convertDeviceDict(device: any): Record<string, any> {
    return {
      deviceSettingId: device.deviceSettingId,
      deviceMac: device.deviceMac,
      deviceName: device.deviceName,
      devicePower: device.devicePower,
      rssi: device.rssi,
      deviceType: device.deviceType,
      deviceProtocolType: device.deviceProtocolType,
      deviceCalculateType: device.deviceCalculateType,
      deviceAccuracyType: device.deviceAccuracyType,
      devicePowerType: device.devicePowerType,
      deviceConnectType: device.deviceConnectType,
      deviceFuncType: device.deviceFuncType,
      deviceUnitType: device.deviceUnitList,
      peripheralType: device.peripheralType,
      sign: device.sign,
      advLength: device.advLength,
      macAddressStart: device.macAddressStart,
      standardType: device.standardType
    };
  }

  sendMeasureData(model: any, advModel: any, measureState: number): void {
    const deviceDict = this.convertDeviceDict(advModel);
    const dataDict = this.convertMeasurementDict(model);

    this.bleManager.loggerStreamHandler?.success(`测量状态:${measureState}`);

    const dict = {
      measurementState: measureState,
      device: deviceDict,
      data: dataDict
    };

    this.bleManager.measureStreamHandler?.success(dict);
  }

  sendHistoryData(models: any[]): void {
    const dataList = models.map(model => this.convertMeasurementDict(model));
    
    this.bleManager.loggerStreamHandler?.success(`历史数据-数量:${dataList.length}`);
    this.bleManager.historyStreamHandler?.success({ dataList });
  }

  sendBlePermissionState(state: number): void {
    let stateValue = 0;
    switch (state) {
      case 1: // unauthorized
        stateValue = 1;
        break;
      case 2: // poweredOn
        stateValue = 2;
        break;
      case 3: // poweredOff
        stateValue = 3;
        break;
    }

    this.bleManager.blePermissionStreamHandler?.success({ state: stateValue });
  }

  private filterNullValues(dict: Record<string, any>): Record<string, any> {
    return Object.fromEntries(
      Object.entries(dict).filter(([_, value]) => value != null)
    );
  }

  private convertMeasurementDict(model: any): Record<string, any> {
    const dict = {
      weight: model.weight,
      impedance: model.impedance,
      impedance100EnCode: model.impedance100EnCode,
      isHeartRating: model.isHeartRating,
      heartRate: model.heartRate,
      isOverload: model.isOverload,
      isPlus: model.isPlus,
      measureTime: model.dateTimeInterval * 1000,
      memberId: model.memberId,
      footLen: model.footLen,
      unit: model.unit,
      z100KhzLeftArmEnCode: model.z100KhzLeftArmEnCode,
      z100KhzLeftLegEnCode: model.z100KhzLeftLegEnCode,
      z100KhzRightArmEnCode: model.z100KhzRightArmEnCode,
      z100KhzRightLegEnCode: model.z100KhzRightLegEnCode,
      z100KhzTrunkEnCode: model.z100KhzTrunkEnCode,
      z20KhzLeftArmEnCode: model.z20KhzLeftArmEnCode,
      z20KhzLeftLegEnCode: model.z20KhzLeftLegEnCode,
      z20KhzRightArmEnCode: model.z20KhzRightArmEnCode,
      z20KhzRightLegEnCode: model.z20KhzRightLegEnCode,
      z20KhzTrunkEnCode: model.z20KhzTrunkEnCode,
      isPowerOff: model.isPowerOff
    };

    return this.filterNullValues(dict);
  }
}