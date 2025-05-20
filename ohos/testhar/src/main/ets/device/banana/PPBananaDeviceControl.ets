import { ble } from '@kit.ConnectivityKit';
import { PPBaseDeviceControl } from '../PPBaseDeviceControl';
import { PPLogger } from '../../log/PPLogger';
import { BleUUID } from '../BleUUID';
import HexUtil from '../../utils/HexUtil';
import { ByteUtil } from '../../utils/ByteUtil';
import { PPDataChangeListener } from '../../listener/PPDataChangeListener';
import { PPBananaDeviceDataAnalysis } from './PPBananaDeviceDataAnalysis';
import { PPUnitType } from '../../enums/PPUnitType';
import { PPSendHelper } from '../../utils/PPSendHelper';
import { BusinessError } from '@kit.BasicServicesKit';


export class PPBananaDeviceControl extends PPBaseDeviceControl {
  characteristicFFF1: ble.BLECharacteristic | null = null;
  dataChangeNotify?: (data: string) => void
  deviceInfoCharacteristics: ble.BLECharacteristic[] = [];
  characteristicBattery: ble.BLECharacteristic | null = null;
  dataAnalysis = new PPBananaDeviceDataAnalysis();

  override OnCharacteristicReceived(characteristic: ble.BLECharacteristic) {
    let dataArray = new Uint8Array(characteristic.characteristicValue);
    let data: string = HexUtil.formatHexString(dataArray);
    if (this.dataChangeNotify) {
      this.dataChangeNotify(data);
    }
    if (characteristic.characteristicUuid === BleUUID.CHARACTERISTIC_NOTIFY) {
      PPLogger.i(`PPBananaDeviceControl OnCharacteristicReceived apple notify:${data}`);
      this.dataAnalysis.analysisData(dataArray, this.deviceModel ?? null);
    }
  }

  override onSearchResponse(advData: Uint8Array): void {

    if (advData.length >= 19) { //老的体脂秤
      const data = advData.subarray(8);
      if (ByteUtil.isXorValue(data)) {
        PPLogger.d("PPBananaDeviceControl.startSearch.onAdvDataReceived.xor: " + HexUtil.formatHexString(data));
        this.dataAnalysis?.analysisData(data, this.deviceModel ?? null);
      }
    } else if (advData.length >= 17) {
      const data = advData.subarray(6);
      if (ByteUtil.isXorValue(data)) {
        PPLogger.d("PPBananaDeviceControl.startSearch.onAdvDataReceived.xor: " + HexUtil.formatHexString(data));
        this.dataAnalysis?.analysisData(data, this.deviceModel ?? null);
      }
    }

  }

  registerDataChangeListener(listener: PPDataChangeListener) {
    this.dataAnalysis.dataChangeListener = listener;
  }


}
