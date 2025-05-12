import { access, ble } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { PPLogger } from '../../log/PPLogger';
import { PPDeviceModel } from '../../vo/PPDeviceModel';
import { PPDeviceFilterHelper } from './PPDeviceFilterHelper';
import HexUtil from '../../utils/HexUtil';

export class PPBleSearchByDevice {
  bleSwitch: boolean = false;
  scanSwitch: boolean = false;
  deviceModel: PPDeviceModel | null = null;
  private static _instance: PPBleSearchByDevice | null = null;
  scanResultCallback?: (advData: Uint8Array) => void;

  public static getInstance(): PPBleSearchByDevice {
    if (!PPBleSearchByDevice._instance) {
      PPLogger.d("PPBleSearchByDevice getInstance: Creating new instance");
      PPBleSearchByDevice._instance = new PPBleSearchByDevice();
    } else {
      PPLogger.d("PPBleSearchByDevice getInstance: Returning existing instance");
    }
    return PPBleSearchByDevice._instance;
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
  startScan(callback: (advData: Uint8Array) => void) {
    this.scanResultCallback = callback;
    if (!this.deviceModel) {
      PPLogger.e("Please set PPDeviceModel, the deviceModel is not null")
      return;
    }
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

      const filter: ble.ScanFilter = {
        name: `${this.deviceModel.deviceName}`
      };

      ble.startBLEScan([filter], scanOption);

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
    PPLogger.i('PPBleSearchByDevice scanCallback bluetooth device find on = ' + JSON.stringify(data));

    for (const item of data) {

      let uint8_msg = new Uint8Array(item.data);

      // let gattClient = ble.createGattClientDevice(item.deviceId);
      let deviceName: string = item.deviceName;
      if (deviceName === undefined || deviceName === null || deviceName === "") {
        return;
      }

      PPLogger.i('PPBleSearchByDevice scanCallback deviceName = ' + deviceName );

      // 3. 解析所有AD Structure
      const advDataArray = PPDeviceFilterHelper.parseManufacturerData(uint8_msg);
      PPLogger.i('PPBleSearchByDevice scanCallback data = ' + HexUtil.formatHexString(advDataArray) );

      if (!advDataArray) {
        return
      }
      if (this.scanResultCallback) {
        if (advDataArray.length <= 0) {
          return
        }
        if (this.deviceModel) {
          const start = this.deviceModel.macAddressStart ?? 0;
          if (start > 0) {
            let deviceAddress = PPDeviceFilterHelper.getMac(advDataArray, start);
            if (deviceAddress && deviceAddress === this.deviceModel.deviceMac) {
              this.scanResultCallback(advDataArray);
            }
          } else {
            PPLogger.e("Please config deviceModel, the macAddressStart is not null")
            return;
          }
        } else {
          PPLogger.e("Please config deviceModel, And the macAddressStart is not null")
        }
      }
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

