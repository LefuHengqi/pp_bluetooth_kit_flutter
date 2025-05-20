import { access, ble } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import HexUtil from '../../utils/HexUtil';
import { PPLogger } from '../../log/PPLogger';
import { PPDeviceModel } from '../../vo/PPDeviceModel';
import { PPBluetoothKit } from '../../PPBluetoothKit';
import { PPDeviceCalculateType, PPDeviceProtocolType } from '../../enums/PPDeviceEnums';
import { ByteUtil } from '../../utils/ByteUtil';
import { PPDeviceFilterHelper } from './PPDeviceFilterHelper';

/**
 * 模拟BLE客户端，进行BLE连接
 * 1、工程启动时请求蓝牙授权，在EntryAbility完成申请
 * 2、页面打开时获取设备蓝牙开启状态
 * 3、以serviceUuid为过滤条件进行扫描，实际开发过程中可以按业务场景配置扫描条件或不设置，具体可以参考官网
 * 4、基于扫描出来的随机Mac地址(deviceId)做连接/断开操作
 * 5、可以基于connectStateChange获取连接状态做其他操作
 */

export class PPBleSearch {
  bleSwitch: boolean = false;
  scanSwitch: boolean = false;
  bleDevices: Array<PPDeviceModel> = [];
  private static _instance: PPBleSearch | null = null;
  scanResultCallback?: (device: PPDeviceModel) => void;

  public static getInstance(): PPBleSearch {
    if (!PPBleSearch._instance) {
      PPLogger.d("PPBleSearch getInstance: Creating new instance");
      PPBleSearch._instance = new PPBleSearch();
    } else {
      PPLogger.d("PPBleSearch getInstance: Returning existing instance");
    }
    return PPBleSearch._instance;
  }

  /**
   * 获取蓝牙开关状态
   */
  getBleState() {
    try {
      let state = access.getState();
      if (access.BluetoothState.STATE_ON === state) {
        this.bleSwitch = true;
        this.scanSwitch = true;
      } else {
        this.bleSwitch = false;
      }
    } catch (err) {
      PPLogger.e('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  /**
   * 发起BLE扫描流程
   */
  startScan(callback: (device: PPDeviceModel) => void) {
    this.scanResultCallback = callback;
    this.bleDevices = [];
    try {
      //订阅BLE设备发现
      ble.on('BLEDeviceFind', (data: Array<ble.ScanResult>) => {
        this.scanCallback(data)
      });
      let scanOption: ble.ScanOptions = {
        dutyMode: ble.ScanDuty.SCAN_MODE_LOW_LATENCY,
        matchMode: ble.MatchMode.MATCH_MODE_AGGRESSIVE,
        interval: 0
      };

      ble.startBLEScan(null, scanOption);

      // ble.startBLEScan([scanFilter], scanOptions);
      PPLogger.i('ble Client start BLE Scan success')
      this.scanSwitch = true;
    } catch (err) {
      this.scanSwitch = false;
      PPLogger.e('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  /**
   * 关闭BLE扫描流程
   */
  stopScan() {
    try {
      //取消订阅BLE设备发现
      ble.off('BLEDeviceFind', (data: Array<ble.ScanResult>) => {
        PPLogger.i('offBLEDeviceFind bluetooth device find off = ' + JSON.stringify(data))
      });
      ble.stopBLEScan();
      PPLogger.i('ble Client stop BLE Scan success')
      this.scanSwitch = false;
    } catch (err) {
      PPLogger.e('stopScan errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message)
    }
  }

  async scanCallback(data: Array<ble.ScanResult>) {

    if (data == null || data.length <= 0) {
      return
    }
    PPLogger.i('onBLEDeviceFind bluetooth device find on = ' + JSON.stringify(data));

    for (const item of data) {

      let uint8_msg = new Uint8Array(item.data);

      let gattClient = ble.createGattClientDevice(item.deviceId);
      let deviceName: string = await gattClient.getDeviceName();
      if (deviceName === undefined || deviceName === null || deviceName === "") {
        return;
      }
      let remoteId: string = item.deviceId;

      // 3. 解析所有AD Structure
      const advDataArray = PPDeviceFilterHelper.parseManufacturerData(uint8_msg);

      if (!advDataArray) {
        return
      }

      if (this.scanResultCallback) {
        const deviceModel = this.deviceToPPDeviceModel(deviceName, remoteId, advDataArray)
        if (deviceModel) {
          this.scanResultCallback(deviceModel);
        }
      }
    }
  }


  deviceToPPDeviceModel(deviceName: string, deviceId: string, advDataArray: Uint8Array): PPDeviceModel | null {
    if (advDataArray.length <= 0) {
      return null
    }

    let advData = HexUtil.formatHexString(advDataArray);

    PPLogger.i("deviceToPPDeviceModel deviceName:" + deviceName + " remoteId:" + deviceId + " advHex:" + advData);

    const existingIndex = this.bleDevices.findIndex(
      item => item.deviceRemoteId === deviceId
    );
    if (existingIndex === -1) {

      const deviceConfigVos = PPDeviceFilterHelper.matchDeviceConfigs(deviceName);

      if (deviceConfigVos) {
        let deviceModel: PPDeviceModel | null = null;

        deviceConfigVos.forEach(configVo => {

          if (configVo.advLength == advDataArray.length || configVo.advLength == 999) {

            if (configVo.deviceProtocolType == PPDeviceProtocolType.PPDeviceProtocolTypeV3) {

              const outData = advDataArray.subarray((configVo.macAddressStart ?? 0) + 1, (configVo.macAddressStart ?? 0) + 12)

              const mSign = HexUtil.formatHexString(outData.subarray(0, 3));
              if (mSign == configVo.sign) {
                deviceModel = PPDeviceFilterHelper.deviceConfigVoToPPDeviceModel(configVo, advDataArray, deviceName, deviceId)
              }
            } else if (configVo.deviceProtocolType == PPDeviceProtocolType.PPDeviceProtocolTypeTorre) {
              PPLogger.d(`DeviceFilterHelper Torre deviceCalcuteType:${configVo.deviceCalcuteType} index:${PPDeviceCalculateType.PPDeviceCalculateTypeAlternate8}`);

              if (configVo.deviceCalcuteType === PPDeviceCalculateType.PPDeviceCalculateTypeAlternate8 ||
                configVo.deviceCalcuteType === PPDeviceCalculateType.PPDeviceCalculateTypeAlternate8_3) {

                deviceModel = PPDeviceFilterHelper.deviceConfigVoToPPDeviceModel(configVo, advDataArray, deviceName, deviceId);

                // 提取算法差异标识
                const algorithmDifferHex = advData.substring(advData.length - 2);
                const decimalValue = parseInt(algorithmDifferHex, 16);
                const binary = decimalValue.toString(2).padStart(8, '0');

                PPLogger.i(`DeviceFilterHelper Torre binary:${binary}`);

                const localSign = binary.substring(3, 5);
                PPLogger.i(`DeviceFilterHelper torre sign:${configVo.sign} localSign:${localSign}`);

                if (localSign === "00") {
                  // 走旧线材算法
                  deviceModel.deviceCalculateType = PPDeviceCalculateType.PPDeviceCalculateTypeAlternate8;
                } else if (localSign === "01") {
                  // 走新线材算法
                  deviceModel.deviceCalculateType = PPDeviceCalculateType.PPDeviceCalculateTypeAlternate8_3;
                }

              } else {
                deviceModel =  PPDeviceFilterHelper.deviceConfigVoToPPDeviceModel(configVo, advDataArray, deviceName, deviceId);
              }

              if (deviceModel) {
                PPLogger.i(`DeviceFilterHelper getDeviceModel ${deviceModel.toString()}`);
              } else {
                PPLogger.e(`DeviceFilterHelper deviceName:${configVo.deviceName} sign:${configVo.sign} ` +
                  `deviceProtocolType:${configVo.deviceProtocolType} advLength:${configVo.advLength} ` +
                  `macAddressStart:${configVo.macAddressStart} advDataLen:${advData.length}`);
              }
            } else if (configVo.deviceProtocolType == PPDeviceProtocolType.PPDeviceProtocolTypeV4) {
              if (configVo.sign == "FF") {
                PPLogger.i(`DeviceFilterHelper Ice V4 sign:${configVo.sign}`);
                deviceModel =
                   PPDeviceFilterHelper.deviceConfigVoToPPDeviceModel(configVo, advDataArray, deviceName, deviceId);
              } else {
                // 获取广告数据的最后两个字符
                let algorithmDifferHex: string = advData.substring(advData.length - 2);
                // 将16进制字符串转换为十进制整数
                let decimalValue: number = parseInt(algorithmDifferHex, 16);
                // 将十进制转换为8位二进制字符串，前面补零
                let binary: string = decimalValue.toString(2).padStart(8, '0');
                // 获取第3-5位（从0开始计数）
                let localSign: string = binary.substring(3, 5);

                PPLogger.i(`DeviceFilterHelper Ice V4 sign:${configVo.sign} localSign:${localSign} binary:${binary}`);

                deviceModel = PPDeviceFilterHelper.deviceConfigVoToPPDeviceModel(configVo, advDataArray, deviceName, deviceId);

                if (localSign == "00") {
                  // 走旧线材算法
                  deviceModel.deviceCalculateType = PPDeviceCalculateType.PPDeviceCalculateTypeAlternate8_0;
                } else if (localSign == "01") {
                  // 走新线材算法
                  deviceModel.deviceCalculateType = PPDeviceCalculateType.PPDeviceCalculateTypeAlternate8_4;
                } else {
                  // 前面自动走云端，不用再次赋值
                }
              }

            } else {
              deviceModel =  PPDeviceFilterHelper.deviceConfigVoToPPDeviceModel(configVo, advDataArray, deviceName, deviceId);
            }

          }
          if (deviceModel) {
            this.bleDevices.push(deviceModel);
            PPLogger.i(`DeviceFilterHelper getDeviceModel ${deviceModel}`);
          } else {
            PPLogger.e(`DeviceFilterHelper deviceName:${configVo.deviceName} sign:${configVo.sign} deviceProtocolType:${configVo.deviceProtocolType}
            advLength:${configVo.advLength} macAddressStart:${configVo.macAddressStart} advDataLen:${advDataArray.length}`);
          }

        })

        return deviceModel;
      }
      return null
    } else {
      return this.bleDevices[existingIndex]
    }
  }

  analysisBroadcastDataNormal(scanRecord: Uint8Array): BroadcastData {
    const beacon = new Beacon(scanRecord);
    const broadcastData: BroadcastData = {
      connectAbled: false,
      beacondata: new Uint8Array(0),
      dataLen: 0
    };

    for (const beaconItem of beacon.mItems) {
      if (beaconItem.type === AD_TYPE_FLAGS) {
        if (beaconItem.bytes && beaconItem.bytes.length > 0) {
          // 判断是否可连接 (0x06表示可连接)
          broadcastData.connectAbled = beaconItem.bytes[0] === 0x06;
        }
      }

      if (beaconItem.type === AD_TYPE_MANUFACTURER) {
        broadcastData.beacondata = beaconItem.bytes;
        broadcastData.dataLen = beaconItem.len - 1; // 减去类型字节
      }
    }

    return broadcastData;
  }


  getManufacturerSpecificData(advBytes: Uint8Array): Map<number, Uint8Array> {
    const manufacturerDataMap = new Map<number, Uint8Array>();
    let n = 0;
    while (n < advBytes.byteLength) {
      const fieldLen = advBytes[n] & 0xFF;
      if (fieldLen <= 0) {
        break;
      }
      if (n + fieldLen >= advBytes.byteLength) {
        break;
      }
      const dataType = advBytes[n + 1] & 0xFF;
      if (dataType === 0xFF && fieldLen >= 3) {
        // Manufacturer Id
        const high = (advBytes[n + 3] & 0xFF) << 8;
        const low = (advBytes[n + 2] & 0xFF);
        const manufacturerId = high | low;
        const msdLen = fieldLen - 3;
        const msdPtr = n + 4;
        if (manufacturerDataMap.has(manufacturerId)) {
          const existingData = manufacturerDataMap.get(manufacturerId)!;
          const mergedData = new Uint8Array(existingData.length + msdLen);
          mergedData.set(existingData, 0);
          mergedData.set(advBytes.subarray(msdPtr, msdPtr + msdLen), existingData.length);
          manufacturerDataMap.set(manufacturerId, mergedData);
        } else {
          const data = advBytes.subarray(msdPtr, msdPtr + msdLen);
          manufacturerDataMap.set(manufacturerId, data);
        }
      }
      n += fieldLen + 1;
    }
    return manufacturerDataMap;
  }
}

class BeaconItem {
  type: number; // AD Type
  len: number; // 数据长度
  bytes: Uint8Array; // 数据内容

  constructor(type: number, len: number, bytes: Uint8Array) {
    this.type = type;
    this.len = len;
    this.bytes = bytes;
  }
}

class Beacon {
  mItems: BeaconItem[] = [];

  constructor(scanRecord: Uint8Array) {
    let offset = 0;

    while (offset < scanRecord.length) {
      const len = scanRecord[offset];

      // 长度检查
      if (len === 0 || offset + len >= scanRecord.length) {
        break;
      }

      const type = scanRecord[offset + 1];
      const dataStart = offset + 2;
      const dataEnd = offset + 1 + len;
      const bytes = scanRecord.slice(dataStart, dataEnd);

      this.mItems.push(new BeaconItem(type, len, bytes));
      offset += 1 + len;
    }
  }
}

// 定义AD Type常量
const AD_TYPE_FLAGS = 0x01; // 广播标志位(原connectAbledType)
const AD_TYPE_MANUFACTURER = 0xFF; // 厂商自定义数据(原advDataType)

// 广播数据结构
interface BroadcastData {
  connectAbled: boolean; // 是否可连接
  beacondata: Uint8Array; // 厂商数据
  dataLen: number; // 数据长度
}

