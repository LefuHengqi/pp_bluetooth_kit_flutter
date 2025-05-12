import util from '@ohos.util';
import { PPUnitType } from '../enums/PPUnitType';
import { PPLogger } from '../log/PPLogger';
import { ByteUtil } from './ByteUtil';
import { UnitUtil } from './UnitUtil';

export class PPSendHelper {
  static number: number = 0; // 假设有全局变量管理序号，此处简化

  // 将SSID和密码编码为字节数组列表
  static codeBySSIDAndPassword(ssid: string, password: string): Uint8Array[] {
    const ssidHex = ByteUtil.stringToHexString(ssid);
    const ssidArray: Uint8Array[] = [];

    if (ssidHex.length > 0) {
      const head = "0A";
      const len = ssidHex.length;
      const total = Math.floor(len / 30) + (len % 30 > 0 ? 1 : 0);
      let num = 0;

      for (let i = 0; i < total; i++) {
        const start = i * 30;
        const end = Math.min((i + 1) * 30, len);
        const dataBody = head +
        ByteUtil.decimalToHex(total) +
        ByteUtil.decimalToHex(num) +
        ByteUtil.decimalToHex(Math.floor(len / 2)) +
        ssidHex.substring(start, end);

        const xorValue = ByteUtil.getXorValue(ByteUtil.hexToBytes(dataBody));
        const xorHex = xorValue.toString(16).toUpperCase().padStart(2, '0');
        const data = dataBody + xorHex;
        num++;
        ssidArray.push(ByteUtil.hexToBytes(data));
      }
    }

    const passwordArray = PPSendHelper.getPassHex(password);
    const result = [...ssidArray, ...passwordArray];

    // 添加结束标志
    result.push(ByteUtil.hexToBytes("0E"));
    return result;
  }

  // 密码编码处理
  private static getPassHex(password: string): Uint8Array[] {
    const passwordHex = ByteUtil.stringToHexString(password);
    const arrayHex: Uint8Array[] = [];

    if (passwordHex.length > 0) {
      const head = "0B";
      const len = passwordHex.length;
      const total = Math.floor(len / 30) + (len % 30 > 0 ? 1 : 0);
      let num = 0;

      for (let i = 0; i < total; i++) {
        const start = i * 30;
        const end = Math.min((i + 1) * 30, len);
        const dataBody = head +
        ByteUtil.decimalToHex(total) +
        ByteUtil.decimalToHex(num) +
        ByteUtil.decimalToHex(Math.floor(len / 2)) +
        passwordHex.substring(start, end);

        const xorValue = ByteUtil.getXorValue(ByteUtil.hexToBytes(dataBody));
        const xorHex = xorValue.toString(16).toUpperCase().padStart(2, '0');
        const data = dataBody + xorHex;
        num++;
        arrayHex.push(ByteUtil.hexToBytes(data));
      }
    }
    return arrayHex;
  }

  /**
   * @param userUnit - 用户单位类型
   * @param address - 蓝牙地址（格式如 "XX:XX:XX:XX:XX:XX"）
   * @param mode - 0: 正常模式, 1: 安全模式（不测量阻抗）
   * @returns 生成的广播数据（Uint8Array）
   */
  static sendAdvertisingData(userUnit: PPUnitType, address: string, mode: number): Uint8Array {
    let dataStr: string = '';
    const split: string[] = address.split(':');

    // 拼接地址部分（去掉冒号，取后4段）
    dataStr += split[2] + split[3] + split[4] + split[5];

    // 处理模式（16进制）
    const modeHex: string = (mode === 1) ? '38' : '37';
    dataStr += modeHex;

    // 处理单位（转16进制）
    const unit: number = UnitUtil.getUnitInt(userUnit, '');
    dataStr += ByteUtil.decimalToHex(unit);

    // 序号（自增，0-255循环）
    PPSendHelper.number++;
    if (PPSendHelper.number >= 256) {
      PPSendHelper.number = 0;
    }
    dataStr += ByteUtil.decimalToHex(PPSendHelper.number);

    // 字符串转Uint8Array（确保长度为偶数）
    const byteData: Uint8Array = ByteUtil.hexStringToUint8Array(dataStr);

    // 计算异或校验值
    const xorValue: number = ByteUtil.getXorValue(byteData);
    const xorStr: string = ByteUtil.decimalToHex(xorValue).padStart(2, '0');
    dataStr += xorStr;

    // 补零到固定长度（假设总长度为24字节）
    const finalDataStr: string = dataStr + '000000000000';
    PPLogger.i(`Bluetooth sendAdvertisingData: ${finalDataStr}`);

    // 最终转换为Uint8Array
    return ByteUtil.hexStringToUint8Array(finalDataStr);
  }



}