import { PPBleConnect } from "../ble/connect/PPBleConnect";
import { ble, constant } from "@kit.ConnectivityKit";
import { PPLogger } from "../log/PPLogger";
import { PPDeviceModel } from "../vo/PPDeviceModel";
import { PPBleSearchByDevice } from "../ble/search/PPBleSearchByDevice";
import HexUtil from "../utils/HexUtil";
import { TorreHelper } from "./torre/TorreHelper";

export class PPBaseDeviceControl {
  deviceId: string = ''
  deviceModel: PPDeviceModel | null = null;
  bleConnect?: PPBleConnect;
  mtu: number = 20;

  randomNum = TorreHelper.generateRandomFourDigitNumber();

  discoverServiceResultCallback?: (isSuccess: boolean) => void;
  private characteristicCallback?: (characteristic: ble.BLECharacteristic) => void;

  constructor(deviceModel: PPDeviceModel) {
    this.deviceId = deviceModel.deviceRemoteId ?? deviceModel.deviceMac ?? "";
    this.deviceModel = deviceModel;
    this.bleConnect = new PPBleConnect(this.deviceId);
  }

  startConnect(connectStateChange: (state: ble.ProfileConnectionState) => void,
    discoverServiceResultCallback?: (isSuccess: boolean) => void) {

    PPLogger.e(`PPBaseDeviceControl.startConnect randomNum:${this.randomNum}`)
    this.discoverServiceResultCallback = discoverServiceResultCallback

    this.bleConnect?.startConnect((state: ble.ProfileConnectionState) => {
      if (state === constant.ProfileConnectionState.STATE_DISCONNECTED) {
        this.addLog('设备断开');
        this.unRegisterCharacteristicChanged();
      }
      connectStateChange(state);
    }, (result: ble.GattService[]) => {
      this.registerCharacteristicChanged();
      this.onDiscoverServices(result);
    })

  }

  startSearch() {
    PPBleSearchByDevice.getInstance().deviceModel = this.deviceModel;
    PPBleSearchByDevice.getInstance().startScan((advData) => {
      if (advData) {
        PPLogger.d("PPBaseDeviceControl.startSearch.onAdvDataReceived: " + HexUtil.formatHexString(advData))
        this.onSearchResponse(advData)
      }
    });
  }

  disConnect() {
    this.unRegisterCharacteristicChanged();
    this.bleConnect?.disConnect();
  }

  stopSearch() {
    PPBleSearchByDevice.getInstance().stopScan();
  }

  addLog(message: string) {
    PPLogger.d(message)
  }

  getGattClient(): ble.GattClientDevice | null {
    if (this.bleConnect) {
      return this.bleConnect.getGattClient();
    }
    return null;
  }

  registerCharacteristicChanged() {
    this.unRegisterCharacteristicChanged();
    this.characteristicCallback = (characteristic: ble.BLECharacteristic) => {
      this.OnCharacteristicReceived(characteristic);
    };
    PPLogger.e('PPBaseDeviceControl.registerCharacteristicChanged')
    this.getGattClient()?.on('BLECharacteristicChange', this.characteristicCallback)
  }

  unRegisterCharacteristicChanged() {
    PPLogger.e(`PPBaseDeviceControl.unRegisterCharacteristicChanged randomNum:${this.randomNum}`)
    if (this.characteristicCallback) {
      this.getGattClient()?.off('BLECharacteristicChange', this.characteristicCallback)
      this.characteristicCallback = undefined;
      PPLogger.e('PPBaseDeviceControl.unRegisterCharacteristicChanged success')
    }
  }

  isConnect(): boolean {
    return this.bleConnect?.isConnect() ?? false;
  }

  isSearch(): boolean {
    return PPBleSearchByDevice.getInstance().scanSwitch;
  }

  /**
   * 需要子类自己实现,每个设备不同
   */
  onDiscoverServices(services: ble.GattService[]) {
  }

  /**
   * 监听特征值变化
   * @param characteristic
   */
  OnCharacteristicReceived(characteristic: ble.BLECharacteristic) {
  }

  /**
   * 子类自己实现，每个设备的处理不同。
   * @param data
   */
  onSearchResponse(advData: Uint8Array) {
  }
}