import { PPBleFFF2ErrorCode } from "../../../enums/PPBleFFF2ErrorCode";
import { PPLogger } from "../../../log/PPLogger";
import { ByteUtil } from "../../../utils/ByteUtil";
import HexUtil from "../../../utils/HexUtil";
import { PPDeviceModel } from "../../../vo/PPDeviceModel";
import { PPWifiModel } from "../../../vo/PPWifiModel";
import { wifi } from "@kit.ConnectivityKit";
import { PPConfigWifiStateMenu } from "../../../enums/PPConfigWifiStateMenu";


export class PPTorreWifiSyncCmd {
  static deviceModel?: PPDeviceModel | null = null;
  static wifiListEndCallBack?: (error: PPBleFFF2ErrorCode) => void;
  static monitorWiFiListCallBack?: (wifiModels: PPWifiModel[] | null) => void;
  static configWifiConfirmStartCallBack?: (error: PPBleFFF2ErrorCode) => void;
  static configWifiConfirmSendDataCallBack?: (error: PPBleFFF2ErrorCode) => void;
  static configWifiSSIDResultCallBack?: (error: PPBleFFF2ErrorCode) => void;
  static configWifiPwdResultCallBack?: (error: PPBleFFF2ErrorCode) => void;
  static configWifiDomainResultCallBack?: (error: PPBleFFF2ErrorCode) => void;
  static configWifiRegisterResultCallBack?: (error: PPBleFFF2ErrorCode) => void;
  static confirmGetWifiInfoEndCallBack?: (error: PPBleFFF2ErrorCode) => void;
  static readDeviceWifiSSIDEndCallBack?: (error: PPBleFFF2ErrorCode) => void;
  static confirmWifiSSIDEndCallBack?: (error: PPBleFFF2ErrorCode) => void;
  static readDeviceSsidCallBack?: (ssid: string) => void;
  static configWifiResultCallBack?: (menu: PPConfigWifiStateMenu, resultCode: string) => void;
  static domainHex: Uint8Array | null = null;
  static ssidHex: Uint8Array | null = null;
  static pwdHex: Uint8Array | null = null;

  static getWifiSSIDCmd(): Uint8Array {
    return new Uint8Array([0x03, 0x03, 0x06, 0x00, 0x01]);
  }

  static confirmWifiSSIDEndCmd(): Uint8Array {
    return new Uint8Array([0x03, 0x03, 0x06, 0x01, 0x00]);
  }

  static getWifiListCmd(): Uint8Array {
    return new Uint8Array([0x04, 0x01, 0x01]);
  }

  static confirmWifiListEndCmd(): Uint8Array {
    return new Uint8Array([0x04, 0x01, 0x02]);
  }

  static startConfigCmd(): Uint8Array {
    return new Uint8Array([0x03, 0x01, 0x01]);
  }

  static domainNameStartCmd(domainName: string): Uint8Array {

    PPTorreWifiSyncCmd.domainHex = ByteUtil.concatArrays([ByteUtil.stringToUint8Array(domainName), new Uint8Array([0x00])]);

    // 命令头 0xF1
    const commandHeader = new Uint8Array([0x03, 0x04, 0x02, 0x02]);

    const lenHex = ByteUtil.swapEndian(ByteUtil.numberToUint8Array(PPTorreWifiSyncCmd.domainHex.length, 2));

    // 合并所有字节
    return ByteUtil.concatArrays([commandHeader, lenHex]);
  }

  static ssidStartCmd(ssid: string): Uint8Array {

    PPTorreWifiSyncCmd.ssidHex = ByteUtil.concatArrays([ByteUtil.stringToUint8Array(ssid), new Uint8Array([0x00])]);

    // 命令头 0xF1
    const commandHeader = new Uint8Array([0x03, 0x04, 0x02, 0x00]);

    const lenHex = ByteUtil.swapEndian(ByteUtil.numberToUint8Array(PPTorreWifiSyncCmd.ssidHex.length, 2));

    // 合并所有字节
    return ByteUtil.concatArrays([commandHeader, lenHex]);
  }

  static pwdStartCmd(pwd: string | null): Uint8Array {
    if (pwd === null) {
      PPTorreWifiSyncCmd.pwdHex = new Uint8Array([0x00]);
    } else {
      PPTorreWifiSyncCmd.pwdHex = ByteUtil.concatArrays([ByteUtil.stringToUint8Array(pwd), new Uint8Array([0x00])]);
    }

    // 命令头 0xF1
    const commandHeader = new Uint8Array([0x03, 0x04, 0x02, 0x01]);

    const lenHex = ByteUtil.swapEndian(ByteUtil.numberToUint8Array(PPTorreWifiSyncCmd.pwdHex.length, 2));

    // 合并所有字节
    return ByteUtil.concatArrays([commandHeader, lenHex]);
  }

  static domainNameCmd(mtu: number): Uint8Array[] {

    const domainHex = PPTorreWifiSyncCmd.domainHex;

    if (domainHex && domainHex.length > 0) {
      return ByteUtil.splitByMTUWithLeadingZero(domainHex, mtu)
    }
    return [];
  }

  static ssidCmd(mtu: number): Uint8Array[] {

    const ssidHex = PPTorreWifiSyncCmd.ssidHex;

    if (ssidHex && ssidHex.length > 0) {
      return ByteUtil.splitByMTUWithLeadingZero(ssidHex, mtu)
    }
    return [];
  }

  static pwdCmd(mtu: number): Uint8Array[] {

    const pwdHex = PPTorreWifiSyncCmd.pwdHex;

    if (pwdHex && pwdHex.length > 0) {
      return ByteUtil.splitByMTUWithLeadingZero(pwdHex, mtu)
    }
    return [];
  }

  static sendDataEndCmd(): Uint8Array {
    return new Uint8Array([0x03, 0x01, 0x03]);
  }

  static registerToServerCmd(): Uint8Array {
    return new Uint8Array([0x03, 0x01, 0x04]);
  }

  static exitConfigWifiCmd(): Uint8Array {
    return new Uint8Array([0x03, 0x01, 0x05]);
  }


  static processConfigWifi(receiveData: Uint8Array, cacheReceiveData: Uint8Array, deviceModel?: PPDeviceModel | null) {
    PPTorreWifiSyncCmd.deviceModel = deviceModel;
    const configWifiReceiveData = HexUtil.formatHexString(receiveData);
    switch (receiveData[2]) {
      case 0x01: { //开始配网
        if (receiveData[3] == 0x00) {
          PPLogger.d("targetF2 确认开始配网成功");
          PPTorreWifiSyncCmd.configWifiConfirmStartCallBack?.(PPBleFFF2ErrorCode.Ok);
        } else {
          PPLogger.e("targetF2 确认开始配网失败");
          PPTorreWifiSyncCmd.configWifiResultCallBack?.(PPConfigWifiStateMenu.CONFIG_STATE_ERROR_TYPE_START_FAIL, configWifiReceiveData);
        }
        break;
      }
      case 0x02: {
        if (receiveData[3] == 0x00) {
          PPLogger.d("targetF2 确认开始发送数据成功");
          PPTorreWifiSyncCmd.configWifiConfirmSendDataCallBack?.(PPBleFFF2ErrorCode.Ok);
        } else {
          PPLogger.e("targetF2 确认开始配网失败");
          PPTorreWifiSyncCmd.configWifiResultCallBack?.(PPConfigWifiStateMenu.CONFIG_STATE_ERROR_TYPE_DATA_SEND_FAIL, configWifiReceiveData);
        }
        break;
      }
      case 0x03: {
        if (receiveData.length < 5) {
          return;
        }
        if (receiveData[3] == 0x00) { //ssid
          if (receiveData[4] == 0x00) {
            PPLogger.d("targetF2 确认ssid下发结束成功");
            PPTorreWifiSyncCmd.configWifiSSIDResultCallBack?.(PPBleFFF2ErrorCode.Ok);
          } else {
            PPLogger.e("targetF2 确认ssid下发结束失败");
            PPTorreWifiSyncCmd.configWifiResultCallBack?.(PPConfigWifiStateMenu.CONFIG_STATE_ERROR_TYPE_DATA_SEND_SSID_FAIL, configWifiReceiveData);
          }
        } else if (receiveData[3] == 0x01) { //pwd
          if (receiveData[4] == 0x00) {
            PPLogger.d("targetF2 确认pwd下发结束成功");
            PPTorreWifiSyncCmd.configWifiPwdResultCallBack?.(PPBleFFF2ErrorCode.Ok);
          } else {
            PPLogger.e("targetF2 确认pwd下发结束失败");
            PPTorreWifiSyncCmd.configWifiResultCallBack?.(PPConfigWifiStateMenu.CONFIG_STATE_ERROR_TYPE_DATA_SEND_PWD_FAIL, configWifiReceiveData);
          }
        } else if (receiveData[3] == 0x02) { //domain
          if (receiveData[4] == 0x00) {
            PPLogger.d("targetF2 确认domain下发结束成功");
            PPTorreWifiSyncCmd.configWifiDomainResultCallBack?.(PPBleFFF2ErrorCode.Ok);
          } else {
            PPLogger.e("targetF2 确认domain下发结束失败");
            PPTorreWifiSyncCmd.configWifiResultCallBack?.(PPConfigWifiStateMenu.CONFIG_STATE_ERROR_TYPE_DATA_SEND_DOMAIN_FAIL, configWifiReceiveData);
          }
        }
        break;
      }
      case 0x04: { //设备向服务器注册
        const registerErrorCode = receiveData[4]
        if (receiveData[3] == 0x00) {
          PPLogger.d("targetF2 设备向服务器注册成功");
          PPTorreWifiSyncCmd.configWifiRegisterResultCallBack?.(PPBleFFF2ErrorCode.Ok)
          PPTorreWifiSyncCmd.configWifiResultCallBack?.(PPConfigWifiStateMenu.CONFIG_STATE_SUCCESS, configWifiReceiveData);
        } else if (receiveData[3] == 0x01) {
          PPLogger.e("targetF2 超时失败 errorCode = " + registerErrorCode);
          PPTorreWifiSyncCmd.configWifiResultCallBack?.(PPConfigWifiStateMenu.CONFIG_STATE_ERROR_TYPE_REGIST_TIMEOUT, configWifiReceiveData);
        } else if (receiveData[3] == 0x02) {
          PPLogger.e("targetF2 设备向服务器注册 路由器连接失败 errorCode = " + registerErrorCode);
          PPTorreWifiSyncCmd.configWifiResultCallBack?.(PPConfigWifiStateMenu.CONFIG_STATE_ERROR_TYPE_REGIST_FAIL, configWifiReceiveData);
        } else if (receiveData[3] == 0x03) {
          PPLogger.e("targetF2 设备向服务器注册 HTTP网络错误码 errorCode = " + registerErrorCode);
          PPTorreWifiSyncCmd.configWifiResultCallBack?.(PPConfigWifiStateMenu.CONFIG_STATE_ERROR_TYPE_REGIST_HTTP, configWifiReceiveData);
        } else if (receiveData[3] == 0x04) {
          PPLogger.e("targetF2 设备向服务器注册 HTTPS网络错误码 errorCode = " + registerErrorCode);
          PPTorreWifiSyncCmd.configWifiResultCallBack?.(PPConfigWifiStateMenu.CONFIG_STATE_ERROR_TYPE_REGIST_HTTPS, configWifiReceiveData);
        } else if (receiveData[3] == 0x05) {
          PPLogger.e("targetF2 设备向服务器注册 注册服务器返回失败 errorCode = " + registerErrorCode);
          PPTorreWifiSyncCmd.configWifiResultCallBack?.(PPConfigWifiStateMenu.CONFIG_STATE_ERROR_TYPE_REGIST_SERVER, configWifiReceiveData);
        } else if (receiveData[3] == 0x06) {
          PPLogger.e("targetF2 设备向服务器注册 注册失败[配网指令漏发] errorCode = " + registerErrorCode);
          PPTorreWifiSyncCmd.configWifiResultCallBack?.(PPConfigWifiStateMenu.CONFIG_STATE_ERROR_TYPE_REGIST_FAIL, configWifiReceiveData);
        }
        break;
      }
      case 0x05: {
        PPTorreWifiSyncCmd.configWifiResultCallBack?.(PPConfigWifiStateMenu.CONFIG_STATE_EXIT, configWifiReceiveData);
        break;
      }
      case 0x06: { //返回设备配网信息结束[设备->App]
        if (receiveData[4] == 0x01) {
          PPTorreWifiSyncCmd.confirmGetWifiInfoEndCallBack?.(PPBleFFF2ErrorCode.Ok);
          if (cacheReceiveData) {
            const ssidHex = cacheReceiveData.subarray(2, cacheReceiveData.length - 1);
            const ssid = ByteUtil.uint8ArrayToString(ssidHex);
            PPLogger.d(`PPWifiSyncCmd.currentSSID ssidHex: ${HexUtil.formatHexString(ssidHex)} ssid: ${ssid}`);
            PPTorreWifiSyncCmd.readDeviceSsidCallBack?.(ssid);
          }
        } else {
          PPLogger.e("targetF2 返回设备配网信息结束[设备->App] 接收数据为空");
          PPTorreWifiSyncCmd.readDeviceSsidCallBack?.("")
          PPTorreWifiSyncCmd.confirmGetWifiInfoEndCallBack?.(PPBleFFF2ErrorCode.Unknown);
        }
        break;
      }
    }

  }

  static processWifiList(receiveData: Uint8Array, cacheReceiveData: Uint8Array, deviceModel?: PPDeviceModel | null) {
    PPTorreWifiSyncCmd.deviceModel = deviceModel;

    if (receiveData[2] == 0x02) {
      PPTorreWifiSyncCmd.wifiListEndCallBack?.(PPBleFFF2ErrorCode.Ok);

      PPLogger.d(`PPWifiSyncCmd.processWifiList receiveData: ${HexUtil.formatHexString(receiveData)}`);

      const dataArray = PPTorreWifiSyncCmd.splitByNullByte(cacheReceiveData);

      const wifiModels: PPWifiModel[] = [];

      for (const data of dataArray) {
        PPLogger.d(`PPWifiSyncCmd.processWifiList ssidHex: ${HexUtil.formatHexString(data)}`);
        try {
          // 1. 解析sign（前2个字节）
          const sign = data[0];

          // 2. 截取SSID部分（从18字节开始）
          const ssidBytes = data.subarray(18);

          // 3. 字节转字符串
          const ssid = ByteUtil.uint8ArrayToString(ssidBytes);

          // 4. 构建模型
          const wifiModel = new PPWifiModel();
          wifiModel.ssid = ssid;
          wifiModel.sign = sign;
          wifiModels.push(wifiModel);

          PPLogger.i(`Parsed WiFi: SSID=${ssid}, sign=${sign}`);
        } catch (e) {
          PPLogger.e(`Error parsing WiFi data: ${e}`);
        }
      }
      PPLogger.d(`PPWifiSyncCmd.processWifiList wifiModels: ${JSON.stringify(wifiModels)}`);
      PPTorreWifiSyncCmd.monitorWiFiListCallBack?.(wifiModels);
    }

  }

  static splitByNullByte(data: Uint8Array): Uint8Array[] {
    const result: Uint8Array[] = [];
    let start = 0;

    while (true) {
      // 从当前位置查找下一个0x00
      const end = data.indexOf(0x00, start);

      if (end === -1) {
        // 没有找到更多分隔符，添加剩余部分
        if (start < data.length) {
          result.push(data.subarray(start));
        }
        break;
      }

      // 截取非空部分（start到end-1）
      if (end > start) {
        result.push(data.subarray(start, end));
      }

      // 跳过0x00本身
      start = end + 1;
    }

    return result;
  }
}
