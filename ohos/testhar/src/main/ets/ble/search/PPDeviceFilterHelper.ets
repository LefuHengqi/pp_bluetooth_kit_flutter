import { PPDeviceAccuracyType, PPDeviceCalculateType, PPDeviceConnectType, PPDevicePowerType, PPDeviceProtocolType, PPDeviceType } from "../../enums/PPDeviceEnums";
import { PPLogger } from "../../log/PPLogger";
import { PPBluetoothKit } from "../../PPBluetoothKit";
import { DeviceConfigVo } from "../../vo/DeviceConfigVo";
import { PPDeviceModel } from "../../vo/PPDeviceModel";

export class PPDeviceFilterHelper {
  static matchDeviceConfigs(deviceName: string): DeviceConfigVo[] {
    // 初始化两个匹配列表
    const nameFullMatchDeviceList: DeviceConfigVo[] = [];
    const nameSemiMatchDeviceList: DeviceConfigVo[] = [];

    // 遍历所有设备配置
    PPBluetoothKit.deviceConfigVos?.forEach((it) => {
      const configDeviceName = it.deviceName;

      if (configDeviceName) {
        if (deviceName === configDeviceName) {
          // 全匹配
          nameFullMatchDeviceList.push(it);
        } else if (deviceName.includes(configDeviceName)) {
          // 半匹配
          nameSemiMatchDeviceList.push(it);
        }
      }
    });

    // 返回匹配结果：优先返回全匹配列表，如果没有则返回半匹配列表
    return nameFullMatchDeviceList.length > 0
      ? nameFullMatchDeviceList
      : nameSemiMatchDeviceList;
  }

  static deviceConfigVoToPPDeviceModel(deviceConfigVo: DeviceConfigVo | null, advDataArray: Uint8Array, deviceName: string, remoteId: string): PPDeviceModel {
    let deviceAddress = "";
    const start = deviceConfigVo?.macAddressStart ?? 0;

    PPLogger.v(`deviceConfigVoToPPDeviceModel deviceName:${deviceName} start:${start}`);

    if (start > 0) {
      deviceAddress = PPDeviceFilterHelper.getMac(advDataArray, start);
      if (!deviceAddress) {
        deviceAddress = remoteId;
      }
    } else {
      deviceAddress = remoteId;
    }

    const deviceModel = new PPDeviceModel(deviceName, deviceAddress);

    try {
      if (deviceConfigVo) {
        deviceModel.deviceRemoteId = remoteId;
        deviceModel.deviceConnectType = deviceConfigVo.deviceConnectType ?? 0;
        deviceModel.deviceType = deviceConfigVo.deviceType ?? 0;
        deviceModel.deviceProtocolType = deviceConfigVo.deviceProtocolType ?? 0;
        deviceModel.deviceCalculateType = deviceConfigVo.deviceCalcuteType ?? 0;
        deviceModel.deviceFuncType = deviceConfigVo.deviceFuncType ?? 0;
        deviceModel.devicePowerType = deviceConfigVo.devicePowerType ?? 0;
        deviceModel.deviceAccuracyType = deviceConfigVo.deviceAccuracyType ?? 0;
        deviceModel.deviceUnitType = deviceConfigVo.deviceUnitType ?? "";
        deviceModel.advLength = deviceConfigVo.advLength ?? 0;
        deviceModel.macAddressStart = deviceConfigVo.macAddressStart ?? 0;
        deviceModel.deviceSettingId = deviceConfigVo.id ?? 0;
        deviceModel.sign = deviceConfigVo.sign ?? "";
        deviceModel.imgUrl = deviceConfigVo.imgUrl && deviceConfigVo.imgUrl.length > 0
          ? deviceConfigVo.imgUrl
          : "https://unique.lefuenergy.com/prod/scale_img/default_no_border_black.png";
        deviceModel.productModel = deviceConfigVo.productModel ?? "";
        deviceModel.standardType = deviceConfigVo.standardType ?? 0;
      }
    } catch (e) {
      PPLogger.e(`deviceConfigVoToPPDeviceModel error:${e}`);
      deviceModel.deviceRemoteId = remoteId;
      deviceModel.deviceConnectType = PPDeviceConnectType.PPDeviceConnectTypeDirect;
      deviceModel.deviceType = PPDeviceType.PPDeviceTypeCF;
      deviceModel.deviceProtocolType = PPDeviceProtocolType.PPDeviceProtocolTypeTorre;
      deviceModel.deviceCalculateType = PPDeviceCalculateType.PPDeviceCalculateTypeAlternate;
      deviceModel.deviceFuncType = deviceConfigVo?.deviceFuncType ?? 0;
      deviceModel.devicePowerType = PPDevicePowerType.PPDevicePowerTypeBattery;
      deviceModel.deviceAccuracyType = PPDeviceAccuracyType.PPDeviceAccuracyTypePoint005;
      deviceModel.deviceUnitType = deviceConfigVo?.deviceUnitType ?? "";
      deviceModel.advLength = deviceConfigVo?.advLength ?? 0;
      deviceModel.macAddressStart = deviceConfigVo?.macAddressStart ?? 0;
      deviceModel.deviceSettingId = deviceConfigVo?.id ?? 0;
      deviceModel.sign = deviceConfigVo?.sign ?? "";
      deviceModel.imgUrl = "https://unique.lefuenergy.com/prod/scale_img/default_no_border_black.png";
      deviceModel.productModel = "";
      deviceModel.standardType = deviceConfigVo?.standardType ?? 0;
    }

    if (deviceConfigVo?.imgUrl && deviceConfigVo.imgUrl.length > 0) {
      deviceModel.imgUrl = deviceConfigVo.imgUrl;
    }

    PPLogger.v(`deviceConfigVoToPPDeviceModel 2 ${deviceModel.toString()}`);
    return deviceModel;
  }

  static getMac(advDataArray: Uint8Array, serverStart: number): string {
    try {
      // 计算需要的字节长度（6字节MAC地址）
      const macByteLength = 6;
      const endIndex = serverStart + 1

      // 检查数据长度是否足够
      if (!advDataArray || advDataArray.length < endIndex) {
        return "";
      }

      // 提取MAC地址部分的字节
      const macBytes = advDataArray.slice(endIndex - macByteLength, endIndex);

      // 格式化为MAC地址格式（XX:XX:XX:XX:XX:XX）
      let formatted = "";
      for (let i = 0; i < macBytes.length; i++) {
        if (i > 0) {
          formatted += ":";
        }
        // 将字节转换为两位十六进制，并确保大写
        formatted += (macBytes[i] & 0xFF).toString(16).padStart(2, '0').toUpperCase();
      }

      return formatted;
    } catch (e) {
      console.error(`getMac error: ${e}`);
      return "";
    }
  }

  /**
   * 解析广播数据中的厂商自定义数据 (Type = 0xFF)
   * @param advData - 原始广播数据 (Uint8Array)
   * @returns 厂商自定义数据的Uint8Array，若不存在则返回空Uint8Array
   */
  static parseManufacturerData(advData: Uint8Array): Uint8Array {
    if (!advData || advData.length === 0) {
      return new Uint8Array(0);
    }

    let index = 0;
    while (index < advData.length - 1) {
      const length = advData[index++] & 0xFF; // AD Structure长度
      if (length === 0) {
        break;
      }

      const type = advData[index++] & 0xFF; // AD Structure类型
      const dataStart = index;
      const dataEnd = index + length - 1;

      // 检查是否为厂商自定义数据 (0xFF)
      if (type === 0xFF && dataEnd <= advData.length) {
        return advData.slice(dataStart, dataEnd);
      }
      index = dataEnd;
    }

    return new Uint8Array(0);
  }
}