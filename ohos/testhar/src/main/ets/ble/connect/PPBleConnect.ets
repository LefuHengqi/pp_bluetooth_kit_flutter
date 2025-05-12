import { ble, constant } from '@kit.ConnectivityKit';
import { BusinessError, Callback } from '@kit.BasicServicesKit';
import { PPLogger } from '../../log/PPLogger';

/**
 * 连接 -> 连接中 -> 断开
 * 1、根据deviceID初始化gattClient实例，失败会有提示，业务可以做微调
 * 2、当前不同连接状态显示不同文字，连接/断开
 */

export class PPBleConnect {
  deviceId: string = '';
  gattClient: ble.GattClientDevice | null = null;
  connectState: ble.ProfileConnectionState = constant.ProfileConnectionState.STATE_DISCONNECTED;
  connectionStateCallback?: Callback<ble.ProfileConnectionState>;
  discoverServiceResultCallback?: Callback<ble.GattService[]>;

  constructor(deviceId:string) {
    this.deviceId = deviceId;
    this.initGattClient()
  }

  startConnect(connectStateChange?: (state: ble.ProfileConnectionState) => void,
    discoverServiceResultCallback?: (result: ble.GattService[]) => void) {
    this.connectionStateCallback = connectStateChange;
    this.discoverServiceResultCallback = discoverServiceResultCallback;

    if (this.gattClient && this.connectState !== constant.ProfileConnectionState.STATE_CONNECTED) {
      this.addLog('设备未连接,开始连接')
      this.gattClient.connect()
    }
  }

  /**
   * 初始化gattClient实例
   */
  initGattClient() {
    if (this.gattClient) {
      return;
    }

    try {
      this.gattClient = ble.createGattClientDevice(this.deviceId);
      this.onBLEConnectionStateChange()
    } catch (err) {
      this.addLog('连接失败，请重试！')
      this.addLog('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  addLog(message: string) {
    PPLogger.d(message)
  }


  /**
   * client端断开与远端蓝牙低功耗设备的连接
   */
  disConnect() {
    this.connectionStateCallback = undefined;
    this.discoverServiceResultCallback = undefined;
    if (!this.gattClient) {
      return;
    }
    if (this.gattClient && this.connectState !== constant.ProfileConnectionState.STATE_DISCONNECTED) {
      this.addLog('设备已连接,开始断开')
      this.gattClient.disconnect()
    }
    this.gattClient.off('BLEConnectionStateChange', (state: ble.BLEConnectionChangeState) => {
      PPLogger.i('PPBleConnect disConnect gattClient.off ' + state);
    })
    this.gattClient = null;
  }

  /**
   * client端订阅蓝牙低功耗设备的连接状态变化事件
   */
  onBLEConnectionStateChange() {
    if (!this.gattClient) {
      this.addLog('连接失败，请重试！')
      return;
    }

    this.gattClient.on('BLEConnectionStateChange', (state: ble.BLEConnectionChangeState) => {
      PPLogger.i('BluetoothPage bluetooth connectState ' + JSON.stringify(this.connectState));
      this.connectState = state.state;
      if (this.connectionStateCallback) {
        this.connectionStateCallback(this.connectState);
      }
      if (this.connectState === constant.ProfileConnectionState.STATE_CONNECTED) {
        this.addLog('连接成功')
        this.discoverServices()
      }
    })
  }

  async discoverServices() {
    if (!this.gattClient) {
      this.addLog('GATT客户端未初始化');
      return;
    }
    try {
      const services = await this.gattClient?.getServices()
      services.forEach(async service => {
        this.addLog(`服务UUID: ${service.serviceUuid}`);

        // 获取服务下的所有特征
        const characteristics: ble.BLECharacteristic[] = service.characteristics;

        for (const characteristic of characteristics) {
          this.addLog(`服务UUID: ${characteristic.characteristicUuid}`);
          this.addLog(`属性: 可读[${characteristic.properties?.read}] 可写[${characteristic.properties?.write}] 可通知[${characteristic.properties?.notify}]`);
        }
      });
      if (this.discoverServiceResultCallback) {
        this.discoverServiceResultCallback(services);
      }
    } catch (err) {
      this.addLog(`获取服务失败:${err.code} ${err.message}`);
    }

  }

  isConnect(): boolean {
    let connect = (this.gattClient && (this.connectState === constant.ProfileConnectionState.STATE_CONNECTED
      || this.connectState === constant.ProfileConnectionState.STATE_CONNECTING)) ?? false
    PPLogger.i('PPBleConnect isConnect connectState: ' + connect)
    return connect;
  }

  getGattClient(): ble.GattClientDevice | null {
    return this.gattClient;
  }
}


