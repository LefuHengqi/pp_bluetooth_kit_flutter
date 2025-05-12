import { ByteUtil } from "../../utils/ByteUtil";
import { DateUtil } from "../../utils/DateUtil";
import { ble } from "@kit.ConnectivityKit";
import { PPLogger } from "../../log/PPLogger";
import { TimeFormat } from "../../enums/PPDeviceEnums";
import { UnitUtil } from "../../utils/UnitUtil";
import { PPUnitType } from "../../enums/PPUnitType";


export class PPTorreDeviceControlExtF1 {
  characteristicFFF1: ble.BLECharacteristic | null = null;
  gattClient?: ble.GattClientDevice | null

  // 时间同步（全部改为字节操作）
  async syncTime(timeMillis: number, timeType: TimeFormat = TimeFormat.HOUR_24): Promise<boolean> {
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
      timeType === TimeFormat.HOUR_24 ? 0x01 : 0x00// 时间格式
    ]);

    return this.writeResponseBytesF1(command);
  }

  async getMtuLen(): Promise<boolean> {
    return this.writeResponseBytesF1(new Uint8Array([0x02, 0x00]));
  }

  async startMeasure(): Promise<boolean> {
    return this.writeResponseBytesF1(new Uint8Array([0x24, 0x00]));
  }

  async stopMeasure(): Promise<boolean> {
    return this.writeResponseBytesF1(new Uint8Array([0x28, 0x00]));
  }

  // 切换婴儿模式（全部改为字节操作）
  async switchBaby(mode: number, step: number, weight: number): Promise<boolean> {
    const modeByte = mode === 0 ? 0x00 : 0x01;
    const stepByte = step === 0 ? 0x00 : 0x01;
    const weightBytes = step === 0 ? [0x00, 0x00] :
    ByteUtil.hexToBytes(ByteUtil.weightKgToHex(weight));

    const commandArray: number[] = [
      0x2E, 0x05, 0x01, // 命令头
      modeByte,
      stepByte,
      ...Array.from(weightBytes) // 先转标准数组再展开
    ];
    const command = new Uint8Array(commandArray); // 最终转Uint8Array
    PPLogger.i(`PPTorreDeviceControl switchBaby command: ${Array.from(command)}`);

    return this.writeResponseBytesF1(command);
  }

  async switchMode(type: number, state: number): Promise<boolean> {
    const typeByte = type === 0 ? 0x01 : 0x02;
    const modeByte = state === 0 ? 0x00 : 0x01;

    const command = new Uint8Array([
      0x01, 0x02, // 命令头
      typeByte,
      modeByte
    ]);

    return this.writeResponseBytesF1(command);
  }

  async controlImpedance(state: number): Promise<boolean> {
    const command = new Uint8Array([
      0x07, 0x02, 0x01, // 命令头
      state === 0 ? 0x00 : 0x01
    ]);
    return this.writeResponseBytesF1(command);
  }

  // 0x00：关闭基础模式 0x01：打开基础模式
  async controlImpedance2(state: number): Promise<boolean> {
    console.log(`controlImpedance2 state: ${state}`);
    const dataToSend = state === 0 ? new Uint8Array([0x2C, 0x02, 0x01, 0x00]) :
      new Uint8Array([0x2C, 0x02, 0x01, 0x01]);
    return this.writeResponseBytesF1(dataToSend);
  }

  // 心率0打开 1关闭
  async controlHeartRate(state: number): Promise<boolean> {
    console.log(`controlHeartRate state: ${state}`);
    const dataToSend = state === 0 ? new Uint8Array([0x06, 0x02, 0x01, 0x00]) :
      new Uint8Array([0x06, 0x02, 0x01, 0x01]);
    return this.writeResponseBytesF1(dataToSend);
  }

  // 获取阻抗开关状态
  async getImpedanceState(): Promise<boolean> {
    return this.writeResponseBytesF1(new Uint8Array([0x07, 0x02, 0x02, 0x00]));
  }

  // 获取心率状态
  async getHeartRateState(): Promise<boolean> {
    return this.writeResponseBytesF1(new Uint8Array([0x06, 0x02, 0x02, 0x00]));
  }

  // 获取设备配网状态[App->设备]
  async getWifiState(): Promise<boolean> {
    return this.writeResponseBytesF1(new Uint8Array([0x0E, 0x01, 0x00]));
  }

  // wifi mac
  async getWifiMac(): Promise<boolean> {
    return this.writeResponseBytesF1(new Uint8Array([0x27, 0x00]));
  }

  async keepAlive(): Promise<boolean> {
    return this.writeResponseBytesF1(new Uint8Array([0x10, 0x00]));
  }

  async getLight(): Promise<boolean> {
    return this.writeResponseBytesF1(new Uint8Array([0x03, 0x02, 0x02, 0x00]));
  }

  async setLight(light: number): Promise<boolean> {
    const hex = ByteUtil.decimalToByte(light);
    return this.writeResponseBytesF1(new Uint8Array([0x03, 0x02, 0x01, hex]));
  }

  async getLanguage(): Promise<boolean> {
    return this.writeResponseBytesF1(new Uint8Array([0x42, 0x02, 0x02, 0x00]));
  }

  async getLanguageList(): Promise<boolean> {
    return this.writeResponseBytesF1(new Uint8Array([0x42, 0x02, 0x03, 0x00]));
  }

  async setLanguage(language: number): Promise<boolean> {
    const hex = ByteUtil.decimalToByte(language);
    return this.writeResponseBytesF1(new Uint8Array([0x42, 0x02, 0x01, hex]));
  }

  async getUnit(): Promise<boolean> {
    return this.writeResponseBytesF1(new Uint8Array([0x05, 0x02, 0x02, 0x00]));
  }

  async syncUnit(unitType: PPUnitType): Promise<boolean> {
    const hex = ByteUtil.decimalToByte(UnitUtil.unitTorre2Int(unitType));
    return this.writeResponseBytesF1(new Uint8Array([0x05, 0x02, 0x01, hex]));
  }

  async resetDevice(): Promise<boolean> {
    return this.writeResponseBytesF1(new Uint8Array([0x09, 0x00]));
  }

  /**
   * 设备绑定状态
   * @param type 1设置 2获取
   * @param state 0设备未绑定 1已绑定
   */
  async deviceBindStatus(type: number, state: number): Promise<boolean> {
    if (type === 1) {
      return this.writeResponseBytesF1(new Uint8Array([0x1C, 0x02, 0x01, state === 0 ? 0x00 : 0x01]));
    } else {
      return this.writeResponseBytesF1(new Uint8Array([0x1C, 0x02, 0x02, 0x00]));
    }
  }

  /**
   * 模拟模式开关
   * @param type 1设置 2获取
   * @param state 0关闭 1开启
   */
  async demoModeSwitch(type: number, state: number): Promise<boolean> {
    if (type === 1) {
      return this.writeResponseBytesF1(new Uint8Array([0x31, 0x02, 0x01, state === 0 ? 0x00 : 0x01]));
    } else {
      return this.writeResponseBytesF1(new Uint8Array([0x31, 0x02, 0x02, 0x00]));
    }
  }

  async clearDeviceUserInfo(): Promise<boolean> {
    return this.writeResponseBytesF1(new Uint8Array([0x16, 0x01, 0x01]));
  }

  async clearHistoryData(): Promise<boolean> {
    return this.writeResponseBytesF1(new Uint8Array([0x16, 0x01, 0x02]));
  }

  async clearAllDeviceInfo(): Promise<boolean> {
    return this.writeResponseBytesF1(new Uint8Array([0x16, 0x01, 0x00]));
  }

  async clearConfigWifiInfo(): Promise<boolean> {
    return this.writeResponseBytesF1(new Uint8Array([0x16, 0x01, 0x03]));
  }

  async clearSettingInfo(): Promise<boolean> {
    return this.writeResponseBytesF1(new Uint8Array([0x16, 0x01, 0x04]));
  }

  // 启动本地升级
  async startLocalOTA(): Promise<boolean> {
    return this.writeResponseBytesF1(new Uint8Array([0x0B, 0x00]));
  }

  // 调测用户升级
  async startTestOTA(): Promise<boolean> {
    return this.writeResponseBytesF1(new Uint8Array([0x0F, 0x01, 0x01]));
  }

  // 正常用户升级
  async startUserOTA(): Promise<boolean> {
    return this.writeResponseBytesF1(new Uint8Array([0x0F, 0x01, 0x00]));
  }

  // RGB设置（改为字节操作）
  async setRGB(
    defaultColor: string,
    againColor: string,
    lossColor: string,
    lightEnable: number,
    lightMode: number
  ): Promise<boolean> {
    const enableValue = lightEnable == 1 ? "01" : "00";
    const lightModeValue = lightMode == 1 ? "01" : "00";

    const defaultColorArray = ByteUtil.hexToRgb(defaultColor);
    const againColorArray = ByteUtil.hexToRgb(againColor);
    const lossColorArray = ByteUtil.hexToRgb(lossColor);

    // 转换默认颜色
    const defaultColorValue = defaultColorArray ?
    defaultColorArray.map(e => e.toString(16).padStart(2, '0')).join('').toUpperCase() :
      "FFFFFF";

    // 转换再次颜色
    const againColorValue = againColorArray ?
    againColorArray.map(e => e.toString(16).padStart(2, '0')).join('').toUpperCase() :
      "FFFFFF";

    // 转换丢失颜色
    const lossColorValue = lossColorArray ?
    lossColorArray.map(e => e.toString(16).padStart(2, '0')).join('').toUpperCase() :
      "FFFFFF";

    const rgbValue = `390B${enableValue}${lightModeValue}${defaultColorValue}${againColorValue}${lossColorValue}`;

    const command = new Uint8Array(ByteUtil.hexToBytes(rgbValue));

    PPLogger.i(`PPTorreDeviceControl setRGB command: ${Array.from(command)}`);
    return this.writeResponseBytesF1(command);
  }

  // 私有写入方法（统一改为字节操作）
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
      await this.gattClient?.writeCharacteristicValue(this.characteristicFFF1, ble.GattWriteType.WRITE)
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


}
