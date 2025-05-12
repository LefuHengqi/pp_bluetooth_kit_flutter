import { ble, constant } from '@kit.ConnectivityKit';
import { PPBaseDeviceControl } from '../PPBaseDeviceControl';
import { PPLogger } from '../../log/PPLogger';
import { BleUUID } from '../BleUUID';
import { BusinessError } from '@kit.BasicServicesKit';
import HexUtil from '../../utils/HexUtil';
import { PPIceDeviceDataAnalysis } from './PPIceDeviceDataAnalysis';
import { PPBodyBaseModel } from '../../vo/PPBodyBaseModel';
import { PPDeviceModel } from '../../vo/PPDeviceModel';
import { PPUnitType } from '../../enums/PPUnitType';
import { TimeFormat } from '../../enums/PPDeviceEnums';
import { ByteUtil } from '../../utils/ByteUtil';
import { PPConfigWifiStateMenu } from '../../enums/PPConfigWifiStateMenu';
import { PPWifiModel } from '../../vo/PPWifiModel';
import { PPUserModel } from '../../vo/PPUserModel';
import { PPHistoryDataInterface } from '../../listener/PPHistoryDataInterface';
import { PPDataChangeListener } from '../../listener/PPDataChangeListener';
import { TorreHelper } from '../torre/TorreHelper';
import { DateUtil } from '../../utils/DateUtil';
import { PPIceDeviceDataAnalysisExtF2 } from './PPIceDeviceDataAnalysisExtF2';
import { PPSendHelper } from '../../utils/PPSendHelper';
import { UnitUtil } from '../../utils/UnitUtil';
import PPLogSyncCmd from '../torre/log/PPLogSyncCmd';
import { PPBleFFF2ErrorCode } from '../../enums/PPBleFFF2ErrorCode';


/**
 * 连接 -> 连接中 -> 断开
 * 1、根据deviceID初始化gattClient实例，失败会有提示，业务可以做微调
 * 2、当前不同连接状态显示不同文字，连接/断开
 */

export class PPIceDeviceControl extends PPBaseDeviceControl {
  normalMtu = 244; //默认的mtu值,Torre协议最终以秤返回的为准.

  characteristicFFF1: ble.BLECharacteristic | null = null;
  characteristicFFF2: ble.BLECharacteristic | null = null;
  characteristicFFF4: ble.BLECharacteristic | null = null;
  characterBatteryUUID: ble.BLECharacteristic | null = null;
  deviceInfoCharacteristics: ble.BLECharacteristic[] = [];
  dataChangeNotify?: (data: string) => void
  dataAnalysis = new PPIceDeviceDataAnalysis();
  bodyBaseModel: PPBodyBaseModel | null = null;
  deviceDataAnalysisF2: PPIceDeviceDataAnalysisExtF2 = new PPIceDeviceDataAnalysisExtF2();

  override async onDiscoverServices(services: ble.GattService[]) {
    await this.onDiscoverServices_(services);
  }

  private async onDiscoverServices_(services: ble.GattService[]) {
    try {

      let lastService = services[services.length-1]

      services.forEach(async service => {

        if (service.serviceUuid === BleUUID.TORRE_SERVICE_UUID) {

          // 获取服务下的所有特征
          const characteristics: ble.BLECharacteristic[] = service.characteristics;
          for (const characteristic of characteristics) {
            if (characteristic.characteristicUuid === BleUUID.CHARACTERISTIC_WRITE) {
              this.characteristicFFF1 = characteristic;
              PPLogger.i("PPIceDeviceControl onDiscoverServices FFF1:" + characteristic.characteristicUuid);
              await this.targetF1()
            } else if (characteristic.characteristicUuid === BleUUID.CHARACTERISTIC_F2) {
              this.characteristicFFF2 = characteristic;
              PPLogger.i("PPIceDeviceControl onDiscoverServices FFF2:" + characteristic.characteristicUuid);
              await this.targetF2()
            } else if (characteristic.characteristicUuid === BleUUID.CHARACTERISTIC_NOTIFY) {
              this.characteristicFFF4 = characteristic;
              PPLogger.i("PPIceDeviceControl onDiscoverServices FFF4:" + characteristic.characteristicUuid);
              await this.targetNotify()
            }
          }
        } else if (service.serviceUuid === BleUUID.TORRE_DEVICE_INFO_SERVICE_UUID) {
          this.deviceInfoCharacteristics = service.characteristics;
        } else if (service.serviceUuid === BleUUID.TORRE_BATTERY_SERVICE_UUID) {
          const characteristics: ble.BLECharacteristic[] = service.characteristics;
          for (const characteristic of characteristics) {
            if (characteristic.characteristicUuid === BleUUID.TORRE_BATTERY_CHARACTERISTIC_UUID) {
              PPLogger.i(`PPIceDeviceControl onDiscoverServices batteryReadUUID:${characteristic.characteristicUuid}`);
              this.characterBatteryUUID = characteristic;
            }
          }
        }
        if (service.serviceUuid === lastService.serviceUuid) {
          await this.requestMtu();
          PPLogger.i("PPIceDeviceControl onDiscoverServices_ end");
          this.discoverServiceResultCallback?.(true)
        }
      });

    } catch (e) {
      this.discoverServiceResultCallback?.(false)
      PPLogger.e("onDiscoverServices fail msg:" + e)
    }
  }

  private async requestMtu() {
    PPLogger.d("开始请求MTU");
    try {
      this.getGattClient()?.setBLEMtuSize(this.normalMtu)
      this.getGattClient()?.on('BLEMtuChange', (mtu: number) => {
        PPLogger.i('系统化返回的  mtu: ' + mtu);
        this.normalMtu = mtu ?? 20;
        if (this.deviceModel) {
          this.deviceModel.mtu = this.normalMtu;
        }
      });
    } catch (err) {
      PPLogger.e('MTU errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  private async targetF1() {
    // this.deviceControlExtF1.deviceDataAnalysis = this.dataAnalysisF1
    PPLogger.i("PPIceDeviceControl start notify FFF1")
    if (this.characteristicFFF1?.properties?.notify) {
      await this.getGattClient()?.setCharacteristicChangeNotification(this.characteristicFFF1, true);
      PPLogger.i("PPIceDeviceControl onDiscoverServices notify FFF1:" + this.characteristicFFF1.characteristicUuid)
    }
  }

  private async targetF2() {
    PPLogger.i("PPIceDeviceControl start notify FFF2")
    if (this.characteristicFFF2?.properties?.notify) {
      await this.getGattClient()?.setCharacteristicChangeNotification(this.characteristicFFF2, true);
      PPLogger.i("PPIceDeviceControl onDiscoverServices notify FFF2:" + this.characteristicFFF2.characteristicUuid)
    }
  }


  private async targetNotify() {
    PPLogger.i("PPIceDeviceControl start notify FFF4")
    if (this.characteristicFFF4?.properties?.notify) {
      // await this.getGattClient()?.setCharacteristicChangeNotification(this.characteristicFFF4, true);
      if (this.getGattClient() && this.getGattClient() != null) {
        const result = await TorreHelper.notify(this.getGattClient()!!, this.characteristicFFF4);
        PPLogger.i(`PPIceDeviceControl onDiscoverServices notify FFF4 result:${result}}`)
      } else {
        PPLogger.e("PPIceDeviceControl onDiscoverServices notify FFF4 fail")
      }
    } else if (this.characteristicFFF4?.properties?.indicate) {
      if (this.getGattClient() && this.getGattClient() != null) {
        const result = await TorreHelper.indicate(this.getGattClient()!!, this.characteristicFFF4);
        PPLogger.i(`PPIceDeviceControl onDiscoverServices indicate FFF4 result:${result}}`)
      } else {
        PPLogger.e("PPIceDeviceControl onDiscoverServices indicate FFF4 fail")
      }
    }

    let bodyBaseModel = new PPBodyBaseModel();
    bodyBaseModel.deviceModel = new PPDeviceModel(this.deviceId, this.deviceId);
    bodyBaseModel.impedance = 0;
    bodyBaseModel.ppImpedance100EnCode = 0;
    bodyBaseModel.weight = 0;
    bodyBaseModel.unit = PPUnitType.Unit_KG;
    this.bodyBaseModel = bodyBaseModel;
  }


  override OnCharacteristicReceived(characteristic: ble.BLECharacteristic) {

    const dataArray = new Uint8Array(characteristic.characteristicValue)
    let data: string = HexUtil.formatHexString(dataArray);
    if (characteristic.characteristicUuid === BleUUID.CHARACTERISTIC_NOTIFY) {
      PPLogger.i("TorreControl Received F2:" + data + " randomNum:" + this.randomNum);
      if (dataArray) {
        this.dataAnalysis.protocolDataF4(dataArray, this.deviceModel, this.bodyBaseModel);
      }
    } else if (characteristic.characteristicUuid === BleUUID.CHARACTERISTIC_F2) {
      PPLogger.i("TorreControl Received F2:" + data);
      if (dataArray && this.bodyBaseModel) {
        this.deviceDataAnalysisF2.protocolDataF2(dataArray, this.deviceModel);
      }
    }
  }

  async syncTime(timeMillis: number): Promise<boolean> {

    // 时间同步（全部改为字节操作）
    if (timeMillis <= 0) {
      return false;
    }

    let zone = DateUtil.getUtcOffsetInHours();
    if (DateUtil.isDaylightSavingTime()) {
      zone += 1;
    }

    const zoneBytes = ByteUtil.decimalToByteList(Math.abs(zone), 1);
    if (zone < 0) {
      zoneBytes[0] |= 0x80; // 设置负号位
    }

    const timestamp = Math.floor(timeMillis / 1000);
    const timeBytes = ByteUtil.decimalToByteList(timestamp, 4);
    timeBytes.reverse(); // 转为小端序

    const command = new Uint8Array([
      0x04, 0x06, // 命令头
      ...timeBytes, // 时间戳
      zoneBytes[0], // 时区
      0x01// 时间格式
    ]);

    return this.writeResponseBytesF1(command);
  }


  async resetDevice(onResetStateResultCallBack?: (isSuccess: boolean | null) => void): Promise<boolean> {
    this.dataAnalysis.onResetStateResultCallBack = onResetStateResultCallBack;
    return this.writeResponseBytesF1(new Uint8Array([0xF9, 0x01]));
  }

  // 启动本地升级
  async startLocalOTA(): Promise<boolean> {
    const cmd = "AT+TTA";
    const hexCMD = ByteUtil.stringToHexString(cmd);
    return this.writeResponseBytesF1(ByteUtil.hexStringToUint8Array(hexCMD));
  }

  // 正常用户升级
  async startUserOTA(): Promise<boolean> {
    return this.writeResponseBytesF1(new Uint8Array([0xEF, 0x00]));
  }

  //0x00：关闭基础模式,可以测脂肪
  //0x01：打开基础模式，无法测脂肪
  async controlImpedance(state: number,
    onControlImpedanceResultCallBack?: (isSuccess: boolean | null) => void): Promise<boolean> {
    this.dataAnalysis.onControlImpedanceResultCallBack = onControlImpedanceResultCallBack;
    if (state == 0) {
      return this.writeResponseBytesF1(new Uint8Array([0xFD, 0x41, 0x00, 0x00, 0x00, 0x00, 0x00, 0xBC]));
    } else {
      return this.writeResponseBytesF1(new Uint8Array([0xFD, 0x38, 0x00, 0x00, 0x00, 0x00, 0x00, 0xC5]));
    }
  }

  async controlHeartRate(state: number, onControlImpedanceResultCallBack?: (isSuccess: boolean | null) => void): Promise<boolean> {
    this.dataAnalysis.onControlHeartRateResultCallback = onControlImpedanceResultCallBack;
    //  sendDataToWrite(state == 0 ? "FD440000000000000000B9" : "FD430000000000000000BE");
    return this.writeResponseBytesF1(state == 0 ?
      new Uint8Array([0xFD, 0x44, 0x00, 0x00, 0x00, 0x00, 0x00, 0xB9]) :
      new Uint8Array([0xFD, 0x43, 0x00, 0x00, 0x00, 0x00, 0x00, 0xBE]));
  }

  async getImpedanceState(onImpedanceStateCallBack?: (state: number | null) => void): Promise<boolean> {
    this.dataAnalysis.onImpedanceStateCallBack = onImpedanceStateCallBack;
    // sendDataToWrite("FDA000000000000000005D");
    return this.writeResponseBytesF1(new Uint8Array([0xFD, 0xDA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x005D]));
  }

  async getHeartRateState(onHeartRateStateCallBack?: (state: number | null) => void): Promise<boolean> {
    this.dataAnalysis.onHeartRateStateCallBack = onHeartRateStateCallBack;
    //    sendDataToWrite("FDA000000000000000005D");
    return this.writeResponseBytesF1(new Uint8Array([0xFD, 0xDA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x005D]));
  }

  /***********************Wifi相关*****************************************************************/

  // 修改服务器域名
  async modifyServerDomain(domain: string,
    modifyServerDomainResultCallback?: (success: boolean) => void): Promise<boolean> {

    this.dataAnalysis.modifyServerDomainResultCallback = modifyServerDomainResultCallback;

    //移除域名中的协议头（兼容http/https）
    domain = domain.replace(/^https?:\/\//i, '').split('/')[0];
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

  async getWifiSSID(onWifiInfoCallBack?: (ssid: string | null) => void): Promise<boolean> {
    this.dataAnalysis.onWifiInfoCallBack = onWifiInfoCallBack;
    return this.writeResponseBytesF1(new Uint8Array([0xF5, 0x00]));
  }

  // 配置WiFi
  async configWifi(ssid: string, password: string,
    configWifiCallBack?: (sn: string | null, stateMenu: PPConfigWifiStateMenu) => void): Promise<boolean> {

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

  async exitConfigWifi(): Promise<boolean> {
    PPLogger.d('exitConfigWifi');
    return this.writeResponseBytesF1(new Uint8Array([0x0D, 0x00]));
  }

  async getWifiList(monitorWiFiListCallBack?: (wifiModels: PPWifiModel[] | null, state: number) => void): Promise<boolean> {
    this.deviceDataAnalysisF2.sendTag = TorreHelper.SEND_TAG_WIFI_LIST;
    this.deviceDataAnalysisF2.cacheReceiveData = new Uint8Array(0);
    this.dataAnalysis.monitorWiFiListCallBack = monitorWiFiListCallBack;
    //sendDataToWrite("FB00");
    return this.writeResponseBytesF1(new Uint8Array([0xFB, 0x00]));
  }

  async exitWifiList(): Promise<boolean> {
    return this.writeResponseBytesF1(new Uint8Array([0xFB, 0x01]));
  }

  // 同步历史数据
  async syncHistory(historyDataInterface: PPHistoryDataInterface): Promise<boolean> {
    this.dataAnalysis.historyDataInterface = historyDataInterface;
    const byteArray = new Uint8Array([0xF2, 0x00]);
    return await this.writeResponseBytesF1(byteArray);
  }

  async deleteHistory(): Promise<boolean> {
    return await this.writeResponseBytesF1(new Uint8Array([0xF2, 0x01]));
  }

  /**
   * 切换婴儿模式
   *
   * @param mode 00使能抱婴模式 01退出抱婴模式
   */
  async switchBaby(mode: number): Promise<boolean> {
    const modeByte = mode === 0 ? 0x3B : 0x3C;
    const commandArray: number[] = [
      0xFD,
      modeByte,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    ];
    const command = new Uint8Array(commandArray);
    PPLogger.i(`PPTorreDeviceControl switchBaby command: ${Array.from(command)}`);
    return this.writeResponseBytesF1(ByteUtil.getXor(command));
  }


  async syncUnit(unitType: PPUnitType): Promise<boolean> {
    let unit = UnitUtil.unitTorre2Int(unitType)
    const commandArray: number[] = [
      0xFD, 0x00,
      unit,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    ];
    const command = new Uint8Array(commandArray);
    PPLogger.i(`PPTorreDeviceControl switchBaby command: ${Array.from(command)}`);
    return this.writeResponseBytesF1(ByteUtil.getXor(command));
  }


  async keepAlive(): Promise<boolean> {
    PPLogger.d("Ice keepAlive");
    return this.writeResponseBytesF1(new Uint8Array([0x10, 0x00]));
  }

  /**
   * 同步体脂
   * @param bodyFat *10
   * @returns
   */
  async syncFat(bodyFat: number): Promise<boolean> {
    PPLogger.d("Ice syncFat bodyFat:" + bodyFat);
    const bodyFatHex = ByteUtil.swapEndian(ByteUtil.numberToUint8Array(bodyFat, 2));

    const commandArray: number[] = [
      0xFD, 0x40,
      ...Array.from(bodyFatHex),
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    ];
    const command = new Uint8Array(commandArray);
    PPLogger.i(`PPTorreDeviceControl switchBaby command: ${Array.from(command)}`);
    return this.writeResponseBytesF1(ByteUtil.getXor(command));
  }


  /**********************************************************日志同步***************************************************************************************/

  // 保持原始方法名和参数
  async fetchLog(onProgress?: (progress: number, logStr: string) => void): Promise<boolean> {
    try {
      PPLogger.d("PPTorreDeviceControlExtF2 获取Log大小和开始地址");
      const cmd1 = PPLogSyncCmd.fetchLogSizeAndStartAddress();
      if (!this.deviceDataAnalysisF2) {
        PPLogger.e("PPTorreDeviceControlExtF2 fetchLog deviceDataAnalysis is null");
        return false;
      }
      const step1Result = await this._writeResponseBytesF2WaitResult(new Uint8Array(cmd1),
        {
          operationName: 'fetchLogSizeAndStartAddress',
          setCallback: (callback) => this.deviceDataAnalysisF2.fetchLogSizeAndStartAddressCallBack = callback,
          timeoutMs: 15000
        });
      if (step1Result !== PPBleFFF2ErrorCode.Ok) {
        return false;
      }
      PPLogger.d("PPTorreDeviceControlExtF2 请求Log原始数据");
      const step2Result = await this.requestLogWithProgress(onProgress);
      if (step2Result !== PPBleFFF2ErrorCode.Ok) {
        return false;
      }
      PPLogger.d("PPTorreDeviceControlExtF2 Log数据发送结束");
      const cmd3 = PPLogSyncCmd.logEnd();
      return await this._writeResponseBytesF2(new Uint8Array(cmd3));
    } catch (err) {
      PPLogger.e(`PPTorreDeviceControlExtF2 fetchLog error: ${JSON.stringify(err)}`);
      return false;
    }
  }

  async requestLogWithProgress(onProgress?: (progress: number,
    log: string) => void): Promise<PPBleFFF2ErrorCode> {
    if (!this.deviceDataAnalysisF2) {
      return PPBleFFF2ErrorCode.Unknown
    }
    // 1. 创建Promise控制器
    let resolvePromise: () => void = () => {
    }; // 初始化为空函数
    const completionPromise = new Promise<void>((resolve) => {
      resolvePromise = resolve;
    });
    //2. 设置超时（默认30秒）
    const timeoutMs = 30000;
    let timeoutId: number = setTimeout(() => {
      PPLogger.e('PPTorreDeviceControlExtF2  获取日志超时')
      resolvePromise(); // 超时后仍然resolve避免永久阻塞
      return PPBleFFF2ErrorCode.Timeout;
    }, timeoutMs);
    try {
      let endResult = false
      // 3. 注册回调（确保单次绑定）
      this.deviceDataAnalysisF2.bleRequestLogCallBack = (
        errorCode: PPBleFFF2ErrorCode,
        logStr: string,
        progress: number,
        isEnd: boolean
      ) => {
        PPLogger.v(`PPTorreDeviceControlExtF2  progress: ${progress}, isEnd: ${isEnd}, logStr: ${logStr}, errorCode: ${errorCode}`);
        // 实时进度回调
        onProgress?.(progress, logStr);
        if (timeoutId != 0) {
          clearTimeout(timeoutId); // 取消超时检测
          timeoutId = 0;
          PPLogger.d("PPTorreDeviceControlExtF2 取消超时检测");
        }
        endResult = isEnd
        // 收到结束标记时
        if (isEnd) {
          PPLogger.d('PPTorreDeviceControlExtF2 收到结束标记时，释放同步锁')
          resolvePromise(); // 释放同步锁
        } else if (errorCode !== PPBleFFF2ErrorCode.Ok) {
          resolvePromise(); // 释放同步锁
        }
      };

      // 4. 发送请求命令
      const cmd = PPLogSyncCmd.requestLogData();
      const writeSuccess = await this._writeResponseBytesF2(new Uint8Array(cmd));
      if (!writeSuccess) {
        PPLogger.e("PPTorreDeviceControlExtF2 写入命令失败");
        return PPBleFFF2ErrorCode.Unknown;
      }
      // 5. 等待日志传输完成（同步点）
      await completionPromise;

      if (endResult) {
        return PPBleFFF2ErrorCode.Ok
      } else {
        return PPBleFFF2ErrorCode.Unknown
      }
    } catch (error) {
      PPLogger.e(`请求日志失败: ${error}`);
      return PPBleFFF2ErrorCode.Unknown
    } finally {
      // 6. 清理资源
      if (timeoutId) {
        clearTimeout(timeoutId);
      }
      this.deviceDataAnalysisF2.bleRequestLogCallBack = undefined; // 移除回调
      return PPBleFFF2ErrorCode.Unknown
    }
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
          case BleUUID.TORRE_MODEL_NUMBER_UUID: {
            const data = await readData();
            if (data && this.deviceModel) {
              this.deviceModel.modelNumber = ByteUtil.bufferToAscii(data);
              PPLogger.i(`DeviceController: Model number - ${this.deviceModel.modelNumber}`);
            }
            break;
          }

          case BleUUID.TORRE_SOFTWARE_REVISION_UUID: {
            const data = await readData();
            if (data && this.deviceModel) {
              this.deviceModel.softwareVersion = ByteUtil.bufferToAscii(data);
              PPLogger.i(`DeviceController: Software rev - ${this.deviceModel.softwareVersion}`);
            }
            break;
          }

          case BleUUID.TORRE_HARDWARE_REVISION_UUID: {
            const data = await readData();
            if (data && this.deviceModel) {
              this.deviceModel.hardwareVersion = ByteUtil.bufferToAscii(data);
              PPLogger.i(`DeviceController: Hardware rev - ${this.deviceModel.hardwareVersion}`);
            }
            break;
          }

          case BleUUID.TORRE_FIRMWARE_REVISION_UUID: {
            const data = await readData();
            if (data && this.deviceModel) {
              this.deviceModel.firmwareVersion = ByteUtil.bufferToAscii(data);
              PPLogger.i(`DeviceController: Firmware rev - ${this.deviceModel.firmwareVersion}`);
            }
            break;
          }

          case BleUUID.TORRE_SERIAL_NUMBER_UUID: {
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

  registerDataChangeListener(listener: PPDataChangeListener) {
    this.dataAnalysis.dataChangeListener = listener;
  }

  // 私有写入方法
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


  private async _writeResponseBytesF2(bytes: Uint8Array): Promise<boolean> {
    try {
      const dataHex = ByteUtil.uint8ArrayToHex(bytes);
      PPLogger.d(`PPTorreDeviceControl write response targetF2 data:${dataHex}`);

      if (!this.characteristicFFF2) {
        PPLogger.e(`PPTorreDeviceControl Characteristic Response FFF2 not initialized`);
        return false;
      }
      let writeFlag: boolean = false;

      let writeValue: ArrayBuffer = ByteUtil.typedArrayToBuffer(bytes);
      this.characteristicFFF2.characteristicValue = writeValue;
      let errorMessage: string = ""
      let errorCode: string = ""
      try {
        await this.getGattClient()?.writeCharacteristicValue(this.characteristicFFF2, ble.GattWriteType.WRITE)
      } catch (e) {
        errorMessage = e.message;
        errorCode = e.code.toString()
        writeFlag = true;
      }
      if (writeFlag) {
        PPLogger.e(`PPTorreDeviceControl writeCharacteristic errorcde: ${errorCode} ,  errmessage: ${errorMessage}`);
        return false;
      }
      PPLogger.e(`PPTorreDeviceControl _writeResponseBytesF2 Write success`);
      return true;
    } catch (err) {
      PPLogger.e(`PPTorreDeviceControl _writeResponseBytesF2 error: ${JSON.stringify(err)}`);
      return false;
    }
  }

  /**
   * 写入数据并等待响应
   * @param bytes 要写入的二进制数据
   * @param options 配置参数
   */
  async _writeResponseBytesF2WaitResult(bytes: Uint8Array, options: WriteOptions): Promise<PPBleFFF2ErrorCode> {
    const operationName = options.operationName;
    const setCallback = options.setCallback;
    const timeoutMs = options.timeoutMs ?? 2000;

    PPLogger.d(`${operationName} 操作开始`);
    // 1. 创建Promise控制器（只需resolve）
    let resolvePromise: (value: PPBleFFF2ErrorCode) => void;
    const operationPromise = new Promise<PPBleFFF2ErrorCode>((resolve) => {
      PPLogger.d(`${operationName} 主控制器返回`)
      resolvePromise = resolve;
    });
    let mErrorCode = PPBleFFF2ErrorCode.Unknown;
    // 2. 设置超时控制
    let timeoutId: number | undefined;
    const timeoutPromise = new Promise<PPBleFFF2ErrorCode>((_, reject) => {
      timeoutId = setTimeout(() => {
        PPLogger.e(`${operationName} 操作超时`);
        reject(new Error(`${operationName} 操作超时`));
        return PPBleFFF2ErrorCode.Timeout;
      }, timeoutMs);
    });

    try {
      // 3. 设置单次回调
      setCallback((errorCode: PPBleFFF2ErrorCode) => {
        PPLogger.d(`${operationName} 操作结束，错误码: ${errorCode}`);
        if (timeoutId) {
          clearTimeout(timeoutId);
          timeoutId = undefined;
        }
        mErrorCode = errorCode
        resolvePromise(errorCode);
      });
      PPLogger.d(`${operationName} 开始写入`)
      // 4. 执行写入
      await this._writeResponseBytesF2(bytes);

      // 5. 等待结果
      await Promise.race([operationPromise, timeoutPromise.catch(() => PPBleFFF2ErrorCode.Timeout)]);

      return mErrorCode;
    } catch (error) {
      PPLogger.e(`${operationName} 写入错误: ${JSON.stringify(error)}`);
      return PPBleFFF2ErrorCode.Unknown;
    } finally {
      // 6. 确保清理资源
      if (timeoutId) {
        clearTimeout(timeoutId);
      }
      return mErrorCode;
    }
  }
}


export interface WriteOptions {
  operationName: string;
  setCallback: (callback: (errorCode: PPBleFFF2ErrorCode) => void) => void;
  timeoutMs?: number;
}

