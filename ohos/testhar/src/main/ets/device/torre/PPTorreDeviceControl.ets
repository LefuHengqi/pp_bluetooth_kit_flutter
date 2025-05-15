import { ble } from '@kit.ConnectivityKit';
import { PPBaseDeviceControl } from '../PPBaseDeviceControl';
import { PPLogger } from '../../log/PPLogger';
import { BleUUID } from '../BleUUID';
import { BusinessError } from '@kit.BasicServicesKit';
import HexUtil from '../../utils/HexUtil';
import { PPTorreDeviceDataAnalysis } from './PPTorreDeviceDataAnalysis';
import { PPBodyBaseModel } from '../../vo/PPBodyBaseModel';
import { PPDeviceModel } from '../../vo/PPDeviceModel';
import { PPUnitType } from '../../enums/PPUnitType';
import { PPTorreDeviceControlExtF1 } from './PPTorreDeviceControlExtF1';
import { PPTorreDeviceControlExtF2 } from './PPTorreDeviceControlExtF2';
import { TimeFormat } from '../../enums/PPDeviceEnums';
import { ByteUtil } from '../../utils/ByteUtil';
import { PPConfigWifiStateMenu } from '../../enums/PPConfigWifiStateMenu';
import { PPWifiModel } from '../../vo/PPWifiModel';
import { TorreHelper } from './TorreHelper';
import { PPUserModel } from '../../vo/PPUserModel';
import { PPHistoryDataInterface } from '../../listener/PPHistoryDataInterface';
import { PPDataChangeListener } from '../../listener/PPDataChangeListener';
import { OnOTAStateListener } from '../../listener/OnOTAStateListener';


/**
 * 连接 -> 连接中 -> 断开
 * 1、根据deviceID初始化gattClient实例，失败会有提示，业务可以做微调
 * 2、当前不同连接状态显示不同文字，连接/断开
 */

export class PPTorreDeviceControl extends PPBaseDeviceControl {
  normalMtu = 244; //默认的mtu值,Torre协议最终以秤返回的为准.


  characteristicFFF1: ble.BLECharacteristic | null = null;
  characteristicFFF2: ble.BLECharacteristic | null = null;
  characteristicFFF3: ble.BLECharacteristic | null = null;
  characterBatteryUUID: ble.BLECharacteristic | null = null;
  dataChangeNotify?: (data: string) => void
  dataAnalysis = new PPTorreDeviceDataAnalysis();
  dataAnalysisF1 = this.dataAnalysis.dataAnalysisExtF1;
  dataAnalysisF2 = this.dataAnalysis.dataAnalysisExtF2;
  dataAnalysisF3 = this.dataAnalysis.dataAnalysisExtF3;
  bodyBaseModel: PPBodyBaseModel | null = null;
  deviceControlExtF1 = new PPTorreDeviceControlExtF1();
  deviceControlExtF2 = new PPTorreDeviceControlExtF2();
  deviceInfoCharacteristics: ble.BLECharacteristic[] = [];

  override async onDiscoverServices(services: ble.GattService[]) {
    await this.onDiscoverServices_(services);
  }

  async onDiscoverServices_(services: ble.GattService[]) {
    try {

      let lastService = services[services.length-1]

      services.forEach(async service => {

        if (service.serviceUuid === BleUUID.TORRE_SERVICE_UUID) {

          // 获取服务下的所有特征
          const characteristics: ble.BLECharacteristic[] = service.characteristics;
          for (const characteristic of characteristics) {
            if (characteristic.characteristicUuid === BleUUID.TORRE_CHARACTERISTIC_F1_UUID) {
              this.characteristicFFF1 = characteristic;
              PPLogger.i("PPTorreDeviceControl onDiscoverServices FFF1:" + characteristic.characteristicUuid);
              await this.targetF1()
            } else if (characteristic.characteristicUuid === BleUUID.TORRE_CHARACTERISTIC_F2_UUID) {
              this.characteristicFFF2 = characteristic;
              PPLogger.i("PPTorreDeviceControl onDiscoverServices FFF2:" + characteristic.characteristicUuid);
              await this.targetF2()
            } else if (characteristic.characteristicUuid === BleUUID.TORRE_CHARACTERISTIC_F3_UUID) {
              this.characteristicFFF3 = characteristic;
              PPLogger.i("PPTorreDeviceControl onDiscoverServices FFF3:" + characteristic.characteristicUuid);
              await this.targetF3()
            }
          }
        } else if (service.serviceUuid === BleUUID.TORRE_DEVICE_INFO_SERVICE_UUID) {
          this.deviceInfoCharacteristics = service.characteristics;
        } else if (service.serviceUuid === BleUUID.TORRE_BATTERY_SERVICE_UUID) {
          const characteristics: ble.BLECharacteristic[] = service.characteristics;
          for (const characteristic of characteristics) {
            if (characteristic.characteristicUuid === BleUUID.TORRE_BATTERY_CHARACTERISTIC_UUID) {
              PPLogger.i(`PPTorreDeviceControl onDiscoverServices batteryReadUUID:${characteristic.characteristicUuid}`);
              this.characterBatteryUUID = characteristic;
            }
          }
        }
        if (service.serviceUuid === lastService.serviceUuid) {
          await this.requestMtu();
          PPLogger.i("PPTorreDeviceControl onDiscoverServices_ end");
          this.discoverServiceResultCallback?.(true)
        }
      });

    } catch (e) {
      this.discoverServiceResultCallback?.(false)
      PPLogger.e("onDiscoverServices fail msg:" + e)
    }
  }

  async requestMtu() {
    PPLogger.d("开始请求MTU");
    try {
      this.getGattClient()?.setBLEMtuSize(this.normalMtu)
      this.getGattClient()?.on('BLEMtuChange', (mtu: number) => {
        PPLogger.i('系统化返回的  mtu: ' + mtu);
        this.dataAnalysisF1.mtuCallBack = (mtu: number | null) => {
          PPLogger.i(`拿到外设返回的MTU:${mtu}`);
          this.normalMtu = mtu ?? 20;
          if (this.deviceModel) {
            this.deviceModel.mtu = this.normalMtu;
            this.deviceControlExtF2.deviceModel = this.deviceModel;
          }
        }
        this.getMtuLen();
      });
    } catch (err) {
      PPLogger.e('MTU errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  async targetF1() {
    this.deviceControlExtF1.gattClient = this.getGattClient()
    this.deviceControlExtF1.characteristicFFF1 = this.characteristicFFF1
    // this.deviceControlExtF1.deviceDataAnalysis = this.dataAnalysisF1
    PPLogger.i("PPTorreDeviceControl start notify FFF1")
    if (this.characteristicFFF1?.properties?.notify) {
      await this.getGattClient()?.setCharacteristicChangeNotification(this.characteristicFFF1, true);
      PPLogger.i("PPTorreDeviceControl onDiscoverServices notify FFF1:" + this.characteristicFFF1.characteristicUuid)
    }
  }

  async targetF2() {
    this.deviceControlExtF2.gattClient = this.getGattClient()
    this.deviceControlExtF2.characteristicFFF2 = this.characteristicFFF2
    this.deviceControlExtF2.deviceDataAnalysis = this.dataAnalysisF2
    PPLogger.i("PPTorreDeviceControl start notify FFF2")
    if (this.characteristicFFF2?.properties?.notify) {
      await this.getGattClient()?.setCharacteristicChangeNotification(this.characteristicFFF2, true);
      PPLogger.i("PPTorreDeviceControl onDiscoverServices notify FFF2:" + this.characteristicFFF2.characteristicUuid)
    }
  }


  async targetF3() {
    PPLogger.i("PPTorreDeviceControl start notify FFF3")
    if (this.characteristicFFF3?.properties?.notify) {
      // await this.getGattClient()?.setCharacteristicChangeNotification(this.characteristicFFF3, true);
      if (this.getGattClient() && this.getGattClient() != null) {
        const result = await TorreHelper.notify(this.getGattClient()!!, this.characteristicFFF3);
        PPLogger.i(`PPTorreDeviceControl onDiscoverServices notify FFF3 result:${result}}`)
      } else {
        PPLogger.e("PPTorreDeviceControl onDiscoverServices notify FFF3 fail")
      }
    } else if (this.characteristicFFF3?.properties?.indicate) {
      if (this.getGattClient() && this.getGattClient() != null) {
        const result = await TorreHelper.indicate(this.getGattClient()!!, this.characteristicFFF3);
        PPLogger.i(`PPTorreDeviceControl onDiscoverServices indicate FFF3 result:${result}}`)
      } else {
        PPLogger.e("PPTorreDeviceControl onDiscoverServices indicate FFF3 fail")
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
    if (characteristic.characteristicUuid === BleUUID.TORRE_CHARACTERISTIC_F1_UUID) {
      PPLogger.i("TorreControl Received F1:" + data);
      if (dataArray) {
        this.dataAnalysis.protocolDataF1(dataArray, this.deviceModel);
      }
    } else if (characteristic.characteristicUuid === BleUUID.TORRE_CHARACTERISTIC_F2_UUID) {
      PPLogger.i("TorreControl Received F2:" + data + " randomNum:" + this.randomNum);
      if (dataArray) {
        this.dataAnalysis.protocolDataF2(dataArray, this.deviceModel);
      }
    } else if (characteristic.characteristicUuid === BleUUID.TORRE_CHARACTERISTIC_F3_UUID) {
      PPLogger.i("TorreControl Received F3:" + data);
      if (dataArray && this.bodyBaseModel) {
        this.dataAnalysis.protocolDataF3(dataArray, this.deviceModel, this.bodyBaseModel);
      }
    }
  }

  async syncTime(timeMills: number, timeType: TimeFormat = TimeFormat.HOUR_24): Promise<boolean> {
    return this.deviceControlExtF1.syncTime(timeMills, timeType);
  }

  private async getMtuLen(): Promise<boolean> {
    return this.deviceControlExtF1.getMtuLen();
  }

  /**
   * 启动测量结果回调
   * 0x00：成功
   * 0x01：设备配网中，开始测量失败
   * 0x02：设备OTA中，开始测量失败
   *
   * @param state
   */
  async startMeasure(onStartMeasureResultCallBack?: (state: number) => void): Promise<boolean> {
    this.dataAnalysisF1.onStartMeasureResultCallBack = onStartMeasureResultCallBack;
    return this.deviceControlExtF1.startMeasure();
  }

  async stopMeasure(): Promise<boolean> {
    return this.deviceControlExtF1.stopMeasure();
  }

  async startBabyModel(step: number, weight: number, onControlBabyResultCallBack: (isSuccess: boolean) => void): Promise<boolean> {
    this.dataAnalysisF1.onControlBabyResultCallBack = onControlBabyResultCallBack;
    return this.deviceControlExtF1.switchBaby(0, step, weight);
  }

  async exitBabyModel(onControlBabyResultCallBack: (isSuccess: boolean) => void): Promise<boolean> {
    this.dataAnalysisF1.onControlBabyResultCallBack = onControlBabyResultCallBack;
    return this.deviceControlExtF1.switchBaby(1);
  }

  /**
   * @param type               0x01：设置模式  0x02：获取模式
   * @param state              功能类型为0x01时：
   *                           0x00：工厂模式 0x01：用户模式 0x02：标定模式
   * @param sendResultCallBack
   */
  async switchMode(type: number, state: number): Promise<boolean> {
    return this.deviceControlExtF1.switchMode(type, state);
  }

  //0x00：关闭基础模式,可以测脂肪
  //0x01：打开基础模式，无法测脂肪
  async controlImpedance(isOn: boolean,
    onControlImpedanceResultCallBack?: (isSuccess: boolean | false) => void): Promise<boolean> {
    this.dataAnalysisF1.onControlImpedanceResultCallBack = onControlImpedanceResultCallBack;
    return this.deviceControlExtF1.controlImpedance(isOn ? 0 : 1);
  }

  async controlImpedance2(isOn: boolean,
    onControlImpedanceResultCallBack?: (isSuccess: boolean | false) => void): Promise<boolean> {
    this.dataAnalysisF1.onControlImpedanceResultCallBack = onControlImpedanceResultCallBack;
    return this.deviceControlExtF1.controlImpedance(isOn ? 0 : 1);
  }

  async controlHeartRate(open: boolean,
    onControlHeartRateResultCallback?: (isSuccess: boolean | false) => void): Promise<boolean> {
    this.dataAnalysisF1.onControlHeartRateResultCallback = onControlHeartRateResultCallback;
    return this.deviceControlExtF1.controlHeartRate(open ? 0 : 1);
  }

  async getImpedanceState(onImpedanceStateCallBack?: (isOn: boolean | true) => void): Promise<boolean> {
    this.dataAnalysisF1.onImpedanceStateCallBack = onImpedanceStateCallBack;
    return this.deviceControlExtF1.getImpedanceState();
  }

  async getHeartRateState(onHeartRateStateCallBack?: (isOn: boolean | true) => void): Promise<boolean> {
    this.dataAnalysisF1.onHeartRateStateCallBack = onHeartRateStateCallBack;
    return this.deviceControlExtF1.getHeartRateState();
  }

  async getWifiSSID(readDeviceSsidCallBack?: (ssid: string) => void): Promise<boolean> {
    return this.deviceControlExtF2.getWifiSSID(readDeviceSsidCallBack);
  }

  async getWifiState(onConfigWifiStateResultCallback?: (state: number | null) => void): Promise<boolean> {
    this.dataAnalysisF1.onConfigWifiStateResultCallback = onConfigWifiStateResultCallback;
    return this.deviceControlExtF1.getWifiState();
  }

  async getWifiMac(onReadDeviceWifiMacCallBack?: (mac: string | null) => void): Promise<boolean> {
    this.dataAnalysisF1.onReadDeviceWifiMacCallBack = onReadDeviceWifiMacCallBack;
    return this.deviceControlExtF1.getWifiMac();
  }

  async keepAlive(): Promise<boolean> {
    return this.deviceControlExtF1.keepAlive();
  }

  async getLight(onLightCallBack?: (light: number | 0) => void
  ): Promise<boolean> {
    this.dataAnalysisF1.onLightCallBack = onLightCallBack;
    return this.deviceControlExtF1.getLight();
  }

  async setLight(light: number, onLightResultCallBack?: (isSuccess: boolean | false) => void
  ): Promise<boolean> {
    this.dataAnalysisF1.onLightResultCallBack = onLightResultCallBack;
    return this.deviceControlExtF1.setLight(light);
  }

  async getLanguage(onGetLanguageCallBack?: (language: number) => void): Promise<boolean> {
    this.dataAnalysisF1.onGetLanguageCallBack = onGetLanguageCallBack;
    return this.deviceControlExtF1.getLanguage();
  }

  async getLanguageList(onGetLanguageListCallBack?: (languages: Array<number>) => void): Promise<boolean> {
    this.dataAnalysisF1.onGetLanguageListCallBack = onGetLanguageListCallBack;
    return this.deviceControlExtF1.getLanguageList();
  }

  async setLanguage(
    language: number,
    onSetLanguageCallBack?: (isSuccess: boolean) => void
  ): Promise<boolean> {
    this.dataAnalysisF1.onSetLanguageCallBack = onSetLanguageCallBack;
    return this.deviceControlExtF1.setLanguage(language);
  }

  async getUnit(onDeviceUnitCallBack?: (unitType: PPUnitType | null) => void): Promise<boolean> {
    this.dataAnalysisF1.onDeviceUnitCallBack = onDeviceUnitCallBack;
    return this.deviceControlExtF1.getUnit();
  }

  async syncUnit(unitType: PPUnitType,
    onDeviceUnitResultCallBack?: (isSuccess: boolean | null) => void): Promise<boolean> {
    this.dataAnalysisF1.onDeviceUnitResultCallBack = onDeviceUnitResultCallBack;
    return this.deviceControlExtF1.syncUnit(unitType);
  }

  async resetDevice(onResetStateResultCallBack?: (isSuccess: boolean | null) => void): Promise<boolean> {
    this.dataAnalysisF1.onResetStateResultCallBack = onResetStateResultCallBack;
    return this.deviceControlExtF1.resetDevice();
  }

  /**
   * 设备绑定状态
   *
   * @param type  1设置  2获取
   * @param state 0设备未绑定 1已绑定
   */
  async deviceBindStatus(binding: boolean,
    onBindStateResultCallBack?: (isSuccess: boolean | false) => void): Promise<boolean> {
    this.dataAnalysisF1.onBindStateResultCallBack = onBindStateResultCallBack;
    //state 0设备未绑定 1已绑定
    return this.deviceControlExtF1.deviceBindStatus(1, binding ? 1 : 0);
  }

  /**
   *   state 0设备未绑定 1已绑定
   * @param onGetDeviceBindStateCallBack
   * @returns
   */
  async getDeviceBindStatus(onBindStateCallBack?: (isBinding: boolean | false) => void): Promise<boolean> {
    this.dataAnalysisF1.onBindStateCallBack = onBindStateCallBack;
    return this.deviceControlExtF1.deviceBindStatus(2);
  }

  /**
   * 模拟模式开关
   * @param type 1设置 2获取
   * @param state 0关闭 1开启
   */
  async demoModeSwitch(type: number, state: number,
    onDemoModeSwitchResultCallBack?: (isSuccess: boolean | null) => void): Promise<boolean> {
    this.dataAnalysisF1.onDemoModeSwitchResultCallBack = onDemoModeSwitchResultCallBack;
    return this.deviceControlExtF1.demoModeSwitch(type, state);
  }

  async clearDeviceUserInfo(onClearDataResultCallBack?: (isSuccess: boolean) => void): Promise<boolean> {
    this.dataAnalysisF1.onClearDataResultCallBack = onClearDataResultCallBack;
    return this.deviceControlExtF1.clearDeviceUserInfo();
  }

  async clearHistoryData(onClearDataResultCallBack?: (isSuccess: boolean) => void): Promise<boolean> {
    this.dataAnalysisF1.onClearDataResultCallBack = onClearDataResultCallBack;
    return this.deviceControlExtF1.clearHistoryData();
  }

  async clearAllDeviceInfo(onClearDataResultCallBack?: (isSuccess: boolean) => void): Promise<boolean> {
    this.dataAnalysisF1.onClearDataResultCallBack = onClearDataResultCallBack;
    return this.deviceControlExtF1.clearAllDeviceInfo();
  }

  async clearConfigWifiInfo(onClearDataResultCallBack?: (isSuccess: boolean) => void): Promise<boolean> {
    this.dataAnalysisF1.onClearDataResultCallBack = onClearDataResultCallBack;
    return this.deviceControlExtF1.clearConfigWifiInfo();
  }

  async clearSettingInfo(onClearDataResultCallBack?: (isSuccess: boolean) => void): Promise<boolean> {
    this.dataAnalysisF1.onClearDataResultCallBack = onClearDataResultCallBack;
    return this.deviceControlExtF1.clearSettingInfo();
  }

  // 启动本地升级
  async startLocalOTA(otaStateListener: OnOTAStateListener): Promise<boolean> {
    this.dataAnalysisF1.otaStateListener = otaStateListener;
    return this.deviceControlExtF1.startLocalOTA();
  }

  // 正常用户升级
  async startUserOTA(otaStateListener: OnOTAStateListener): Promise<boolean> {
    this.dataAnalysisF1.otaStateListener = otaStateListener;
    return this.deviceControlExtF1.startUserOTA();
  }

  async setRGB(
    defaultColor: string,
    againColor: string,
    lossColor: string,
    lightEnable: number,
    lightMode: number,
    onSetRGBCallBack?: (state: number | null) => void
  ): Promise<boolean> {
    this.dataAnalysisF1.onSetRGBCallBack = onSetRGBCallBack;
    return this.deviceControlExtF1.setRGB(
      defaultColor,
      againColor,
      lossColor,
      lightEnable,
      lightMode
    );
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


  /***********************以下开始FFF2指令*****************************************************************/
  /***********************Wifi相关*****************************************************************/

  async configWifi(domainName: string, ssid: string, password: string | null,
    configWifiResultCallBack?: (configState: PPConfigWifiStateMenu, resultCode: string) => void): Promise<boolean> {
    return this.deviceControlExtF2.configWifi(domainName, ssid, password, configWifiResultCallBack);
  }

  async exitConfigWifi(): Promise<boolean> {
    PPLogger.d('exitConfigWifi');
    return this.deviceControlExtF2.exitConfigWifi();
  }

  async getWifiList(monitorWiFiListCallBack?: (wifiModels: PPWifiModel[] | null) => void): Promise<boolean> {
    this.dataAnalysisF2.sendTag = TorreHelper.SEND_TAG_WIFI_LIST;
    this.dataAnalysisF2.cacheReceiveData = new Uint8Array(0);
    return this.deviceControlExtF2.getWifiList(monitorWiFiListCallBack);
  }

  /***********************历史数据*****************************************************************/

  /**
   * 同步指定账号userId的历史数据，返回数据包含memberId
   * @param userModel
   * @param historyDataInterface
   * @returns
   */
  async syncUserHistory(userModel: PPUserModel, historyDataInterface: PPHistoryDataInterface | null): Promise<boolean> {
    this.dataAnalysisF2.sendTag = TorreHelper.SEND_TAG_USER_HISTORY;
    this.dataAnalysisF2.cacheReceiveData = new Uint8Array(0);
    return this.deviceControlExtF2.syncUserHistory(userModel, historyDataInterface);
  }

  /**
   * 同步游客历史数据，返回数据不属于某个用户
   * @param historyDataInterface
   * @returns
   */
  async syncTouristHistory(historyDataInterface: PPHistoryDataInterface | null): Promise<boolean> {
    this.dataAnalysisF2.sendTag = TorreHelper.SEND_TAG_USER_HISTORY;
    this.dataAnalysisF2.cacheReceiveData = new Uint8Array(0);
    const userModel = new PPUserModel();
    userModel.userID = TorreHelper.TouristUID;
    userModel.memberID = TorreHelper.TouristUID;
    return this.deviceControlExtF2.syncUserHistory(userModel, historyDataInterface);
  }

  // async syncAllHistory(userModel: PPUserModel, historyDataInterface: PPHistoryDataInterface | null): Promise<boolean> {
  //   return this.deviceControlExtF2.syncUserHistory(userModel, historyDataInterface);
  // }

  /***********************同步日志*****************************************************************/
  async syncLog(logFolder: string, onProgress?: (progress: number, logFilePath: string, isEnd: boolean) => void): Promise<boolean> {
    this.dataAnalysisF2.sendTag = TorreHelper.SEND_TAG_LOG;
    this.dataAnalysisF2.cacheReceiveData = new Uint8Array(0);
    return this.deviceControlExtF2.fetchLog(logFolder, onProgress);
  }

  async syncUserInfo(userModel: PPUserModel): Promise<boolean> {
    return this.deviceControlExtF2.syncUserInfo(userModel);
  }

  async deleteUserInfo(userModel: PPUserModel): Promise<boolean> {
    return this.deviceControlExtF2.deleteUserInfo(userModel);
  }

  async sendCurrentUserInfo(userModel: PPUserModel): Promise<boolean> {
    return this.deviceControlExtF2.sendCurrentUserInfo(userModel);
  }

  async getUserList(monitorUserListCallBack?: (userIds: string[]) => void): Promise<boolean> {
    this.dataAnalysisF2.sendTag = TorreHelper.SEND_TAG_USER_LIST;
    this.dataAnalysisF2.cacheReceiveData = new Uint8Array(0);
    return this.deviceControlExtF2.getUserList(monitorUserListCallBack);
  }

  registerDataChangeListener(listener: PPDataChangeListener) {
    this.dataAnalysisF3.dataChangeListener = listener;
  }

  registerHistoryChangeListener(onHistoryDataChange: (() => void) | null = null) {
    this.dataAnalysisF3.onHistoryDataChange = onHistoryDataChange;
  }
}
