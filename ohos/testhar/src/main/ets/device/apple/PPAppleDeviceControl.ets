import { ble } from '@kit.ConnectivityKit';
import { PPBaseDeviceControl } from '../PPBaseDeviceControl';
import { PPLogger } from '../../log/PPLogger';
import { BleUUID } from '../BleUUID';
import HexUtil from '../../utils/HexUtil';
import { ByteUtil } from '../../utils/ByteUtil';
import { PPSendHelper } from '../../utils/PPSendHelper';
import { UnitUtil } from '../../utils/UnitUtil';
import { PPUserModel } from '../../vo/PPUserModel';
import { PPUnitType } from '../../enums/PPUnitType';
import { PPDeviceType, PPUserGender } from '../../enums/PPDeviceEnums';
import { PPScaleHelper } from '../../utils/PPScaleHelper';
import { PPDeviceModel } from '../../vo/PPDeviceModel';
import { BusinessError } from '@kit.BasicServicesKit';
import { PPHistoryDataInterface } from '../../listener/PPHistoryDataInterface';
import { PPConfigWifiStateMenu } from '../../enums/PPConfigWifiStateMenu';
import { PPAppleDeviceDataAnalysis } from './PPAppleDeviceDataAnalysis';
import { PPDataChangeListener } from '../../listener/PPDataChangeListener';

/**
 * 连接 -> 连接中 -> 断开
 * 1、根据deviceID初始化gattClient实例，失败会有提示，业务可以做微调
 * 2、当前不同连接状态显示不同文字，连接/断开
 */

export class PPAppleDeviceControl extends PPBaseDeviceControl {
  characteristicFFF1: ble.BLECharacteristic | null = null;
  dataChangeNotify?: (data: string) => void
  deviceInfoCharacteristics: ble.BLECharacteristic[] = [];
  characterBatteryUUID: ble.BLECharacteristic | null = null;
  dataAnalysis = new PPAppleDeviceDataAnalysis();

  override onDiscoverServices(services: ble.GattService[]) {
    try {
      services.forEach(async service => {

        if (service.serviceUuid === BleUUID.SERVICE_MAIN) {

          // 获取服务下的所有特征
          const characteristics: ble.BLECharacteristic[] = service.characteristics;
          for (const characteristic of characteristics) {
            if (characteristic.characteristicUuid === BleUUID.CHARACTERISTIC_WRITE) {
              this.characteristicFFF1 = characteristic;
              PPLogger.i(`PPAppleDeviceControl onDiscoverServices targetWrite:${characteristic.characteristicUuid}`);
            } else if (characteristic.characteristicUuid === BleUUID.CHARACTERISTIC_NOTIFY) {
              PPLogger.i(`PPAppleDeviceControl onDiscoverServices targetNotify:${characteristic.characteristicUuid}`);
              // 订阅通知特征
              if (characteristic.properties?.notify) {
                await this.getGattClient()?.setCharacteristicChangeNotification(characteristic,
                  characteristic.properties?.notify);
              }
            }
          }
        } else if (service.serviceUuid === BleUUID.SERVICE_DEVICE_INFO) {
          this.deviceInfoCharacteristics = service.characteristics;
        } else if (service.serviceUuid === BleUUID.SERVICE_BATTERY) {
          const characteristics: ble.BLECharacteristic[] = service.characteristics;
          for (const characteristic of characteristics) {
            if (characteristic.characteristicUuid === BleUUID.CHARACTERISTIC_BATTERY_LEVEL) {
              PPLogger.i(`PPCoconutDeviceControl onDiscoverServices batteryReadUUID:${characteristic.characteristicUuid}`);
              this.characterBatteryUUID = characteristic;
            }
          }
        }
      });
      if (this.discoverServiceResultCallback) {
        this.discoverServiceResultCallback(true)
      }
    } catch (e) {
      if (this.discoverServiceResultCallback) {
        this.discoverServiceResultCallback(false)
      }
      PPLogger.e("onDiscoverServices fail msg:" + e)
    }
  }

  override OnCharacteristicReceived(characteristic: ble.BLECharacteristic) {
    let dataArray = new Uint8Array(characteristic.characteristicValue);
    let data: string = HexUtil.formatHexString(dataArray);
    if (this.dataChangeNotify) {
      this.dataChangeNotify(data);
    }
    if (characteristic.characteristicUuid === BleUUID.CHARACTERISTIC_NOTIFY) {
      PPLogger.i(`PPAppleDeviceControl OnCharacteristicReceived apple notify:${data}`);
      this.dataAnalysis.analysisData(dataArray, this.deviceModel ?? null);
    }
  }

  startNotify(dataChangeNotify?: (data: string) => void) {
    this.dataChangeNotify = dataChangeNotify;
  }

  // 配置WiFi
  async configWifi(ssid: string, password: string | null,
    configWifiCallBack?: (sn: string | null, stateMenu: PPConfigWifiStateMenu | null) => void): Promise<boolean> {

    this.dataAnalysis.monitorConfigResultCallback = configWifiCallBack;

    const dataList: Uint8Array[] = PPSendHelper.codeBySSIDAndPassword(ssid, password);
    try {
      for (const bytes of dataList) {
        const success = await this.writeResponseBytesF1(bytes);
        if (!success) {
          return false;
        }
      }
      return true;
    } catch (err) {
      console.error(`configWifi error: ${JSON.stringify(err)}`);
      return false;
    }
  }

  // 修改服务器域名
  async modifyServerDomain(domain: string,
    modifyServerDomainResultCallback?: (success: boolean) => void): Promise<boolean> {

    this.dataAnalysis.modifyServerDomainResultCallback = modifyServerDomainResultCallback;

    domain = domain.replace(/https?:\/\//g, '');
    const ipHex = ByteUtil.stringToHexString(domain);
    const xorValue = ByteUtil.getXorValue(ByteUtil.hexToBytes(ipHex));
    const xorHex = xorValue.toString(16).toUpperCase().padStart(2, '0');
    const dataHex = `F800${ByteUtil.decimalToHex(ipHex.length / 2)}${xorHex}${ipHex}`;
    const byteList = ByteUtil.getSendByteList(dataHex, 40);

    try {
      for (const bytes of byteList) {
        const success = await this.writeResponseBytesF1(bytes);
        if (!success) {
          return false;
        }
      }
      return true;
    } catch (err) {
      console.error(`modifyServerDomain error: ${JSON.stringify(err)}`);
      return false;
    }
  }

  // 设备复位
  async resetDevice(monitorResetStateResultCallback?: (resultState: boolean) => void): Promise<boolean> {
    this.dataAnalysis.onResetStateResultCallBack = monitorResetStateResultCallback;
    const byteArray = new Uint8Array([0xF9, 0x01]);
    return await this.writeResponseBytesF1(byteArray);
  }

  // 同步历史数据
  async syncHistory(historyDataInterface: PPHistoryDataInterface): Promise<boolean> {
    this.dataAnalysis.historyDataInterface = historyDataInterface;
    const byteArray = new Uint8Array([0xF2, 0x00]);
    return await this.writeResponseBytesF1(byteArray);
  }

  // 读取WiFi信息
  async readWifiInfo(getWifiInfoCallback?: (ssid: string | null) => void): Promise<boolean> {
    this.dataAnalysis.getWifiInfoCallback = getWifiInfoCallback;
    const byteArray = new Uint8Array([0xF5, 0x00]);
    return await this.writeResponseBytesF1(byteArray);
  }

  // 删除历史数据
  async deleteHistory(): Promise<boolean> {
    const byteArray = new Uint8Array([0xF2, 0x01]);
    return await this.writeResponseBytesF1(byteArray);
  }

  private buildTimeSyncCommand(milliseconds: number): Uint8Array {
    if (milliseconds <= 0) {
      return new Uint8Array(0);
    }

    const date = new Date(milliseconds);
    const components = [
      date.getFullYear(), // 2字节
      date.getMonth() + 1, // 1字节
      date.getDate(), // 1字节
      date.getHours(), // 1字节
      date.getMinutes(), // 1字节
      date.getSeconds()// 1字节
    ];

    // 命令头 0xF1
    const commandHeader = new Uint8Array([0xF1]);

    // 转换各时间组件
    const timeBytes = components.map((comp, index) =>
    index === 0 ? ByteUtil.decimalToBytes(comp, 2) : ByteUtil.decimalToBytes(comp));

    // 合并所有字节
    return ByteUtil.concatArrays([commandHeader, ...timeBytes]);
  }

  // 最终调用方法
  async syncTime(milliseconds: number): Promise<boolean> {
    try {
      const command = this.buildTimeSyncCommand(milliseconds);
      if (command.length === 0) {
        return false;
      }

      return await this.writeResponseBytesF1(command);
    } catch (err) {
      PPLogger.e(`Time sync failed: ${JSON.stringify(err)}`);
      return false;
    }
  }

  async syncUnit(unitType: PPUnitType, userModel: PPUserModel | null = null): Promise<boolean> {
    let byteArray = new Uint8Array(16); // Adjust size as needed
    let position = 0;

    let unit = 0;
    if (this.deviceModel == null) {
      unit = UnitUtil.getUnitInt(unitType, "");
    } else {
      unit = UnitUtil.getUnitInt(unitType, this.deviceModel?.deviceName ?? "");
    }

    let modeByte = this._getMode(userModel, this.deviceModel == undefined ? null : this.deviceModel);

    // Start building the byte array
    byteArray[position++] = 0xFD; // Start byte

    // Add mode (converted from hex string to number)
    // let modeByte = parseInt(mode, 16);
    byteArray[position++] = modeByte;

    // Add unit
    byteArray[position++] = unit;

    // Add zeros
    byteArray[position++] = 0x00;

    if (PPScaleHelper.isFuncTypeUserInfo(this.deviceModel?.deviceFuncType) ||
      this.deviceModel?.modelNumber == "UTC-0") {
      // Athlete mode (0, 1, or 2)
      byteArray[position++] = userModel != null && userModel.isAthleteMode ? 0x02 : 0x00;

      // Gender (0: female, 1: male)
      byteArray[position++] = userModel != null && userModel.sex == PPUserGender.PPUserGenderFemale ? 0x00 : 0x01;

      // Age (6-99)
      byteArray[position++] = userModel != null ? (userModel.age == undefined ? 0x00 : userModel.age) : 0x00;

      // Height (90-220cm)
      byteArray[position++] =
        userModel != null ? (userModel.userHeight == undefined ? 0x00 : userModel.userHeight) : 0x00;

      // Add two zeros
      byteArray[position++] = 0x00;
      byteArray[position++] = 0x00;
    } else {
      // Add the alternative pattern
      byteArray[position++] = 0x00;
      byteArray[position++] = 0x00;
      byteArray[position++] = 0x00;
      byteArray[position++] = 0x00;
      byteArray[position++] = 0x00;
      byteArray[position++] = 0x00;
    }

    // Calculate XOR
    let xor = 0;
    for (let i = 0; i < position; i++) {
      xor ^= byteArray[i];
    }

    // Add XOR byte
    byteArray[position++] = xor;

    // Slice the array to actual size
    let finalArray = byteArray.slice(0, position);

    return await this.writeResponseBytesF1(finalArray);
  }

  private _getMode(userModel: PPUserModel | null, deviceModel: PPDeviceModel | null): number {
    const DEFAULT_MODE = 0x00;
    const PREGNANT_MODE = 0x38;
    const UTC0_MODE = 0x37;

    if (!deviceModel) {
      return DEFAULT_MODE;
    }

    if (userModel?.isPregnantMode) {
      return PREGNANT_MODE;
    }

    if (deviceModel?.modelNumber === "UTC-0") {
      return UTC0_MODE;
    }

    if (PPScaleHelper.isFuncTypeWifi(deviceModel?.deviceFuncType) ||
      deviceModel?.deviceType === PPDeviceType.PPDeviceTypeCA) {
      return DEFAULT_MODE;
    }

    return UTC0_MODE;
  }

  // 读取设备信息
  async readDeviceInfo(): Promise<PPDeviceModel | null> {
    if (!this.deviceInfoCharacteristics) {
      PPLogger.e('DeviceController: No characteristics available');
      return null;
    }

    try {
      for (const characteristic of this.deviceInfoCharacteristics) {
        const charUUID = characteristic.characteristicUuid;

        // 统一使用安全读取方法
        const readData = async (): Promise<ArrayBuffer | null> => {
          try {
            const data = await this.getGattClient()?.readCharacteristicValue(characteristic);
            return data?.characteristicValue ?? null;
          } catch (e) {
            PPLogger.e(`Read characteristic ${charUUID} failed: ${JSON.stringify(e)}`);
            return null;
          }
        };

        switch (charUUID) {
          case BleUUID.CHARACTERISTIC_MODEL_NUMBER: {
            const data = await readData();
            if (data && this.deviceModel) {
              this.deviceModel.modelNumber = ByteUtil.bufferToAscii(data);
              PPLogger.i(`DeviceController: Model number - ${this.deviceModel.modelNumber}`);
            }
            break;
          }

          case BleUUID.CHARACTERISTIC_SOFTWARE_REV: {
            const data = await readData();
            if (data && this.deviceModel) {
              this.deviceModel.softwareVersion = ByteUtil.bufferToAscii(data);
              PPLogger.i(`DeviceController: Software rev - ${this.deviceModel.softwareVersion}`);
            }
            break;
          }

          case BleUUID.CHARACTERISTIC_HARDWARE_REV: {
            const data = await readData();
            if (data && this.deviceModel) {
              this.deviceModel.hardwareVersion = ByteUtil.bufferToAscii(data);
              PPLogger.i(`DeviceController: Hardware rev - ${this.deviceModel.hardwareVersion}`);
            }
            break;
          }

          case BleUUID.CHARACTERISTIC_FIRMWARE_REV: {
            const data = await readData();
            if (data && this.deviceModel) {
              this.deviceModel.firmwareVersion = ByteUtil.bufferToAscii(data);
              PPLogger.i(`DeviceController: Firmware rev - ${this.deviceModel.firmwareVersion}`);
            }
            break;
          }

          case BleUUID.CHARACTERISTIC_SERIAL_NUMBER: {
            const data = await readData();
            if (data && this.deviceModel) {
              this.deviceModel.serialNumber = ByteUtil.bufferToAscii(data);
              PPLogger.i(`DeviceController: Serial number - ${this.deviceModel.serialNumber}`);
            }
            break;
          }
        }
      }
      return this.deviceModel;
    } catch (err) {
      PPLogger.e(`DeviceController: Error reading device info - ${JSON.stringify(err)}`);
      return null;
    }
  }

  /**
   * 读取设备电量
   * @returns 电量百分比（0-100），失败返回 -1
   */
  async readBatteryLevel(): Promise<number> {
    if (!this.characterBatteryUUID) {
      PPLogger.e('Battery characteristic not initialized');
      return -1;
    }

    try {
      // 1. 安全读取特征值（可能返回undefined）
      const dataCharacteristic = await this.getGattClient()?.readCharacteristicValue(this.characterBatteryUUID);

      const arrayBuffer = dataCharacteristic?.characteristicValue;

      // 2. 空值检查（处理undefined和空ArrayBuffer）
      if (!arrayBuffer || arrayBuffer.byteLength === 0) {
        PPLogger.e('Empty battery characteristic value');
        return -1;
      }

      // 3. 转换为Uint8Array读取数据
      const bytes = new Uint8Array(arrayBuffer);
      const batteryLevel = bytes[0];

      // 4. 验证范围（0-100）
      if (batteryLevel >= 0 && batteryLevel <= 100) {
        PPLogger.i(`Battery level: ${batteryLevel}%`);
        return batteryLevel;
      } else {
        PPLogger.e(`Invalid battery value: ${batteryLevel}`);
        return -1;
      }
    } catch (err) {
      PPLogger.e(`Read failed: ${JSON.stringify(err as BusinessError)}`);
      return -1;
    }
  }


  private async writeResponseBytesF1(bytes: Uint8Array): Promise<boolean> {
    if (!this.characteristicFFF1) {
      PPLogger.e(`PPTorreDeviceControl Characteristic FFF1 not initialized`);
      return false;
    }
    let writeFlag: boolean = false;
    let writeValue: ArrayBuffer = ByteUtil.typedArrayToBuffer(bytes);
    this.characteristicFFF1.characteristicValue = writeValue;
    PPLogger.e(`PPTorreDeviceControl Writing bytes: ${Array.from(bytes)}`);
    let errorMessage: string = ""
    let errorCode: string = ""
    try {
      await this.getGattClient()?.writeCharacteristicValue(this.characteristicFFF1, ble.GattWriteType.WRITE)
    } catch (e) {
      errorMessage = e.message;
      errorCode = e.code.toString()
      writeFlag = true;
    }
    if (writeFlag) {
      PPLogger.e(`PPTorreDeviceControl writeCharacteristic errorcde: ${errorCode} ,  errmessage: ${errorMessage}`);
      return false;
    }
    PPLogger.e(`PPTorreDeviceControl Write success`);
    return true;
  }

  registerDataChangeListener(listener: PPDataChangeListener) {
    this.dataAnalysis.dataChangeListener = listener;
  }
}
