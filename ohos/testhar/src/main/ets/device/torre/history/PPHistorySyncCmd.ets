import { when } from "@ohos/hypium";
import { PPBleFFF2ErrorCode } from "../../../enums/PPBleFFF2ErrorCode";
import { PPDeviceCalculateType } from "../../../enums/PPDeviceEnums";
import { PPHistoryDataInterface } from "../../../listener/PPHistoryDataInterface";
import { PPLogger } from "../../../log/PPLogger";
import { ByteUtil } from "../../../utils/ByteUtil";
import { DateUtil } from "../../../utils/DateUtil";
import HexUtil from "../../../utils/HexUtil";
import { PPScaleHelper } from "../../../utils/PPScaleHelper";
import { PPBodyBaseModel } from "../../../vo/PPBodyBaseModel";
import { PPDeviceModel } from "../../../vo/PPDeviceModel";
import { PPUserModel } from "../../../vo/PPUserModel";
import { TorreHelper } from "../TorreHelper";

export class PPHistorySyncCmd {
  static bleRequestHistoryStartCallBack?: (error: PPBleFFF2ErrorCode) => void;
  static bleRequestHistorySyncUserResultCallBack?: (error: PPBleFFF2ErrorCode) => void;
  static bleRequestHistoryEndCallBack?: (error: PPBleFFF2ErrorCode) => void;
  //通知外部开始下发用户信息确认成功，开始下发用户信息-根据用户去获取历史数据。
  static historyStartSendUserInfoCallBack?: (error: PPBleFFF2ErrorCode) => void;
  static historySendUserInfoEndCallBack?: (error: PPBleFFF2ErrorCode) => void;
  //所有历史数据发送完成，收到该监听后需要下发给秤收到结束指令。
  static historyDataInterface: PPHistoryDataInterface | null;
  static historyData: Uint8Array = new Uint8Array(0);
  static memberBufferList: Uint8Array[];
  static deviceModel?: PPDeviceModel | null = null;
  static uidHex: Uint8Array | null = null;

  static syncUserHistoryStartCmd(userID: string): Uint8Array {

    PPHistorySyncCmd.uidHex = ByteUtil.autoPadZero(ByteUtil.stringToUint8Array(userID), TorreHelper.userIdMormalLen);

    // 命令头 0xF1
    const commandHeader = new Uint8Array([0x02, 0x03, 0x07]);

    const lenHex = ByteUtil.swapEndian(ByteUtil.numberToUint8Array(PPHistorySyncCmd.uidHex.length, 2));

    // 合并所有字节
    return ByteUtil.concatArrays([commandHeader, lenHex]);
  }

  static syncUserHistoryToUserInfoCmd(mtu: number): Uint8Array[] {

    const uidHex = PPHistorySyncCmd.uidHex;

    if (uidHex && uidHex.length > 0) {
      return ByteUtil.splitByMTUWithLeadingZero(uidHex, mtu)
    }
    return [];
  }

  /**
   * 用户历史数据用户ID数据下发完成[App->设备]
   */
  static syncUserHistoryToUserInfoEndCmd(): Uint8Array {
    PPLogger.d("syncHistory 用户历史数据用户ID数据下发完成");
    return new Uint8Array([0x02, 0x01, 0x08]);
  }

  /**
   * 获取用户历史数据-带用户
   */
  static syncUserHistoryCmd(): Uint8Array {
    PPLogger.d("syncHistory 获取用户历史数据-带用户");
    return new Uint8Array([0x02, 0x01, 0x09]);
  }

  /**
   * 开始真正的获取历史数据-不带用户
   */
  static syncHistoryCmd(): Uint8Array {
    PPLogger.d("syncHistory 开始获取设备历史数据-不带用户");
    return new Uint8Array([0x02, 0x01, 0x03]);
  }

  /**
   * 确认用户历史数据发送结束ACK
   */
  static syncUserHistoryEndCmd(): Uint8Array {
    PPLogger.d("syncHistory 确认用户历史数据发送结束");
    return new Uint8Array([0x02, 0x02, 0x0A, 0x00]);
  }

  static processHistoryData(receiveData: Uint8Array, deviceModel?: PPDeviceModel | null) {
    PPHistorySyncCmd.deviceModel = deviceModel;
    switch (receiveData[2]) {
      case 0x01: //历史数据用户ID下发开始ACK[设备->App][FFF2]
        if (receiveData[3] == 0x00) {
          PPLogger.d("syncHistory 确认同步历史数据成功");
          PPHistorySyncCmd.bleRequestHistoryStartCallBack?.(PPBleFFF2ErrorCode.Ok);
        } else {
          PPLogger.d("syncHistory 确认同步历史数据失败");
          PPHistorySyncCmd.bleRequestHistoryStartCallBack?.(PPBleFFF2ErrorCode.Unknown);
        }
        break;

      case 0x02: //历史数据用户信息发送完成
        if (receiveData[3] == 0x00) {
          PPLogger.d("syncHistory 历史数据用户信息确认发送成功");
          PPHistorySyncCmd.bleRequestHistorySyncUserResultCallBack?.(PPBleFFF2ErrorCode.Ok);
        } else {
          PPLogger.d("syncHistory 历史数据用户信息确认发送失败");
          PPHistorySyncCmd.bleRequestHistorySyncUserResultCallBack?.(PPBleFFF2ErrorCode.Unknown);
        }
        break;

      case 0x04: //设备历史数据发送结束[设备->App][FFF2]
        PPLogger.d("syncHistory 设备历史数据发送结束");
        PPHistorySyncCmd.onReceiveHistory04()
        break;

      case 0x06: //设备历史数据发送结束[设备->App][FFF2]
        PPHistorySyncCmd.onAllHistorySync();
        if (receiveData[3] == 0x00) {
          PPLogger.d("syncAllHistory 当前用户历史数据发送完成");
        } else {
          PPLogger.d("syncAllHistory 所有历史数据发送完成");
          PPHistorySyncCmd.memberBufferList = [];
          //回调外部历史数据结束
          PPHistorySyncCmd.historyDataInterface?.monitorHistoryEnd?.();
        }

        break;

      case 0x07: //获取用户历史数据下发开始ACK
        PPHistorySyncCmd.historyData = new Uint8Array(0);
        if (receiveData[3] == 0x00) { //接收完成
          PPLogger.d("syncHistoryStartSendUserInfo 获取用户历史数据下发开始ACK");
          PPHistorySyncCmd.historyStartSendUserInfoCallBack?.(PPBleFFF2ErrorCode.Ok);
        } else { //接收失败
          PPLogger.e("syncHistoryStartSendUserInfo 获取用户历史数据下发开始ACK Fail");
          PPHistorySyncCmd.historyStartSendUserInfoCallBack?.(PPBleFFF2ErrorCode.Unknown);
          PPHistorySyncCmd.historyDataInterface?.monitorHistoryFail?.();
        }
        break;
      case 0x08: //用户历史数据用户ID数据下发完成ACK
        if (receiveData[3] == 0x00) { //接收完成
          PPLogger.d("syncUserHistory 用户历史数据用户ID数据下发 接收完成");
          PPHistorySyncCmd.historySendUserInfoEndCallBack?.(PPBleFFF2ErrorCode.Ok);
        } else if (receiveData[3] == 0x01) { //接收失败
          PPLogger.e("syncUserHistory 用户历史数据用户ID数据下发 接收失败");
          PPHistorySyncCmd.historySendUserInfoEndCallBack?.(PPBleFFF2ErrorCode.Unknown);
          PPHistorySyncCmd.historyDataInterface?.monitorHistoryFail?.();
        } else if (receiveData[3] == 0x02) { //用户未找到
          PPLogger.e("syncUserHistory 用户历史数据用户ID数据下发 用户未找到");
          PPHistorySyncCmd.historySendUserInfoEndCallBack?.(PPBleFFF2ErrorCode.Unknown);
          PPHistorySyncCmd.historyDataInterface?.monitorHistoryFail?.();
        }
        break;
      case 0x0A: //用户历史数据发送结束[设备->App]
        const historyReceiveDataResult = receiveData[3];
        if (PPHistorySyncCmd.historyData && PPHistorySyncCmd.historyData.length > 0) {
          PPHistorySyncCmd.memberBufferList.push(PPHistorySyncCmd.historyData)
          PPHistorySyncCmd.historyData = new Uint8Array(0);
        }
        if (historyReceiveDataResult == 0x00) {
          PPLogger.d("syncUserHistory 当前用户历史数据发送完成");
        } else {
          PPLogger.d("syncUserHistory 历史数据全部接收完成");
          if (PPHistorySyncCmd.memberBufferList && PPHistorySyncCmd.memberBufferList.length > 0) {

            //处理历史数据
            if (deviceModel && deviceModel.deviceCalculateType === PPDeviceCalculateType.PPDeviceCalculateTypeDirect) {
              //直流算法的秤
              PPHistorySyncCmd.memberBufferList?.forEach((item) => {
                PPHistorySyncCmd.onUserHistorySyncTypeDirect(item)
              })
            } else {
              PPHistorySyncCmd.memberBufferList?.forEach((item) => {
                PPHistorySyncCmd.onUserHistorySync(item)
              })
            }
          } else {
            PPLogger.d("syncUserHistory 当前历史数据为空");
          }
          //回调外部历史数据结束
          PPHistorySyncCmd.historyDataInterface?.monitorHistoryEnd?.();
          PPHistorySyncCmd.bleRequestHistoryEndCallBack?.(PPBleFFF2ErrorCode.Ok);
          PPHistorySyncCmd.memberBufferList = [];
        }
        break;
    }
  }

  static onUserHistorySync(historyData: Uint8Array) {

    if (historyData && historyData.length > 0) {
      PPLogger.d("syncHistory item historyData = " + HexUtil.formatHexString(historyData));
      const memberIdLen = TorreHelper.userIdMormalLen;
      const historyAllLen = historyData.length - memberIdLen;
      const memberIdHex = historyData.subarray(0, memberIdLen);
      const memberId = ByteUtil.bufferToAscii(memberIdHex);
      PPLogger.d("syncHistory item memberId = " + memberId);
      let historyItemLen = 48;
      if (PPScaleHelper.isSupportFootLen(PPHistorySyncCmd.deviceModel?.deviceFuncType)) {
        historyItemLen = 50;
      } else {
        historyItemLen = 48;
      }
      const arrLen = historyAllLen / historyItemLen;

      if (arrLen > 0) {
        for (let i = 0; i < arrLen; i++) {
          const itemHex = historyData.subarray(memberIdLen + i * historyItemLen, memberIdLen + (i + 1) * historyItemLen)
          PPHistorySyncCmd.historyItem(memberId, itemHex)
        }
      }
    }

  }


  static onAllHistorySync() {

    const historyData = PPHistorySyncCmd.historyData;

    const memberIdLen = TorreHelper.memberIdMormalLen;
    const historyAllLen = historyData.length - memberIdLen;
    const historyItemLen = 12;

    const arrLen = historyAllLen / historyItemLen

    const memberIdHex = historyData.subarray(0, memberIdLen);
    const memberId = ByteUtil.bufferToAscii(memberIdHex);
    PPLogger.d("syncHistory item memberId = " + memberId);

    if (arrLen > 0) {
      for (let i = 0; i < arrLen; i++) {
        const itemHex = historyData.subarray(memberIdLen + i * historyItemLen, memberIdLen + (i + 1) * historyItemLen)
        PPHistorySyncCmd.historyItem(memberId, itemHex)
      }
    }
    PPHistorySyncCmd.bleRequestHistoryEndCallBack?.(PPBleFFF2ErrorCode.Ok);

  }

  static onUserHistorySyncTypeDirect(historyData: Uint8Array) {

    const memberIdLen = TorreHelper.userIdMormalLen;

    const historyAllLen = historyData.length - memberIdLen;

    const memberIdHex = historyData.subarray(0, memberIdLen);

    const memberId = ByteUtil.bufferToAscii(memberIdHex);

    PPLogger.d("syncHistory item memberId = " + memberId);

    const historyItemLen = 16;

    const arrLen = historyAllLen / historyItemLen;

    if (arrLen > 0) {
      for (let i = 0; i < arrLen; i++) {
        const itemHex = historyData.subarray(memberIdLen + i * historyItemLen, memberIdLen + (i + 1) * historyItemLen)
        PPHistorySyncCmd.historyItem(memberId, itemHex)
      }
    }

  }


  static onReceiveHistory04() {
    const historyData = PPHistorySyncCmd.historyData;

    const arrLen = historyData.length / TorreHelper.memberIdMormalLen
    if (arrLen > 0) {

      for (let i = 0; i < arrLen; i++) {
        const itemHex = historyData.subarray(i * TorreHelper.memberIdMormalLen, (i + 1) * TorreHelper.memberIdMormalLen);
        PPHistorySyncCmd.historyItem("", itemHex)
      }
    }
    PPHistorySyncCmd.bleRequestHistoryEndCallBack?.(PPBleFFF2ErrorCode.Ok);
  }

  static historyItem(memberId: string, itemData: Uint8Array) {

    const timeHex = itemData.subarray(0, 4);
    const time = ByteUtil.bytesToLong(timeHex, true)

    if (time < TorreHelper.ABNORMAL_HISTORY_INTERVAL_TIME_TORRE) {
      return;
    }

    const weightInt = TorreHelper.getWeightG(itemData.subarray(4, 6))

    let heartRateHex = itemData[6]
    if (heartRateHex !== 0x00 && heartRateHex !== 0xFF) {
      heartRateHex = 0;
    }

    const bodyBaseModel = new PPBodyBaseModel();
    const userModel = new PPUserModel();
    userModel.memberID = memberId;
    bodyBaseModel.weight = weightInt;
    bodyBaseModel.heartRate = heartRateHex;
    bodyBaseModel.measureTime = time * 1000;
    bodyBaseModel.userModel = userModel;
    bodyBaseModel.isHeartRating = false;

    //解析阻抗
    const imType = itemData[7];
    //阻抗测量频率 0x00：20KHz&100KHz  0x01：50KHz
    if (imType === 0x01) {
      //20KHz&100KHz
      let impedance = TorreHelper.getImpedance(itemData.subarray(8, 12));
      if (PPHistorySyncCmd.deviceModel?.deviceCalculateType === PPDeviceCalculateType.PPDeviceCalculateTypeDirect) {
        impedance = impedance / 10;
      }
      bodyBaseModel.impedance = impedance;
    } else if (imType === 0x00) {
      //八电极设备 20kHz密文阻抗[4byte]  100kHz密文阻抗[4byte]
      //指定部位阻抗值 数据起始为最低位到高位：
      //如：0x03 (bit1 | bit0) ， 数据组成为：右手20KHz密文阻抗 + 右手100KHz密文阻抗 + 左手20KHz密文阻抗 + 左手100KHz密文阻抗

      const impedanceData = itemData.subarray(8);

      PPLogger.d("syncHistory item 8电极 impedanceData : " + HexUtil.formatHexString(impedanceData));

      const len = 4;

      let offset = 0;

      // 右手 (20KHz和100KHz)
      bodyBaseModel.z20KhzRightArmEnCode = TorreHelper.getImpedance(impedanceData.subarray(offset, offset + len));
      offset += len;
      bodyBaseModel.z100KhzRightArmEnCode = TorreHelper.getImpedance(impedanceData.subarray(offset, offset + len));
      offset += len;

      // 左手
      bodyBaseModel.z20KhzLeftArmEnCode = TorreHelper.getImpedance(impedanceData.subarray(offset, offset + len));
      offset += len;
      bodyBaseModel.z100KhzLeftArmEnCode = TorreHelper.getImpedance(impedanceData.subarray(offset, offset + len));
      offset += len;

      // 躯干
      bodyBaseModel.z20KhzTrunkEnCode = TorreHelper.getImpedance(impedanceData.subarray(offset, offset + len));
      offset += len;
      bodyBaseModel.z100KhzTrunkEnCode = TorreHelper.getImpedance(impedanceData.subarray(offset, offset + len));
      offset += len;

      // 右脚
      bodyBaseModel.z20KhzRightLegEnCode = TorreHelper.getImpedance(impedanceData.subarray(offset, offset + len));
      offset += len;
      bodyBaseModel.z100KhzRightLegEnCode = TorreHelper.getImpedance(impedanceData.subarray(offset, offset + len));
      offset += len;

      // 左脚
      bodyBaseModel.z20KhzLeftLegEnCode = TorreHelper.getImpedance(impedanceData.subarray(offset, offset + len));
      offset += len;
      bodyBaseModel.z100KhzLeftLegEnCode = TorreHelper.getImpedance(impedanceData.subarray(offset, offset + len));

    } else if (imType === 0x02) {
      const impedance = TorreHelper.getImpedance(itemData.subarray(8, 12));
      const impedance100EnCode = TorreHelper.getImpedance(itemData.subarray(14, 18));
      bodyBaseModel.impedance = impedance;
      bodyBaseModel.ppImpedance100EnCode = impedance100EnCode;
    }

    PPHistorySyncCmd.historyDataInterface?.monitorHistoryData?.(bodyBaseModel);

  }


  static pushReceiveData(newData: Uint8Array) {
    let accumulatedData = PPHistorySyncCmd.historyData;
    // 创建新数组并拷贝旧数据 + 新数据
    const mergedData = new Uint8Array(accumulatedData.length + newData.length);
    mergedData.set(accumulatedData, 0);
    mergedData.set(newData, accumulatedData.length);
    // 更新累积数据
    PPHistorySyncCmd.historyData = mergedData;
  }
}