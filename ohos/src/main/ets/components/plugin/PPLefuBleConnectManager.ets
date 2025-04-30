import { PPLefuStreamHandler } from './PPLefuStreamHandler';
import bluetooth from '@ohos.bluetooth';
import { PPBluetoothKit } from 'ppsdkkit/src/main/ets/PPBluetoothKit';
import { PPBleSearch } from 'ppsdkkit/src/main/ets/ble/search/PPBleSearch';
import { PPBaseDeviceControl } from 'ppsdkkit/src/main/ets/device/PPBaseDeviceControl';
import { access } from '@kit.ConnectivityKit';
import { PPDeviceModel } from 'ppsdkkit/src/main/ets/vo/PPDeviceModel';

enum PPLefuScanType {
  SCAN = 0
}

export class PPLefuBleConnectManager {
  scanResultStreamHandler: PPLefuStreamHandler | null = null;
  loggerStreamHandler: PPLefuStreamHandler | null = null;
  connectStateStreamHandler: PPLefuStreamHandler | null = null;
  measureStreamHandler: PPLefuStreamHandler | null = null;
  historyStreamHandler: PPLefuStreamHandler | null = null;
  batteryStreamHandler: PPLefuStreamHandler | null = null;
  blePermissionStreamHandler: PPLefuStreamHandler | null = null;
  dfuStreamHandler: PPLefuStreamHandler | null = null;
  deviceLogStreamHandler: PPLefuStreamHandler | null = null;
  scanStateStreamHandler: PPLefuStreamHandler | null = null;
  private bluetoothState: bluetooth.BluetoothState | null = null;
  private needScan: boolean = false;
  private scanType: PPLefuScanType = PPLefuScanType.SCAN;
  private isScaning: boolean = false;
  private connectState: number = 0;
  deviceControl: PPBaseDeviceControl | null = null;
  currentDevice: PPDeviceModel | null = null;
  deviceModels: Array<PPDeviceModel> = [];

  constructor() {
    // 初始化蓝牙管理器
    this.initBluetooth();
  }

  private initBluetooth(): void {
    // 监听蓝牙状态变化
    PPBluetoothKit.addBleStateListener((state: number) => {
      this.onBluetoothStateChange(state);
    })
  }

  private onBluetoothStateChange(state: bluetooth.BluetoothState): void {
    if (this.bluetoothState !== state) {
      this.sendBlePermissionState(state);
    }

    this.bluetoothState = state;
    this.loggerStreamHandler?.success(`蓝牙状态:${state}`);

    if (this.needScan && access.BluetoothState.STATE_ON === state) {
      this.needScan = false;
      this.startScan();
    } else if (state === access.BluetoothState.STATE_OFF) {
      this.needScan = false;
      if (this.isScaning) {
        this.stopScan();
      }
    }
  }

  startScan(): void {
    this.stopScan();
    this.disconnect();
    this.isScaning = true;
    this.sendScanState(true);

    PPBleSearch.getInstance().startScan((deviceModel: PPDeviceModel) => {
      const existingIndex = this.deviceModels.findIndex(
        item => item.deviceMac === deviceModel.deviceMac
      );

      if (deviceModel) {
        //这里为了快速响应UI刷新暂时先采用双数组,BleDevice用于UI显示，后期开发优化会只有PPDeviceModel，
        // 在集成时可自行选择，SDK内部业务使用到的是PPDeviceModel
        if (existingIndex === -1) {
          this.deviceModels.push(deviceModel);
        } else {
          this.deviceModels[existingIndex] = deviceModel;
        }
        this.onDeviceFound(deviceModel);
      }
    });

  }

  private onDeviceFound(device: PPDeviceModel): void {
    if (this.scanType === PPLefuScanType.SCAN) {
      // 转换设备信息为统一格式
      this.scanResultStreamHandler?.success({
        deviceName: device.deviceName,
        deviceId: device.deviceMac,
        rssi: device.rssi
      });
    }
  }

  stopScan(): void {
    PPBleSearch.getInstance().stopScan();
    this.isScaning = false;
    this.sendScanState(false);
  }

  disconnect(): void {
    // 实现断开连接逻辑
    this.deviceControl?.disConnect();
    this.clearData();
  }

  private clearData(): void {
    // 清理设备相关数据
    this.currentDevice = null;
    this.deviceControl = null;
    this.sendConnectState(0);
  }

  private sendConnectState(state: number): void {
    this.loggerStreamHandler?.success(`连接状态:${state}`);
    this.connectState = state;

    this.connectStateStreamHandler?.success({
      deviceMac: this.currentDevice?.deviceMac || '',
      state: state
    });
  }

  private sendScanState(scaning: boolean): void {
    this.scanStateStreamHandler?.success(scaning);
  }

  private sendBlePermissionState(state: bluetooth.BluetoothState): void {
    this.blePermissionStreamHandler?.success(state);
  }
}