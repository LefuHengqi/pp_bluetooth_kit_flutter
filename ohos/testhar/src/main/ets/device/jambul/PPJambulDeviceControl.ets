import { ble } from '@kit.ConnectivityKit';
import { PPBaseDeviceControl } from '../PPBaseDeviceControl';
import { PPLogger } from '../../log/PPLogger';
import { BleUUID } from '../BleUUID';
import HexUtil from '../../utils/HexUtil';
import { ByteUtil } from '../../utils/ByteUtil';
import { UnitUtil } from '../../utils/UnitUtil';
import { PPUserModel } from '../../vo/PPUserModel';
import { PPUnitType } from '../../enums/PPUnitType';
import { PPDeviceType, PPUserGender } from '../../enums/PPDeviceEnums';
import { PPScaleHelper } from '../../utils/PPScaleHelper';
import { PPDeviceModel } from '../../vo/PPDeviceModel';
import { PPDataChangeListener } from '../../listener/PPDataChangeListener';
import { PPJambulDeviceDataAnalysis } from './PPJambulDeviceDataAnalysis';
import { BusinessError } from '@kit.BasicServicesKit';
import { PPSendHelper } from '../../utils/PPSendHelper';


export class PPJambulDeviceControl extends PPBaseDeviceControl {
  characteristicFFF1: ble.BLECharacteristic | null = null;
  dataChangeNotify?: (data: string) => void
  deviceInfoCharacteristics: ble.BLECharacteristic[] = [];
  characteristicBattery: ble.BLECharacteristic | null = null;
  dataAnalysis = new PPJambulDeviceDataAnalysis();

  override OnCharacteristicReceived(characteristic: ble.BLECharacteristic) {
    let dataArray = new Uint8Array(characteristic.characteristicValue);
    let data: string = HexUtil.formatHexString(dataArray);
    if (this.dataChangeNotify) {
      this.dataChangeNotify(data);
    }
    if (characteristic.characteristicUuid === BleUUID.CHARACTERISTIC_NOTIFY) {
      PPLogger.i(`PPJambulDeviceControl OnCharacteristicReceived apple notify:${data}`);
      this.dataAnalysis.analysisData(dataArray, this.deviceModel ?? null);
    }
  }

  override onSearchResponse(advData: Uint8Array): void {

    if (advData.length >= (this.deviceModel?.advLength ?? 11)) {
      const startPosition = (this.deviceModel?.macAddressStart ?? 0) + 1;
      if (startPosition + 11 <= advData.length) {
        const data = advData.subarray(startPosition, startPosition + 11);
        PPLogger.d(`PPJambulDeviceControl.startSearch.onAdvDataReceived.xor: ${HexUtil.formatHexString(data)}}`);
        if (ByteUtil.isXorValue(data)) {
          this.dataAnalysis?.analysisData(data, this.deviceModel ?? null);
        } else {
          PPLogger.e(`PPJambulDeviceControl onSearchResponse Xor is error data:${HexUtil.formatHexString(advData)} startPosition:${startPosition}`);
        }
      } else {
        PPLogger.e(`PPJambulDeviceControl onSearchResponse len error data:${HexUtil.formatHexString(advData)} advLength:${this.deviceModel?.advLength}`);
      }

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

    // return await this.writeResponseBytesF1(finalArray);
    return false;
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

  registerDataChangeListener(listener: PPDataChangeListener) {
    this.dataAnalysis.dataChangeListener = listener;
  }


  /**
   * @param userUnit
   * @param address
   * @param mode     0-表示为有效的用户组信息，退出安全模式   1-表示秤进入安全模式，不会测量阻抗。
   */
  sendSwitchUnitDataByAdvert(unitType: PPUnitType, address: string, mode: number) {
    const name = "Phone";
    const sendData = PPSendHelper.sendAdvertisingData(unitType, address, mode);

    let serviceValueBuffer = new Uint8Array(0);

    try {
      let setting: ble.AdvertiseSetting = {
        interval: 150,
        txPower: 0,
        connectable: true
      };
      let manufactureDataUnit: ble.ManufactureData = {
        manufactureId: 0x004C,
        manufactureValue: sendData.buffer
      };
      let serviceDataUnit: ble.ServiceData = {
        serviceUuid: "00001888-0000-1000-8000-00805f9b34fb",
        serviceValue:serviceValueBuffer.buffer
      };
      let advData: ble.AdvertiseData = {
        serviceUuids: ["00001888-0000-1000-8000-00805f9b34fb"],
        manufactureData: [manufactureDataUnit],
        serviceData: [serviceDataUnit]
      };
      let advResponse: ble.AdvertiseData = {
        serviceUuids: ["00001888-0000-1000-8000-00805f9b34fb"],
        manufactureData: [manufactureDataUnit],
        serviceData: [serviceDataUnit]
      };
      let advertisingParams: ble.AdvertisingParams = {
        advertisingSettings: setting,
        advertisingData: advData,
        advertisingResponse: advResponse,
        duration: 300
      }
      let advHandle = 0xFF;
      ble.startAdvertising(advertisingParams, (err, outAdvHandle) => {
        if (err) {
          return;
        } else {
          advHandle = outAdvHandle;
          console.info("advHandle: " + advHandle);
        }
      });

      let advertisingEnableParams: ble.AdvertisingEnableParams = {
        advertisingId: advHandle,
        duration: 0
      }

      PPLogger.i(`广播发送开始 sendData：${ByteUtil.uint8ArrayToHex(sendData)}`)
      // after 3s, advertising disabled, then enable the advertising
      ble.enableAdvertising(advertisingEnableParams)
        .then(() => {
          PPLogger.i('广播发送完成')
        });
    } catch (err) {
      PPLogger.e('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }

  }
}
